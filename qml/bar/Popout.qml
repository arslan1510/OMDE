pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

Item {
    id: root

    required property PanelWindow window
    required property real dpr
    required property real barWidth
    required property real edgeTop
    readonly property real line: Theme.line(dpr)
    readonly property Item area: area

    property Slot shownSlot: slotA
    readonly property Item content: shownSlot.item
    readonly property real targetWidth: content ? content.width + line * 2 : 0
    readonly property real targetHeight: content ? shownSlot.height + line * 2 : 0
    readonly property real maxContentHeight: height - edgeTop - line * 2

    readonly property Item owner: Popouts.owner
    readonly property real ownerLeft: owner ? Theme.windowPosition(owner).x : 0
    readonly property real ownerWidth: owner?.width ?? 0
    readonly property real targetX: {
        const center = ownerLeft + ownerWidth / 2;
        const x = center < barWidth / 3 ? ownerLeft
            : center > barWidth * 2 / 3 ? ownerLeft + ownerWidth - targetWidth
            : center - targetWidth / 2;
        return Math.max(0, Math.min(barWidth - targetWidth, x));
    }

    property real popX: targetX
    property real popWidth: targetWidth
    property real popHeight: 0
    Behavior on popX {
        enabled: root.popHeight > 0
        Motion { role: Motion.Move }
    }
    Behavior on popWidth {
        enabled: root.popHeight > 0
        Motion { role: Motion.Move }
    }

    readonly property real edgeLeft: Theme.snap(popX, dpr)
    readonly property real edgeRight: Theme.snap(popX + popWidth, dpr)
    readonly property real edgeBottom: edgeTop + Theme.snap(popHeight, dpr)
    readonly property bool open: edgeBottom - edgeTop >= line && edgeRight - edgeLeft >= line * 2

    function status(): var {
        return {
            shown: Popouts.shown,
            pinned: Popouts.pinned,
            owner: owner ? String(owner) : null,
            open: open,
            edges: [edgeLeft, edgeRight, edgeBottom],
            target: [targetX, targetWidth, targetHeight]
        };
    }

    function animateHeight(): void {
        heightAnimation.go(Popouts.shown ? targetHeight : 0, !Popouts.shown ? Motion.Exit
            : popHeight < line ? Motion.Enter : Motion.Move);
    }

    function swap(fresh: bool): void {
        if (!fresh && shownSlot.item && shownSlot.component === Popouts.content)
            return;
        const next = shownSlot === slotA ? slotB : slotA;
        next.load(Popouts.content);
        shownSlot.current = false;
        next.current = true;
        shownSlot = next;
    }

    onTargetHeightChanged: if (Popouts.shown) animateHeight()

    Connections {
        target: Popouts
        function onContentChanged() {
            if (Popouts.shown)
                root.swap(false);
            root.animateHeight();
        }
        function onShownChanged() {
            if (Popouts.shown)
                root.swap(true);
            root.animateHeight();
        }
    }

    Motion {
        id: heightAnimation
        target: root
        property: "popHeight"
        onFinished: {
            if (!Popouts.shown) {
                slotA.unload();
                slotB.unload();
            }
        }
    }

    Binding {
        target: Popouts
        property: "hovered"
        value: hover.hovered && root.open
    }

    component Slot: Flickable {
        property bool current: false
        readonly property Component component: loader.sourceComponent
        readonly property Item item: loader.item

        function load(content: Component): void {
            loader.sourceComponent = content;
        }

        function unload(): void {
            current = false;
            loader.sourceComponent = null;
        }

        x: root.line
        y: root.line
        width: loader.width
        height: Math.min(loader.height, root.maxContentHeight)
        contentWidth: width
        contentHeight: loader.height
        interactive: contentHeight > height
        clip: interactive
        boundsBehavior: Flickable.StopAtBounds
        opacity: current ? 1 : 0
        enabled: current
        Behavior on opacity { Motion {} }
        onOpacityChanged: if (opacity === 0 && !current) loader.sourceComponent = null

        Loader {
            id: loader
        }
    }

    Rectangle {
        id: area
        x: root.edgeLeft
        y: root.edgeTop
        width: root.open ? root.edgeRight - root.edgeLeft : 0
        height: root.open ? root.edgeBottom - root.edgeTop : 0
        color: Theme.background
        clip: true

        HoverHandler {
            id: hover
        }

        Slot {
            id: slotA
        }

        Slot {
            id: slotB
        }
    }

    PanelWindow {
        id: shield

        readonly property PanelWindow bar: root.window

        screen: bar.screen
        visible: Popouts.grabbing
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        exclusiveZone: -1
        color: "transparent"
        focusable: true
        WlrLayershell.namespace: "omde-shield"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        mask: Region {
            width: shield.width
            height: shield.height

            Region {
                intersection: Intersection.Subtract
                x: shield.bar.margins.left
                y: shield.bar.margins.top
                width: Math.ceil(root.barWidth)
                height: Math.ceil(root.edgeTop)
            }

            Region {
                intersection: Intersection.Subtract
                x: shield.bar.margins.left + area.x
                y: shield.bar.margins.top + area.y
                width: area.width
                height: area.height
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: Popouts.dismiss()
        }

        Item {
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape)
                    Popouts.dismiss();
                event.accepted = event.key === Qt.Key_Escape || (root.content?.key?.(event) ?? false);
            }
        }
    }
}
