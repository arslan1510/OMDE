pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int visibleTags: adapter.bar.visibleTags
    readonly property var screenNames: adapter.bar.screenNames
    readonly property int barColumns: adapter.bar.columns

    readonly property bool showLayout: adapter.bar.modules.layout
    readonly property bool showTitle: adapter.bar.modules.title
    readonly property bool showClock: adapter.bar.modules.clock
    readonly property bool showMedia: adapter.bar.modules.media
    readonly property bool showNetwork: adapter.bar.modules.network
    readonly property bool showBluetooth: adapter.bar.modules.bluetooth
    readonly property bool showAudio: adapter.bar.modules.audio
    readonly property bool showBrightness: adapter.bar.modules.brightness
    readonly property bool showSystem: adapter.bar.modules.system
    readonly property bool showBattery: adapter.bar.modules.battery
    readonly property bool showNotifications: adapter.bar.modules.notifications
    readonly property bool showTray: adapter.bar.modules.tray
    readonly property bool showKeepAwake: adapter.bar.modules.keepAwake

    readonly property string clockFormat: adapter.clock.format
    readonly property string dateFormat: adapter.clock.dateFormat

    readonly property int volumeStep: adapter.steps.volume
    readonly property int brightnessStep: adapter.steps.brightness

    readonly property int lowBatteryThreshold: adapter.battery.low
    readonly property int criticalBatteryThreshold: adapter.battery.critical

    readonly property int osdTimeout: adapter.osd.timeout

    readonly property int systemInterval: adapter.system.interval
    readonly property int processInterval: adapter.system.processInterval
    readonly property int processCount: adapter.system.processCount
    readonly property int systemWarning: adapter.system.warning

    readonly property int notificationTimeout: adapter.notifications.timeout
    readonly property int notificationMaxPopups: adapter.notifications.maxPopups
    readonly property int notificationColumns: adapter.notifications.columns

    readonly property int idleLock: adapter.idle.lock
    readonly property int idleScreenOff: adapter.idle.screenOff

    readonly property int launcherRows: adapter.launcher.rows
    readonly property var terminal: adapter.launcher.terminal

    readonly property string screenshotDir: adapter.screenshot.dir

    readonly property real scale: adapter.scale

    readonly property var wallpaper: adapter.wallpaper !== ""
        ? adapter.wallpaper
        : Qt.resolvedUrl("assets/nixos-wallpaper.svg")

    function reload(): void {
        file.reload();
    }

    FileView {
        id: file
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omde/config.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property JsonObject bar: JsonObject {
                property int visibleTags: 3
                property int columns: 102
                property var screenNames: []
                property JsonObject modules: JsonObject {
                    property bool layout: true
                    property bool title: true
                    property bool clock: true
                    property bool media: true
                    property bool network: true
                    property bool bluetooth: true
                    property bool audio: true
                    property bool brightness: true
                    property bool system: true
                    property bool battery: true
                    property bool notifications: true
                    property bool tray: true
                    property bool keepAwake: true
                }
            }

            property JsonObject clock: JsonObject {
                property string format: "hh:mm"
                property string dateFormat: "dddd d MMMM yyyy"
            }

            property JsonObject steps: JsonObject {
                property int volume: 5
                property int brightness: 5
            }

            property JsonObject battery: JsonObject {
                property int low: 20
                property int critical: 10
            }

            property JsonObject osd: JsonObject {
                property int timeout: 3000
            }

            property JsonObject system: JsonObject {
                property int interval: 3000
                property int processInterval: 2000
                property int processCount: 6
                property int warning: 90
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 5000
                property int maxPopups: 3
                property int columns: 44
            }

            property JsonObject idle: JsonObject {
                property int lock: 300
                property int screenOff: 360
            }

            property JsonObject launcher: JsonObject {
                property int rows: 8
                property var terminal: ["xdg-terminal-exec"]
            }

            property JsonObject screenshot: JsonObject {
                property string dir: Quickshell.env("HOME") + "/Pictures/Screenshots"
            }

            property real scale: 1.0
            property string wallpaper: ""
        }
    }
}
