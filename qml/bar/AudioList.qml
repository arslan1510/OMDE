pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.components
import qs.services

Menu {
    id: root

    component DeviceRow: MenuRow {
        required property PwNode modelData
        Layout.fillWidth: true
        mark: MenuRow.Radio
        checked: modelData === (modelData.isSink ? Pipewire.defaultAudioSink : Pipewire.defaultAudioSource)
        text: Audio.nameOf(modelData)
        detail: modelData.isSink ? Icons.speaker : Icons.microphone
        onTriggered: Audio.use(modelData)
    }

    MenuRow {
        Layout.fillWidth: true
        mark: MenuRow.Check
        checked: Audio.muted
        text: "mute"
        onTriggered: Audio.toggleMute()
    }

    Rule {
        Layout.fillWidth: true
    }

    Repeater {
        model: ScriptModel {
            values: Audio.outputs
        }

        DeviceRow {}
    }

    Rule {
        Layout.fillWidth: true
        visible: Audio.inputs.length > 0
    }

    Repeater {
        model: ScriptModel {
            values: Audio.inputs
        }

        DeviceRow {}
    }
}
