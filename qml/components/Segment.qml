import QtQuick
import QtQuick.Layouts
import qs

Item {
    id: root

    property string text: ""
    property string iconSource: ""
    property var tooltip: []
    readonly property bool hasTooltip: tooltip.length > 0
    property color textColor: Theme.foreground
    property bool interactive: false
    property bool rightClickable: false
    property bool scrollable: false
    readonly property bool hovered: pointer.containsMouse

    signal clicked()
    signal rightClicked()
    signal scrolled(int steps)

    function updateTooltip(): void {
        if (hovered && hasTooltip)
            Popouts.hoverEntered(root, tooltipContent);
        else
            Popouts.hoverExited(root);
    }

    onHoveredChanged: updateTooltip()
    onHasTooltipChanged: {
        updateTooltip();
        if (!hasTooltip)
            Popouts.release(root);
    }
    onVisibleChanged: if (!visible) Popouts.release(root)

    implicitWidth: Math.max(iconSource.length > 0 ? Theme.iconSize : Math.ceil(label.implicitWidth),
        Theme.columns(2)) + Theme.cellPadding * 2
    implicitHeight: Theme.cellHeight
    Layout.fillHeight: true

    HoverFill {
        active: root.hovered
        pressed: pointer.pressed
    }

    Label {
        id: label
        anchors.centerIn: parent
        visible: root.iconSource.length === 0
        text: root.text
        color: root.textColor
    }

    Icon {
        anchors.centerIn: parent
        visible: root.iconSource.length > 0
        source: root.iconSource
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: !root.interactive ? Qt.NoButton
            : root.rightClickable ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        onWheel: wheel => {
            wheel.accepted = root.scrollable;
            const steps = wheel.accepted ? notches.take(wheel.angleDelta.y) : 0;
            if (steps !== 0)
                root.scrolled(steps);
        }
        onExited: notches.remainder = 0
    }

    WheelSteps {
        id: notches
    }

    Component {
        id: tooltipContent

        TooltipBody {
            lines: root.tooltip
        }
    }
}
