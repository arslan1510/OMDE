import QtQuick
import qs

// Moves the span from `to` to `to + size`; the edge facing the move leads.
Item {
    id: root

    property real to: 0
    property real size: 0
    property real trail: 0.8
    property real duration: Theme.motion("move").duration
    property easingCurve easing: Theme.motion("move").easing

    readonly property real start: edges.start
    readonly property real end: edges.end
    readonly property bool moving: leading.running || trailing.running

    function snap(): void {
        leading.stop();
        trailing.stop();
        edges.start = to;
        edges.end = to + size;
    }

    function glide(): void {
        if (size > 0 && edges.end <= edges.start) {
            snap();
            return;
        }
        const forward = to > edges.start;
        leading.stop();
        trailing.stop();
        leading.target = edges;
        leading.property = forward ? "end" : "start";
        leading.to = forward ? to + size : to;
        trailing.target = edges;
        trailing.property = forward ? "start" : "end";
        trailing.to = forward ? to : to + size;
        leading.start();
        trailing.start();
    }

    onToChanged: glide()
    onSizeChanged: glide()

    QtObject {
        id: edges
        property real start: 0
        property real end: 0
    }

    NumberAnimation {
        id: leading
        duration: root.duration * (1 - root.trail)
        easing: root.easing
    }

    NumberAnimation {
        id: trailing
        duration: root.duration
        easing: root.easing
    }
}
