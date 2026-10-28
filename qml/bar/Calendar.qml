pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.components

Item {
    id: root

    readonly property date today: clock.date
    property date month: new Date(today.getFullYear(), today.getMonth(), 1)
    readonly property int firstDay: Qt.locale().firstDayOfWeek
    readonly property bool thisMonth: month.getFullYear() === today.getFullYear()
        && month.getMonth() === today.getMonth()
    readonly property var days: {
        const blanks = (month.getDay() - firstDay + 7) % 7;
        const length = new Date(month.getFullYear(), month.getMonth() + 1, 0).getDate();
        return Array(blanks).fill(0).concat(Array.from({ length: length }, (_, i) => i + 1));
    }
    readonly property real dayWidth: Theme.columns(3)
    readonly property real dayHeight: Theme.cellHeight

    function shift(months: int): void {
        month = new Date(month.getFullYear(), month.getMonth() + months, 1);
    }

    function key(event: var): bool {
        if (event.key !== Qt.Key_Left && event.key !== Qt.Key_Right)
            return false;
        shift(event.key === Qt.Key_Left ? -1 : 1);
        return true;
    }

    width: body.width
    height: body.height

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => root.shift(-notches.take(wheel.angleDelta.y))

        WheelSteps {
            id: notches
        }
    }

    Column {
        id: body
        padding: Theme.inset
        spacing: Theme.lineGap

        Item {
            width: grid.width
            height: Theme.cellHeight

            Segment {
                anchors.left: parent.left
                height: parent.height
                text: Icons.back
                textColor: Theme.muted
                interactive: true
                onClicked: root.shift(-1)
            }

            Label {
                anchors.centerIn: parent
                text: Qt.formatDate(root.month, "MMMM yyyy")
            }

            Segment {
                anchors.right: parent.right
                height: parent.height
                text: Icons.submenu
                textColor: Theme.muted
                interactive: true
                onClicked: root.shift(1)
            }
        }

        Grid {
            id: grid
            columns: 7
            columnSpacing: Theme.gap

            Repeater {
                model: 7

                Label {
                    required property int index
                    width: root.dayWidth
                    height: root.dayHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: Qt.locale().dayName((root.firstDay + index - 1) % 7 + 1, Locale.ShortFormat).slice(0, 2).toUpperCase()
                    color: Theme.muted
                }
            }

            Repeater {
                model: root.days

                Label {
                    required property int modelData
                    readonly property bool isToday: root.thisMonth && modelData === root.today.getDate()
                    width: root.dayWidth
                    height: root.dayHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData > 0 ? String(modelData) : ""
                    color: isToday ? Theme.background : Theme.foreground

                    Rectangle {
                        z: -1
                        visible: parent.isToday
                        anchors.fill: parent
                        color: Theme.accent
                    }
                }
            }
        }
    }
}
