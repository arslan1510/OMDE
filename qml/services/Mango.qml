pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string socketPath: Quickshell.env("MANGO_INSTANCE_SIGNATURE") ?? ""

    property var monitors: []
    readonly property string focusedName: monitors.find(m => m.active)?.name ?? ""
    readonly property int tagCount: Math.max(0, ...monitors.map(m => m.tags.length))
    property var layouts: []
    property string snapshot: ""
    property bool focusedFloating: false

    function monitorFor(name: string): var {
        return monitors.find(m => m.name === name) ?? null;
    }

    function selectTag(monitorName: string, tagId: int): void {
        dispatch("viewcrossmon," + tagId + ",^" + monitorName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "$");
    }

    function setLayout(name: string): void {
        dispatch("setlayout," + name);
    }

    function setScreensPowered(on: bool): void {
        for (const m of monitors)
            dispatch((on ? "wakeup_monitor," : "sleep_monitor,") + m.name);
    }

    function quit(): void {
        dispatch("quit");
    }

    function dispatch(args: string): void {
        Quickshell.execDetached({
            command: ["mmsg", "dispatch", args],
            environment: { MANGO_INSTANCE_SIGNATURE: socketPath }
        });
    }

    function toMonitor(m: var): var {
        return {
            name: m.name,
            active: m.active,
            layout: m.layout_symbol,
            tags: m.tags.map(t => ({
                id: t.index,
                active: t.is_active,
                urgent: t.is_urgent,
                occupied: t.client_count > 0
            }))
        };
    }

    // Keep each monitor's tags array when unchanged, so bindings don't re-run.
    function apply(line: string): void {
        const next = JSON.parse(line).monitors.map(toMonitor);
        const key = JSON.stringify(next);
        if (key === snapshot)
            return;
        snapshot = key;
        for (const m of next) {
            const previous = monitorFor(m.name);
            if (previous && JSON.stringify(previous.tags) === JSON.stringify(m.tags))
                m.tags = previous.tags;
        }
        monitors = next;
    }

    Process {
        id: layoutQuery
        stdout: StdioCollector {
            onStreamFinished: root.layouts = JSON.parse(text).layouts
        }
    }

    // Mango names its socket mango-<pid>.sock; skip sockets left by dead instances.
    Process {
        id: finder
        command: ["sh", "-c", 'for s in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/mango-*.sock; do '
            + 'pid=${s##*/mango-}; pid=${pid%.sock}; '
            + '[ -S "$s" ] && [ "$(cat "/proc/$pid/comm" 2>/dev/null)" = mango ] && echo "$s" && exit; '
            + 'done']
        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.trim();
                if (found.length > 0)
                    root.socketPath = found;
            }
        }
    }

    Component.onCompleted: if (socketPath.length === 0) finder.running = true

    Socket {
        path: root.socketPath
        connected: true
        onConnectionStateChanged: {
            if (connected) {
                write("watch all-monitors\n");
                flush();
                if (root.layouts.length === 0)
                    layoutQuery.exec({
                        command: ["mmsg", "get", "layouts"],
                        environment: { MANGO_INSTANCE_SIGNATURE: path }
                    });
            }
        }
        onError: if (!connected) finder.running = true
        parser: SplitParser {
            onRead: line => root.apply(line)
        }
    }

    Socket {
        path: root.socketPath
        connected: true
        onConnectionStateChanged: {
            if (connected) {
                write("watch focusing-client\n");
                flush();
            }
        }
        parser: SplitParser {
            onRead: line => root.focusedFloating = JSON.parse(line).is_floating === true
        }
    }
}
