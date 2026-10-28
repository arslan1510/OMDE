import QtQuick
import qs

Image {
    anchors.fill: parent
    source: Config.wallpaper
    sourceSize: Qt.size(width, height)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    smooth: true
}
