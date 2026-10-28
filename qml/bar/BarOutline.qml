import QtQuick
import qs

Item {
    id: root

    required property real dpr
    required property real barWidth
    required property Popout popout

    readonly property real line: Theme.line(dpr)
    readonly property real barRight: Theme.snap(barWidth, dpr)
    readonly property real barBottom: Theme.snap(Theme.barHeight, dpr)

    component Edge: Rectangle {
        color: Theme.accent
    }

    Edge {
        width: root.barRight
        height: root.line
    }

    Edge {
        width: root.line
        height: root.barBottom
    }

    Edge {
        x: root.barRight - root.line
        width: root.line
        height: root.barBottom
    }

    Edge {
        y: root.barBottom - root.line
        width: root.popout.open ? root.popout.edgeLeft + root.line : root.barRight
        height: root.line
    }

    Edge {
        visible: root.popout.open
        x: root.popout.edgeRight - root.line
        y: root.barBottom - root.line
        width: root.barRight - x
        height: root.line
    }

    Edge {
        visible: root.popout.open
        x: root.popout.edgeLeft
        y: root.barBottom - root.line
        width: root.line
        height: root.popout.edgeBottom - y
    }

    Edge {
        visible: root.popout.open
        x: root.popout.edgeRight - root.line
        y: root.barBottom - root.line
        width: root.line
        height: root.popout.edgeBottom - y
    }

    Edge {
        visible: root.popout.open
        x: root.popout.edgeLeft
        y: root.popout.edgeBottom - root.line
        width: root.popout.edgeRight - root.popout.edgeLeft
        height: root.line
    }
}
