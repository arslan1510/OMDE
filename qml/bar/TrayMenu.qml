pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

Menu {
    id: root

    required property QsMenuHandle menu
    property list<QtObject> submenus: []

    signal done()

    QsMenuOpener {
        id: opener
        menu: root.submenus.length > 0 ? root.submenus[root.submenus.length - 1] : root.menu
    }

    onBack: {
        if (submenus.length > 0)
            submenus = submenus.slice(0, -1);
        else
            Popouts.close();
    }

    MenuRow {
        Layout.fillWidth: true
        glyph: Icons.back
        glyphColor: Theme.muted
        text: "back"
        textColor: Theme.muted
        onTriggered: root.back()
    }

    Repeater {
        model: opener.children

        Item {
            id: row
            required property QsMenuEntry modelData
            Layout.fillWidth: true
            implicitWidth: entryRow.implicitWidth
            implicitHeight: modelData.isSeparator ? rule.implicitHeight : entryRow.implicitHeight

            Rule {
                id: rule
                visible: row.modelData.isSeparator
                width: parent.width
            }

            MenuRow {
                id: entryRow
                visible: !row.modelData.isSeparator
                anchors.fill: parent
                enabled: row.modelData.enabled
                mark: row.modelData.buttonType === QsMenuButtonType.CheckBox ? MenuRow.Check
                    : row.modelData.buttonType === QsMenuButtonType.RadioButton ? MenuRow.Radio
                    : MenuRow.None
                checked: row.modelData.checkState === Qt.Checked
                text: row.modelData.text + (row.modelData.hasChildren ? "  " + Icons.submenu : "")
                textColor: row.modelData.enabled ? Theme.foreground : Theme.muted
                onTriggered: {
                    if (row.modelData.hasChildren) {
                        root.submenus = root.submenus.concat([row.modelData]);
                        return;
                    }
                    row.modelData.triggered();
                    root.done();
                }
            }
        }
    }
}
