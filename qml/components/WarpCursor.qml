import QtQuick
import qs

Item {
    id: root

    required property TextInput input

    readonly property int duration: 200
    readonly property real trailSize: 0.8
    readonly property real minDistance: 1.5
    readonly property real thicknessX: 0.9

    readonly property rect cell: input.cursorRectangle
    readonly property string under: input.displayText.charAt(input.cursorPosition)
    readonly property real cellWidth: Math.ceil(metrics.advanceWidth)
    readonly property real inset: (1 - thicknessX) / 2

    property real lastX: 0
    property bool blinkOn: true

    anchors.fill: parent
    visible: input.activeFocus

    onCellChanged: {
        blinkOn = true;
        blink.restart();
        const far = Math.abs(cell.x - lastX) > cell.height * minDistance;
        lastX = cell.x;
        trail.to = cell.x + cellWidth * inset;
        trail.size = cellWidth * thicknessX;
        if (!far)
            trail.snap();
    }
    onCellWidthChanged: {
        trail.size = cellWidth * thicknessX;
        if (!trail.moving)
            trail.snap();
    }

    TextMetrics {
        id: metrics
        font: root.input.font
        text: root.under || "0"
    }

    Glide {
        id: trail
        duration: root.duration * Theme.motionScale
        easing: ({ type: Easing.OutCirc })
        trail: root.trailSize
    }

    Timer {
        id: blink
        interval: 600
        repeat: true
        running: root.visible
        onTriggered: root.blinkOn = !root.blinkOn
    }

    Rectangle {
        visible: trail.moving
        x: trail.start
        y: root.cell.y
        width: Math.max(0, trail.end - trail.start)
        height: root.cell.height
        color: Theme.accent
    }

    Rectangle {
        visible: root.blinkOn || trail.moving
        x: root.cell.x
        y: root.cell.y
        width: root.cellWidth
        height: root.cell.height
        color: Theme.accent

        Text {
            text: root.under
            color: Theme.background
            font: root.input.font
            renderType: root.input.renderType
        }
    }
}
