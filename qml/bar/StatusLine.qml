import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs
import qs.components
import qs.services

RowLayout {
    spacing: Theme.gutter

    NowPlaying {
        visible: Config.showMedia && Media.player !== null
    }

    Notifications {
        visible: Config.showNotifications
    }

    Segment {
        visible: Config.showKeepAwake
        text: Session.keepAwake ? Icons.awake : Icons.awakeOff
        textColor: Session.keepAwake ? Theme.accent : Theme.muted
        tooltip: [{ text: Session.keepAwake ? "keeping awake"
            : Config.idleLock > 0 ? "locks after " + Math.round(Config.idleLock / 60) + " min idle"
            : "no idle lock" }]
        interactive: true
        onClicked: Session.keepAwake = !Session.keepAwake
    }

    Segment {
        id: bluetooth
        visible: Config.showBluetooth
        text: !Bluetooth.powered ? Icons.bluetoothOff
            : Bluetooth.connected.length > 0 ? Icons.bluetoothConnected : Icons.bluetooth
        textColor: Bluetooth.connected.length > 0 ? Theme.accent : Theme.muted
        tooltip: Bluetooth.connected.map(d => ({
            text: d.name + (d.batteryAvailable ? "  " + Format.percent(d.battery) : "")
        }))
        interactive: true
        rightClickable: true
        onClicked: Popouts.toggle(bluetooth, bluetoothList)
        onRightClicked: Bluetooth.toggle()

        Component {
            id: bluetoothList
            BluetoothList {}
        }
    }

    Segment {
        visible: Config.showBrightness
        text: Icons.brightness(Brightness.percent)
        textColor: Theme.muted
        scrollable: true
        onScrolled: steps => Brightness.adjust(steps)
    }

    Segment {
        id: network
        visible: Config.showNetwork
        text: Network.wifi ? Icons.wifi(Network.signal) : Network.wired ? Icons.ethernet : Icons.networkOff
        textColor: Network.wifi || Network.wired ? Theme.muted : Theme.warning
        tooltip: [
            { text: Network.device ? Network.name : "disconnected" },
            { text: Network.wifi ? Network.signal + "% signal" : "", muted: true }
        ]
        interactive: true
        rightClickable: true
        onClicked: Popouts.toggle(network, networkList)
        onRightClicked: Network.setWifiEnabled(!Network.wifiEnabled)

        Component {
            id: networkList
            NetworkList {}
        }
    }

    Segment {
        id: volume
        visible: Config.showAudio
        text: Icons.volume(Audio.percent, Audio.muted)
        textColor: Audio.muted ? Theme.muted : Theme.foreground
        interactive: true
        rightClickable: true
        scrollable: true
        onClicked: Popouts.toggle(volume, audioList)
        onRightClicked: Audio.toggleMute()
        onScrolled: steps => Audio.adjust(steps)

        Component {
            id: audioList
            AudioList {}
        }
    }

    System {
        visible: Config.showSystem
    }

    Segment {
        id: battery
        visible: Config.showBattery
        text: Icons.battery(Battery.percent, Battery.charging)
        textColor: Battery.level === Battery.Critical ? Theme.critical
            : Battery.level === Battery.Warning ? Theme.warning : Theme.muted
        readonly property string usage: (Battery.timeLeft > 0
            ? [Format.duration(Battery.timeLeft) + (Battery.charging ? " to full" : " left")] : [])
            .concat(Battery.watts > 0 ? [Battery.watts.toFixed(1) + " W"] : [])
            .join(", ")
        tooltip: [{ text: Battery.percent + "%" }, { text: usage, muted: true }]
        interactive: true
        onClicked: Popouts.toggle(battery, profileList)

        Component {
            id: profileList
            ProfileList {}
        }
    }

    Tray {
        visible: Config.showTray && SystemTray.items.values.length > 0
    }
}
