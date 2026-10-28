import QtQuick
import qs
import qs.components
import qs.services

Segment {
    id: root

    readonly property int nameColumns: 18

    function processLine(p: var): var {
        const name = Format.truncate(p.count > 1 ? p.name + " ×" + p.count : p.name, nameColumns);
        return {
            text: name,
            detail: " ".repeat(nameColumns - name.length)
                + (p.cpu.toFixed(1) + "%").padStart(7) + Format.mebibytes(p.mem).padStart(7)
        };
    }

    text: Icons.chip
    textColor: SystemUsage.busy ? Theme.warning : Theme.muted
    tooltip: [
        { prefix: "cpu", text: "  " + SystemUsage.cpu + "%" },
        { prefix: "mem", text: "  " + Format.mebibytes(SystemUsage.memUsed) + "/" + Format.mebibytes(SystemUsage.memTotal) },
        { separator: true }
    ].concat(SystemUsage.processes.length === 0 ? [{ text: "sampling…", muted: true }]
        : SystemUsage.processes.map(p => processLine(p)))

    Timer {
        interval: Config.processInterval
        running: Popouts.isOpenFor(root)
        repeat: true
        triggeredOnStart: true
        onTriggered: SystemUsage.sampleProcesses()
    }
}
