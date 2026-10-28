import QtQuick
import qs

Column {
    id: root

    property alias header: heading.text
    property alias glyph: input.glyph
    property alias placeholder: input.placeholder
    property alias echoMode: input.echoMode
    property string status: ""
    property bool error: false
    property bool holdFocus: false
    readonly property alias input: input

    signal submitted(string password)
    signal cancelled()

    spacing: Theme.gap

    Label {
        id: heading
        width: parent.width
        topPadding: Theme.gap
        bottomPadding: Theme.gap
        wrapMode: Text.Wrap
    }

    Rule {
        width: parent.width
    }

    PromptInput {
        id: input
        width: parent.width
        height: Theme.cellHeight
        echoMode: TextInput.Password
        focus: true
        onAccepted: {
            if (text.length === 0)
                return;
            root.submitted(text);
            text = "";
        }
        Keys.onEscapePressed: root.cancelled()
        onActiveFocusChanged: if (!activeFocus && root.holdFocus) forceActiveFocus()
    }

    Label {
        height: Theme.cellHeight
        verticalAlignment: Text.AlignVCenter
        visible: text.length > 0
        text: root.status
        color: root.error ? Theme.critical : Theme.muted
    }
}
