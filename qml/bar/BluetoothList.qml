pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth as Bt
import qs
import qs.components
import qs.services

Menu {
    Component.onCompleted: Bluetooth.discovering = true
    Component.onDestruction: Bluetooth.discovering = false

    MenuRow {
        Layout.fillWidth: true
        mark: MenuRow.Check
        checked: Bluetooth.powered
        text: "bluetooth"
        onTriggered: Bluetooth.toggle()
    }

    Rule {
        Layout.fillWidth: true
        visible: Bluetooth.powered && Bluetooth.devices.length > 0
    }

    Repeater {
        model: ScriptModel {
            values: Bluetooth.powered ? Bluetooth.devices : []
        }

        MenuRow {
            required property Bt.BluetoothDevice modelData
            Layout.fillWidth: true
            glyph: modelData.connected ? Icons.bluetoothConnected : Icons.bluetooth
            glyphColor: modelData.connected ? Theme.accent : Theme.muted
            text: modelData.name
            textColor: modelData.connected ? Theme.accent : modelData.paired ? Theme.foreground : Theme.muted
            detail: modelData.pairing ? "pairing…"
                : modelData.connected && modelData.batteryAvailable ? Format.percent(modelData.battery)
                : modelData.paired ? "" : "new"
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onTriggered: secondary => secondary
                ? Bluetooth.forget(modelData) : Bluetooth.activate(modelData)
        }
    }
}
