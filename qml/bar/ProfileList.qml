pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs
import qs.components
import qs.services

Menu {
    Repeater {
        model: Battery.profiles

        MenuRow {
            required property int modelData
            readonly property string name: PowerProfile.toString(modelData)
            Layout.fillWidth: true
            mark: MenuRow.Radio
            checked: modelData === Battery.profile
            text: name.replace(/(.)([A-Z])/g, "$1 $2").toLowerCase()
            detail: Icons.profileGlyphs[name]
            onTriggered: Battery.setProfile(modelData)
        }
    }
}
