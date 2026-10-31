pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import qs
import qs.bar
import qs.launcher
import qs.lock
import qs.notifications
import qs.osd
import qs.polkit
import qs.services
import qs.wallpaper
import qs.wifi

ShellRoot {
    id: root

    readonly property var screens: Quickshell.screens.filter(screen => screen.name !== ""
        && (Config.screenNames.length === 0 || Config.screenNames.indexOf(screen.name) !== -1))

    readonly property ShellScreen barScreen: screens.find(screen => screen.name === Mango.focusedName)
        ?? screens[0] ?? null

    LazyLoader {
        id: onScreen
        active: root.barScreen !== null

        Scope {
            readonly property alias bar: bar
            readonly property alias osd: osd

            Bar {
                id: bar
                screen: root.barScreen
            }

            Osd {
                id: osd
                screen: root.barScreen
            }

            NotificationPopup {
                screen: root.barScreen
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Wallpaper {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    Launcher {
        id: launcher
        screen: root.barScreen
    }

    LockScreen {}

    PolkitPrompt {}

    WifiPrompt {}

    IpcHandler {
        target: "launcher"

        function toggle(): void { launcher.toggle("apps"); }
        function windows(): void { launcher.toggle("windows"); }
        function clipboard(): void { launcher.toggle("clipboard"); }
        function hide(): void { launcher.hide(); }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void { onScreen.item?.bar.toggle(); }
    }

    IpcHandler {
        target: "media"

        function playPause(): void { Media.playPause(); }
        function next(): void { Media.next(); }
        function previous(): void { Media.previous(); }
    }

    IpcHandler {
        target: "screenshot"

        function take(kind: string): void { Screenshot.take(kind); }
    }

    IpcHandler {
        target: "session"

        function lock(): void { Session.lock(); }
    }

    IpcHandler {
        target: "omde"

        function reloadTheme(): void { Scheme.reload(); }
        function reloadConfig(): void { Config.reload(); }

        function status(): string {
            return JSON.stringify({
                bar: onScreen.item?.bar.status() ?? null,
                osd: onScreen.item?.osd.shown ?? null,
                notifications: { count: Notifs.count, dnd: Notifs.dnd, popups: Notifs.popups.map(n => n.summary) },
                mango: {
                    focused: Mango.focusedName,
                    tagCount: Mango.tagCount,
                    layouts: Mango.layouts.map(l => l.name),
                    floating: Mango.focusedFloating,
                    monitors: Mango.monitors
                },
                audio: { percent: Audio.percent, muted: Audio.muted, micMuted: Audio.micMuted },
                session: { locked: Session.locked, secure: Session.secure, failure: Session.failure, keepAwake: Session.keepAwake },
                brightness: Brightness.percent,
                network: { name: Network.name, signal: Network.signal },
                battery: { percent: Battery.percent, status: Battery.status },
                bluetooth: { powered: Bluetooth.powered, connected: Bluetooth.connected.map(d => d.name) },
                system: { cpu: SystemUsage.cpu, memPercent: SystemUsage.memPercent }
            });
        }
    }
}
