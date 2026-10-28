pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function bump(key: string): void {
        if (!key) return;
        var entries = adapter.entries;
        var old = entries[key];
        var next = {};
        for (var k in entries) next[k] = entries[k];
        next[key] = { count: Math.min((old ? old.count : 0) + 1, 50), last: Date.now() };
        adapter.entries = next;
    }

    function scores(): var {
        var scores = {};
        for (var key in adapter.entries) {
            var score = boost(key);
            if (score > 0) scores[key] = score;
        }
        return scores;
    }

    function boost(key: string): real {
        if (!key) return 0;
        var e = adapter.entries[key];
        if (!e) return 0;
        var days = (Date.now() - (e.last || 0)) / 86400000;
        var recency = days < 4 ? 24 : days < 14 ? 16 : days < 31 ? 10 : days < 90 ? 5 : 2;
        return Math.min(e.count || 0, 10) * 2 + recency;
    }

    FileView {
        path: Quickshell.statePath("usage.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property var entries: ({})
        }
    }
}
