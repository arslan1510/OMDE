pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.services

WlSessionLock {
    locked: Session.locked
    onSecureChanged: Session.secure = secure

    WlSessionLockSurface {
        color: Theme.background

        WallpaperImage {}

        Card {
            anchors.centerIn: parent
            width: Theme.notificationWidth
            shown: true
            dy: Theme.travel

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            PasswordPrompt {
                width: parent.width
                header: Qt.formatDateTime(clock.date, Config.clockFormat)
                    + "  " + Qt.formatDateTime(clock.date, Config.dateFormat)
                glyph: Icons.lock
                placeholder: "password"
                status: Session.checking ? "checking…" : Session.failure
                error: !Session.checking && Session.failure.length > 0
                onSubmitted: password => Session.authenticate(password)
                onCancelled: input.text = ""
                holdFocus: true
                Component.onCompleted: input.forceActiveFocus()
            }
        }
    }
}
