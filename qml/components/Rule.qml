import QtQuick
import qs

Item {
    implicitHeight: Math.round(Theme.fontSize / 2)

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Theme.borderWidth
        color: Theme.border
    }
}
