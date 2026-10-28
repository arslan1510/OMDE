pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    function shown(monitorName: string): var {
        const ids = new Set(adapter.pinned);
        for (const tag of Mango.monitorFor(monitorName)?.tags ?? [])
            if (tag.active || tag.occupied || tag.urgent)
                ids.add(tag.id);
        return [...ids].filter(id => id <= Mango.tagCount).sort((a, b) => a - b);
    }

    function add(monitorName: string): void {
        const showing = shown(monitorName);
        for (let id = 1; id <= Mango.tagCount; id++) {
            if (showing.indexOf(id) === -1) {
                adapter.pinned = adapter.pinned.concat([id]).sort((a, b) => a - b);
                Mango.selectTag(monitorName, id);
                return;
            }
        }
    }

    function dismiss(monitorName: string, id: int): void {
        const tag = Mango.monitorFor(monitorName)?.tags.find(t => t.id === id);
        if (tag?.occupied)
            return;
        const rest = shown(monitorName).filter(other => other !== id);
        adapter.pinned = adapter.pinned.filter(p => p !== id);
        if (tag?.active)
            Mango.selectTag(monitorName, rest.filter(other => other < id).pop() ?? rest[0]);
    }

    FileView {
        path: Quickshell.statePath("tags.json")
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: adapter
            property list<int> pinned: []
        }
    }
}
