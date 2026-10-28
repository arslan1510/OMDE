pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs

Column {
    id: root

    property var lines: []

    padding: Theme.inset
    spacing: Theme.lineGap

    Repeater {
        model: ScriptModel {
            values: root.lines
        }

        Item {
            id: line

            required property var modelData
            readonly property bool isSeparator: modelData.separator === true

            width: isSeparator ? 1 : parts.implicitWidth
            height: isSeparator ? rule.implicitHeight : parts.implicitHeight

            Rule {
                id: rule
                visible: line.isSeparator
                width: root.width - root.leftPadding - root.rightPadding
            }

            Row {
                id: parts
                visible: !line.isSeparator

                Label {
                    text: line.modelData.prefix || ""
                    color: Theme.muted
                }

                Label {
                    text: line.modelData.text || ""
                    color: line.modelData.muted ? Theme.muted : Theme.foreground
                }

                Label {
                    text: line.modelData.detail || ""
                    color: Theme.muted
                }
            }
        }
    }
}
