pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs
import qs.components
import qs.services

PanelWindow {
    id: root

    property list<QtObject> cards: []

    function merge(): void {
        const next = [...Notifs.popups];
        cards.forEach((card, index) => {
            if (next.indexOf(card) === -1)
                next.splice(Math.min(index, next.length), 0, card);
        });
        cards = next;
    }

    Component.onCompleted: merge()

    Connections {
        target: Notifs
        function onPopupsChanged() { root.merge(); }
    }

    visible: cards.length > 0
    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: Theme.gutter
        right: Theme.gutter
    }
    implicitWidth: Theme.notificationWidth
    implicitHeight: Math.min(Theme.toastWindowHeight, screen.height - Theme.gutter * 3)
    mask: Region {
        item: stack
    }
    exclusiveZone: -1
    focusable: false
    color: "transparent"
    WlrLayershell.namespace: "omde-notification"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: stack
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: Theme.gutter
        move: Transition {
            Motion {
                properties: "y"
                role: Motion.Move
            }
        }

        Repeater {
            model: ScriptModel {
                values: [...root.cards]
            }

            Card {
                id: card
                required property Notification modelData
                readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                width: stack.width
                shown: Notifs.popups.indexOf(modelData) !== -1
                dx: width / 3
                borderColor: critical ? Theme.critical : Theme.accent
                onExited: root.cards = root.cards.filter(other => other !== card.modelData)

                RetainableLock {
                    object: card.modelData
                    locked: true
                }

                Label {
                    id: body
                    width: parent.width
                    text: Format.headline(card.modelData)
                        + (card.modelData.body ? "\n" + card.modelData.body : "")
                    color: card.critical ? Theme.critical : Theme.foreground
                    wrapMode: Text.Wrap
                    maximumLineCount: 5
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: body
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => mouse.button === Qt.RightButton
                        ? Notifs.hidePopup(card.modelData) : Notifs.activate(card.modelData)
                }
            }
        }
    }
}
