pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking as Nm
import qs
import qs.components
import qs.services

Menu {
    Component.onCompleted: Network.scanning = true
    Component.onDestruction: Network.scanning = false

    MenuRow {
        Layout.fillWidth: true
        mark: MenuRow.Check
        checked: Network.wifiEnabled
        text: "wi-fi"
        onTriggered: Network.setWifiEnabled(!Network.wifiEnabled)
    }

    Rule {
        Layout.fillWidth: true
        visible: Network.wifiEnabled && Network.networks.length > 0
    }

    Repeater {
        model: ScriptModel {
            values: Network.wifiEnabled ? Network.networks : []
        }

        MenuRow {
            required property Nm.WifiNetwork modelData
            Layout.fillWidth: true
            glyph: Icons.wifi(modelData.signalStrength * 100)
            glyphColor: modelData.connected ? Theme.accent : Theme.muted
            text: modelData.name
            textColor: modelData.connected ? Theme.accent : Theme.foreground
            detail: modelData.stateChanging ? "…" : Network.secured(modelData) ? Icons.secured : ""
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onTriggered: secondary => secondary
                ? Network.forget(modelData) : Network.choose(modelData)
        }
    }
}
