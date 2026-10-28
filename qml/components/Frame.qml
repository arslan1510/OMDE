import QtQuick
import Quickshell
import qs

Item {
    id: root

    property color borderColor: Theme.accent
    default property alias content: body.data

    readonly property real dpr: QsWindow.window?.devicePixelRatio ?? 1
    readonly property real line: Theme.line(dpr)
    readonly property point origin: Theme.windowPosition(root)
    readonly property real boxLeft: Theme.snap(origin.x, dpr) - origin.x
    readonly property real boxTop: Theme.snap(origin.y, dpr) - origin.y
    readonly property real boxRight: Theme.snap(origin.x + width, dpr) - origin.x
    readonly property real boxBottom: Theme.snap(origin.y + height, dpr) - origin.y

    component Edge: Rectangle {
        color: root.borderColor
    }

    Rectangle {
        x: root.boxLeft
        y: root.boxTop
        width: root.boxRight - root.boxLeft
        height: root.boxBottom - root.boxTop
        color: Theme.background
    }

    Item {
        id: body
        anchors.fill: parent
    }

    Edge {
        x: root.boxLeft
        y: root.boxTop
        width: root.boxRight - root.boxLeft
        height: root.line
    }

    Edge {
        x: root.boxLeft
        y: root.boxBottom - root.line
        width: root.boxRight - root.boxLeft
        height: root.line
    }

    Edge {
        x: root.boxLeft
        y: root.boxTop
        width: root.line
        height: root.boxBottom - root.boxTop
    }

    Edge {
        x: root.boxRight - root.line
        y: root.boxTop
        width: root.line
        height: root.boxBottom - root.boxTop
    }
}
