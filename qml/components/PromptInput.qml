import QtQuick
import qs

TextInput {
    id: root

    property string glyph: ""
    property string placeholder: ""

    leftPadding: glyphLabel.width + Theme.inset
    color: Theme.foreground
    selectionColor: Theme.accent
    selectedTextColor: Theme.background
    passwordCharacter: "•"
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    renderType: Text.CurveRendering
    verticalAlignment: TextInput.AlignVCenter
    clip: true
    cursorDelegate: Item {}

    Label {
        id: glyphLabel
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        color: Theme.accent
    }

    Label {
        x: root.leftPadding + Theme.columns(1)
        anchors.verticalCenter: parent.verticalCenter
        visible: root.text.length === 0
        text: root.placeholder
        color: Theme.muted
    }

    WarpCursor {
        input: root
    }
}
