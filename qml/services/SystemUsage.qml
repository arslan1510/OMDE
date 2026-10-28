pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    property int cpu: 0
    // Memory in MiB.
    property real memUsed: 0
    property real memTotal: 0
    property int cores: 1
    readonly property int memPercent: memTotal > 0 ? Math.round(memUsed / memTotal * 100) : 0
    readonly property bool busy: cpu >= Config.systemWarning || memPercent >= Config.systemWarning
    property var processes: []
    property var lastStat: null

    function sampleProcesses(): void {
        if (!sampler.running)
            sampler.running = true;
    }

    // top -e m prints MiB but falls back to a suffix for wide values.
    function parseMem(value: string): real {
        const n = parseFloat(value) || 0;
        const scale = { k: 1 / 1024, m: 1, g: 1024, t: 1024 * 1024 }[value.slice(-1)];
        return n * (scale || 1);
    }

    // NixOS wrappers end in "-wrapped"; the kernel cuts names at 15 chars.
    function cleanName(name: string): string {
        const truncated = name.length === 15;
        name = name.replace(/^\./, "");
        if (name.endsWith("-wrapped"))
            return name.slice(0, -"-wrapped".length);
        const suffix = truncated ? name.match(/-[a-z]*$/) : null;
        return suffix && "-wrapped".startsWith(suffix[0]) ? name.slice(0, -suffix[0].length) : name;
    }

    function readStat(text: string): void {
        const lines = text.split("\n");
        // user nice system idle iowait irq softirq steal
        const fields = lines[0].trim().split(/\s+/).slice(1, 9).map(Number);
        const idle = fields[3] + fields[4];
        const total = fields.reduce((a, b) => a + b, 0);
        if (lastStat && total > lastStat.total)
            cpu = Math.round(100 * (1 - (idle - lastStat.idle) / (total - lastStat.total)));
        lastStat = { idle: idle, total: total };
        cores = Math.max(1, lines.filter(line => /^cpu\d/.test(line)).length);
    }

    function readMeminfo(text: string): void {
        const field = key => {
            const match = text.match(new RegExp("^" + key + ":\\s+(\\d+)", "m"));
            return match ? parseInt(match[1]) / 1024 : 0;
        };
        memTotal = field("MemTotal");
        memUsed = memTotal - field("MemAvailable");
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: root.readStat(text())
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: root.readMeminfo(text())
    }

    Timer {
        interval: Config.systemInterval
        running: Config.showSystem
        repeat: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
        }
    }

    // The first top frame averages since boot; only the second is current.
    Process {
        id: sampler
        command: ["top", "-b", "-n", "2", "-d", "0.5", "-o", "%CPU", "-e", "m", "-w", "512"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                let second = -1;
                lines.forEach((line, index) => {
                    if (line.startsWith("top -"))
                        second = index;
                });
                const groups = new Map();
                for (const line of lines.slice(second + 1)) {
                    if (!/^\s*\d/.test(line))
                        continue;
                    const f = line.trim().split(/\s+/);
                    if (f.length < 12)
                        continue;
                    const name = root.cleanName(f.slice(11).join(" "));
                    if (name === "top")
                        continue;
                    const group = groups.get(name) || { name: name, count: 0, cpu: 0, mem: 0 };
                    group.count++;
                    group.cpu += (parseFloat(f[8]) || 0) / root.cores;
                    group.mem += root.parseMem(f[5]);
                    groups.set(name, group);
                }
                root.processes = [...groups.values()]
                    .sort((a, b) => b.cpu - a.cpu || b.mem - a.mem)
                    .slice(0, Config.processCount);
            }
        }
    }
}
