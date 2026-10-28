import QtQuick
import QtQuick.Layouts
import qs

MouseArea {
    id: root

    signal triggered(bool secondary)

    readonly property Item menu: {
        for (let item = parent; item; item = item.parent)
            if (item instanceof Menu)
                return item;
        return null;
    }

    enum Mark { None, Check, Radio }
    property int mark: MenuRow.None
    property bool checked: false

    property string glyph: mark === MenuRow.Check ? (checked ? Icons.checked : Icons.unchecked)
        : mark === MenuRow.Radio ? (checked ? Icons.radioOn : Icons.radioOff) : ""
    property string text: ""
    property string detail: ""
    property color glyphColor: mark === MenuRow.None ? Theme.foreground
        : checked ? Theme.accent : Theme.muted
    property color textColor: Theme.foreground

    implicitWidth: row.implicitWidth + Theme.inset * 2
    implicitHeight: Theme.cellHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => triggered(mouse.button === Qt.RightButton)

    HoverFill {
        active: root.menu?.keyRow ? root.menu.keyRow === root : root.containsMouse
        pressed: root.pressed
    }

    RowLayout {
        id: row
        anchors {
            fill: parent
            leftMargin: Theme.inset
            rightMargin: Theme.inset
        }
        spacing: Theme.inset

        Label {
            visible: root.glyph.length > 0
            text: root.glyph
            color: root.glyphColor
        }

        Label {
            Layout.fillWidth: true
            text: root.text
            color: root.textColor
            elide: Text.ElideRight
        }

        Label {
            visible: root.detail.length > 0
            text: root.detail
            color: Theme.muted
        }
    }
}
