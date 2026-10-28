import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

PanelWindow {
    id: root

    readonly property string monitorName: screen.name
    readonly property var monitor: Mango.monitorFor(monitorName)
    readonly property real barWidth: Math.min(Theme.barMaxWidth, width)
    readonly property real sidesWidth: row.width
        - (clock.visible ? clock.implicitWidth + row.spacing * 2 : row.spacing)
    readonly property real leftWidth: {
        const half = Math.round(sidesWidth / 2);
        const left = leftGroup.implicitWidth;
        const right = statusRow.implicitWidth;
        return left > half ? Math.min(left, sidesWidth - Math.min(right, half))
            : Math.max(left, Math.min(half, sidesWidth - right));
    }

    function status(): var {
        return {
            screen: monitorName,
            width: width,
            height: height,
            devicePixelRatio: devicePixelRatio,
            contentFits: leftGroup.implicitWidth <= leftSlot.width
                && statusRow.implicitWidth <= rightSlot.width,
            sections: {
                left: [leftSlot.x, leftGroup.implicitWidth],
                clock: [clock.x, clock.width],
                right: [rightSlot.x + rightSlot.width - statusRow.implicitWidth, statusRow.implicitWidth]
            },
            popout: popout.status()
        };
    }

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Theme.gutter
        left: Theme.barSideMargin(screen)
        right: Theme.gutter
    }
    // Keep the surface size fixed; resizing stutters and leaves stale frames.
    implicitHeight: Math.min(Theme.barHeight + Theme.popoutMaxHeight, screen.height - Theme.gutter * 2)
    exclusiveZone: Theme.barHeight
    focusable: false
    color: "transparent"
    WlrLayershell.namespace: "omde"

    mask: Region {
        Region {
            width: Math.ceil(outline.barRight)
            height: Math.ceil(outline.barBottom)
        }

        Region {
            item: popout.area
        }
    }

    Rectangle {
        width: outline.barRight
        height: outline.barBottom
        color: Theme.background
    }

    RowLayout {
        id: row
        x: Theme.inset
        y: outline.line
        width: root.barWidth - Theme.inset * 2
        height: outline.barBottom - outline.line * 2
        spacing: Theme.gutter

        Item {
            id: leftSlot
            Layout.preferredWidth: root.leftWidth
            Layout.fillHeight: true
            clip: true

            RowLayout {
                id: leftGroup
                height: parent.height
                spacing: Theme.gutter

                LayoutPicker {
                    visible: Config.showLayout
                    monitor: root.monitor
                }

                Tags {
                    Layout.fillHeight: true
                    monitorName: root.monitorName
                    monitor: root.monitor
                }

                FocusedWindow {
                    visible: Config.showTitle
                }
            }
        }

        Clock {
            id: clock
            visible: Config.showClock
        }

        Item {
            id: rightSlot
            Layout.preferredWidth: root.sidesWidth - root.leftWidth
            Layout.fillHeight: true
            clip: true

            StatusLine {
                id: statusRow
                anchors.right: parent.right
                height: parent.height
            }
        }
    }

    Extension {
        id: extension
        x: Theme.snap(root.barWidth, root.devicePixelRatio)
        y: outline.line
        height: outline.barBottom - outline.line * 2
        dpr: root.devicePixelRatio
        room: root.width - x - outline.line
    }

    Binding {
        target: Popouts
        property: "extensionRoom"
        value: extension.room
    }

    IdleInhibitor {
        window: root
        enabled: Session.keepAwake
    }

    Popout {
        id: popout
        anchors.fill: parent
        window: root
        dpr: root.devicePixelRatio
        barWidth: outline.barRight
        edgeTop: outline.barBottom
    }

    BarOutline {
        id: outline
        anchors.fill: parent
        dpr: root.devicePixelRatio
        barWidth: root.barWidth + extension.extent
        popout: popout
    }
}
