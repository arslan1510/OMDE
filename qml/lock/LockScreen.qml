pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.services

Scope {
    PersistentProperties {
        id: state
        reloadableId: "session-lock"
        property bool locked: false

        onLoaded: {
            locked = locked || Session.locked;
            Session.locked = locked;
        }
    }

    Connections {
        target: Session
        function onLockedChanged(): void { state.locked = Session.locked; }
    }

    Connections {
        target: Quickshell
        function onReloadCompleted(): void { Session.secure = lock.secure; }
    }

    WlSessionLock {
        id: lock
        locked: state.locked
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
}
