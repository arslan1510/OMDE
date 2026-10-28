pragma Singleton

import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    property int percent: 0
    readonly property bool muted: false
    property bool known: false

    signal levelChanged()

    onPercentChanged: {
        if (known)
            levelChanged();
        known = true;
    }
    property string device: ""
    property int max: 0
    property int target: -1

    function adjust(steps: int): void {
        setPercent(percent + steps * Config.brightnessStep);
    }

    function setPercent(value: real): void {
        percent = Math.max(1, Math.min(100, Math.round(value)));
        target = percent;
        flush();
    }

    function flush(): void {
        if (setter.running || target < 0)
            return;
        setter.command = ["brightnessctl", "-d", device, "set", target + "%"];
        target = -1;
        setter.running = true;
    }

    Process {
        command: ["brightnessctl", "-m", "-c", "backlight"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                root.max = parseInt(fields[4]);
                root.device = fields[0];
            }
        }
    }

    FileView {
        id: level
        path: root.device ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const value = parseInt(text());
            if (!setter.running && root.target < 0)
                root.percent = Math.round(value * 100 / root.max);
        }
    }

    Process {
        id: setter
        onRunningChanged: {
            if (running)
                return;
            if (root.target >= 0)
                root.flush();
            else
                level.reload();
        }
    }
}
