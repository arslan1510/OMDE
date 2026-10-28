import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services

MouseArea {
    id: root

    required property var entry
    property string glyph: ""
    property bool current: false
    property string label: ""

    readonly property string iconSource: entry.glyph ? "" : Apps.iconFor(entry)
    readonly property string detail: entry.detail ?? ""

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Theme.gap
            rightMargin: Theme.inset
        }
        spacing: Theme.inset

        Label {
            text: Icons.selected
            color: Theme.accent
            opacity: root.current ? 1 : 0
            Behavior on opacity { Motion {} }
        }

        Item {
            implicitWidth: Theme.iconSize
            implicitHeight: Theme.iconSize

            Icon {
                anchors.centerIn: parent
                visible: root.iconSource.length > 0
                source: root.iconSource
            }

            Label {
                anchors.centerIn: parent
                visible: root.iconSource.length === 0
                text: root.entry.glyph || root.glyph
            }
        }

        Label {
            Layout.fillWidth: true
            text: root.label || Format.oneLine(root.entry.name)
            elide: Text.ElideRight
            color: root.label ? Theme.warning : root.current ? Theme.accent : Theme.foreground
            Behavior on color { Motion {} }
        }

        Label {
            visible: root.detail.length > 0
            text: root.detail
            color: Theme.muted
        }
    }
}
