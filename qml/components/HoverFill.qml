import QtQuick
import qs

Rectangle {
    property bool active: false
    property bool pressed: false

    anchors.fill: parent
    color: pressed ? Theme.pressed : Theme.hover
    opacity: active || pressed ? 1 : 0
    Behavior on color { Motion {} }
    Behavior on opacity { Motion {} }
}
