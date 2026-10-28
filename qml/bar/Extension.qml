import QtQuick
import qs
import qs.components

Item {
    id: root

    required property real dpr
    required property real room

    readonly property Item content: loader.item
    readonly property real contentWidth: content ? Math.min(content.implicitWidth, room) : 0
    readonly property real targetWidth: Popouts.extended ? contentWidth : 0
    property real growth: 0
    readonly property real extent: Theme.snap(growth, dpr)

    onTargetWidthChanged: animation.go(targetWidth, !Popouts.extended ? Motion.Exit
        : growth < 1 ? Motion.Enter : Motion.Move)

    width: extent
    clip: true

    Connections {
        target: Popouts
        function onExtensionChanged() {
            if (Popouts.extension)
                loader.sourceComponent = Popouts.extension;
        }
    }

    Motion {
        id: animation
        target: root
        property: "growth"
        onFinished: if (!Popouts.extended) loader.sourceComponent = null
    }

    Loader {
        id: loader
        width: root.contentWidth
        height: root.height
    }
}
