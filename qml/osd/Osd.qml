import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.services

PanelWindow {
    id: root

    property var source: Audio
    property bool shown: false

    function show(target: var): void {
        source = target;
        shown = true;
        hideDelay.restart();
    }

    function setFrom(x: real): void {
        source.setPercent(x / track.width * 100);
    }

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Theme.gutter
        left: Theme.barSideMargin(screen)
        right: Theme.barSideMargin(screen)
    }
    implicitHeight: box.implicitHeight
    exclusiveZone: 0
    focusable: false
    color: "transparent"
    visible: box.present
    WlrLayershell.namespace: "omde-osd"
    WlrLayershell.layer: WlrLayer.Overlay

    Timer {
        id: hideDelay
        interval: Config.osdTimeout
        onTriggered: {
            if (pointer.containsMouse || pointer.pressed)
                restart();
            else
                root.shown = false;
        }
    }

    Connections {
        target: Audio
        function onLevelChanged() { root.show(Audio); }
    }

    Connections {
        target: Brightness
        function onLevelChanged() { root.show(Brightness); }
    }

    Card {
        id: box
        width: parent.width
        shown: root.shown
        dy: -4
        padding: 0

        Item {
            id: track
            x: Theme.inset - Theme.borderWidth
            width: parent.width - x * 2
            height: Theme.inset * 2 + Theme.sliderThickness - Theme.borderWidth * 2

            property color fill: root.source.muted ? Theme.muted : Theme.accent
            Behavior on fill { Motion {} }

            Glide {
                id: level
                to: track.width * root.source.percent / 100
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: track.width
                height: Theme.sliderThickness
                color: Theme.border
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: level.start
                height: Theme.sliderThickness
                color: track.fill
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: level.start
                width: level.end - level.start
                height: Theme.sliderThickness
                color: track.fill
                opacity: 0.5
            }

            MouseArea {
                id: pointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => root.setFrom(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        root.setFrom(mouse.x);
                }
            }
        }
    }
}
