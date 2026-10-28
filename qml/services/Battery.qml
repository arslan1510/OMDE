pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import qs

Singleton {
    id: root

    enum Level { Normal, Warning, Critical }

    readonly property UPowerDevice device: UPower.displayDevice
    readonly property int percent: Math.round(device.percentage * 100)
    readonly property bool charging: device.state === UPowerDeviceState.Charging
    readonly property bool discharging: device.state === UPowerDeviceState.Discharging
    readonly property int level: !discharging ? Battery.Normal
        : percent <= Config.criticalBatteryThreshold ? Battery.Critical
        : percent <= Config.lowBatteryThreshold ? Battery.Warning : Battery.Normal
    readonly property string status: UPowerDeviceState.toString(device.state)
    readonly property real timeLeft: charging ? device.timeToFull : discharging ? device.timeToEmpty : 0
    readonly property real watts: charging || discharging ? Math.abs(device.changeRate) : 0

    readonly property int profile: PowerProfiles.profile
    readonly property var profiles: [PowerProfile.PowerSaver, PowerProfile.Balanced]
        .concat(PowerProfiles.hasPerformanceProfile ? [PowerProfile.Performance] : [])

    function setProfile(value: int): void {
        PowerProfiles.profile = value;
    }

    onLevelChanged: {
        if (level === Battery.Warning)
            Notifs.post("Battery low", percent + "% left", false);
        else if (level === Battery.Critical)
            Notifs.post("Battery critical", percent + "% left: plug in, or the laptop powers off soon", true);
    }
}
