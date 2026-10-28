pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import OMDE.Logind
import qs

Singleton {
    id: root

    property bool locked: false
    property bool secure: false
    property bool keepAwake: true
    readonly property bool checking: pam.active
    property string failure: ""
    property string pending: ""

    function lock(): void {
        failure = "";
        locked = true;
    }

    function authenticate(password: string): void {
        if (pam.active)
            return;
        pending = password;
        failure = "";
        pam.start();
    }

    function suspend(): void { Logind.suspend(); }
    function reboot(): void { Logind.reboot(); }
    function powerOff(): void { Logind.powerOff(); }
    function logout(): void { Mango.quit(); }

    // Hold sleep until every screen is locked, so resume never shows the desktop.
    Binding {
        target: Logind
        property: "inhibitSleep"
        value: !root.secure
    }

    Binding {
        target: Logind
        property: "lockedHint"
        value: root.locked
    }

    Connections {
        target: Logind

        function onPrepareForSleep(start: bool): void {
            if (start)
                root.lock();
        }
        function onLockRequested(): void { root.lock(); }
        function onUnlockRequested(): void { root.locked = false; }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellPath("pam")
        config: "lock"
        onPamMessage: {
            if (responseRequired) {
                respond(root.pending);
                root.pending = "";
            }
        }
        onCompleted: result => {
            root.pending = "";
            if (result === PamResult.Success)
                root.locked = false;
            else
                root.failure = result === PamResult.Failed ? "wrong password" : PamResult.toString(result);
        }
    }

    IdleMonitor {
        timeout: Config.idleLock
        enabled: timeout > 0
        onIsIdleChanged: if (isIdle) root.lock()
    }

    IdleMonitor {
        timeout: Config.idleScreenOff
        enabled: timeout > 0
        onIsIdleChanged: Mango.setScreensPowered(!isIdle)
    }
}
