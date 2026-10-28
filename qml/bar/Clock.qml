import QtQuick
import Quickshell
import qs
import qs.components

Segment {
    id: root

    text: Qt.formatDateTime(clock.date, Config.clockFormat)
    tooltip: [{ text: Qt.formatDateTime(clock.date, Config.dateFormat) }]
    interactive: true
    onClicked: Popouts.toggle(root, calendar)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Component {
        id: calendar

        Calendar {}
    }
}
