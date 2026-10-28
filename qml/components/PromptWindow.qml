import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    property bool shown: false
    property bool belowBar: false
    required property string namespace
    default property alias content: card.content

    signal dismissed()

    visible: card.present
    mask: Region {
        item: root.shown ? backdrop : null
    }
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: -1
    color: "transparent"
    focusable: true
    WlrLayershell.namespace: namespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        id: backdrop
        anchors.fill: parent
        enabled: root.shown
        onClicked: root.dismissed()
    }

    Card {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.belowBar
            ? Theme.gutter * 2 + Theme.barHeight
            : Math.min(Math.round(parent.height * 0.22), parent.height - height - Theme.gutter)
        width: Math.min(Theme.barMaxWidth, parent.width - Theme.gutter * 2)
        shown: root.shown
        dy: root.belowBar ? -Theme.gutter : Theme.travel
    }
}
