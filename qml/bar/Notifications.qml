pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs
import qs.components
import qs.services

Segment {
    id: root

    text: Notifs.dnd ? Icons.bellOff : Notifs.count > 0 ? Icons.bellUnread : Icons.bell
    textColor: Notifs.count > 0 && !Notifs.dnd ? Theme.accent : Theme.muted
    interactive: true
    rightClickable: true
    onClicked: if (Notifs.count > 0) Popouts.toggle(root, list)
    onRightClicked: Notifs.toggleDnd()

    Connections {
        target: Notifs
        function onCountChanged() {
            if (Notifs.count === 0)
                Popouts.release(root);
        }
    }

    Component {
        id: list

        Menu {
            width: Theme.notificationWidth

            Repeater {
                model: ScriptModel {
                    values: Notifs.list
                }

                MenuRow {
                    required property Notification modelData
                    Layout.fillWidth: true
                    text: Format.oneLine(Format.headline(modelData))
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onTriggered: secondary => {
                        if (secondary) {
                            modelData.dismiss();
                            return;
                        }
                        Notifs.activate(modelData);
                        Popouts.close();
                    }
                }
            }

            MenuRow {
                Layout.fillWidth: true
                text: "clear all"
                textColor: Theme.muted
                onTriggered: Notifs.clear()
            }
        }
    }
}
