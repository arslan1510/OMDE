pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth as Bt

Singleton {
    id: root

    readonly property Bt.BluetoothAdapter adapter: Bt.Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property var connected: Bt.Bluetooth.devices.values.filter(d => d.connected)
    readonly property var devices: (adapter?.devices.values ?? [])
        .filter(d => d.paired || d.deviceName.length > 0)
        .sort((a, b) => b.connected - a.connected || b.paired - a.paired || a.name.localeCompare(b.name))
    property bool discovering: false
    property Bt.BluetoothDevice pairing: null

    function toggle(): void {
        adapter.enabled = !adapter.enabled;
    }

    function activate(device: var): void {
        if (device.connected) {
            device.disconnect();
        } else if (device.paired) {
            device.connect();
        } else {
            pairing = device;
            device.pair();
        }
    }

    function forget(device: var): void {
        device.forget();
    }

    Binding {
        when: root.adapter !== null && root.powered
        target: root.adapter
        property: "discovering"
        value: root.discovering
    }

    Connections {
        target: root.pairing
        function onPairedChanged() {
            if (!root.pairing.paired)
                return;
            root.pairing.trusted = true;
            root.pairing.connect();
            root.pairing = null;
        }
    }
}
