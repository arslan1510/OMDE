pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property NetworkDevice device: {
        const connected = Networking.devices.values.filter(d => d.connected);
        return connected.find(d => d.type === DeviceType.Wired)
            ?? connected.find(d => d.type === DeviceType.Wifi) ?? null;
    }
    readonly property bool wired: device?.type === DeviceType.Wired
    readonly property bool wifi: device?.type === DeviceType.Wifi
    readonly property var network: wired ? device.network
        : wifi ? device.networks.values.find(n => n.connected) ?? null : null
    readonly property int signal: wifi ? Math.round((network?.signalStrength ?? 0) * 100) : 0
    readonly property string name: network?.name ?? ""

    readonly property WifiDevice wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var networks: (wifiDevice?.networks.values ?? []).slice()
        .sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength)
    property bool scanning: false
    property WifiNetwork joining: null
    property WifiNetwork asking: null

    function setWifiEnabled(on: bool): void {
        Networking.wifiEnabled = on;
    }

    function secured(network: var): bool {
        return network.security !== WifiSecurityType.Open;
    }

    function choose(network: var): void {
        if (network.connected) {
            network.disconnect();
        } else if (network.known || !secured(network)) {
            joining = network;
            network.connect();
        } else {
            asking = network;
        }
    }

    function forget(network: var): void {
        network.forget();
    }

    Binding {
        when: root.wifiDevice !== null
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.scanning
    }

    Connections {
        target: root.joining
        function onConnectedChanged() {
            if (root.joining.connected)
                root.joining = null;
        }
        function onConnectionFailed(reason) {
            if (reason === ConnectionFailReason.NoSecrets)
                root.asking = root.joining;
            root.joining = null;
        }
    }
}
