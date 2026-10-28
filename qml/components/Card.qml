import QtQuick
import qs

Item {
    id: root

    property bool shown: false
    property real dx: 0
    property real dy: 0
    property int padding: Theme.inset - Theme.borderWidth
    property color borderColor: Theme.accent
    readonly property bool present: shown || progress > 0
    default property alias content: inner.data

    signal exited()

    property real progress: 0
    readonly property int inset: padding + Theme.borderWidth
    readonly property bool settled: shown && !fade.running

    function animate(): void {
        fade.go(shown ? 1 : 0, shown ? Motion.Enter : Motion.Exit);
    }

    onShownChanged: animate()
    Component.onCompleted: if (shown) animate()

    implicitWidth: inner.childrenRect.width + inset * 2
    implicitHeight: inner.childrenRect.height + inset * 2
    Behavior on implicitWidth {
        enabled: root.settled
        Motion { role: Motion.Move }
    }
    Behavior on implicitHeight {
        enabled: root.settled
        Motion { role: Motion.Move }
    }

    Motion {
        id: fade
        target: root
        property: "progress"
        onFinished: if (!root.shown) root.exited()
    }

    Frame {
        width: root.width
        height: root.height
        opacity: root.progress
        transform: Translate {
            x: root.dx * (1 - root.progress)
            y: root.dy * (1 - root.progress)
        }
        borderColor: root.borderColor

        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: inner
            x: root.inset
            y: root.inset
            width: root.width - root.inset * 2
            height: root.height - root.inset * 2
            clip: true
            enabled: root.shown
        }
    }
}
