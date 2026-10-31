pragma Singleton

import Quickshell
import Quickshell.Io
import OMDE.Search
import qs

Singleton {
    id: root

    property int revision: 0

    SearchIndex {
        id: searchIndex
    }

    function refresh(): void {
        lister.running = true;
    }

    function search(query: string, limit: int): var {
        root.revision;
        return searchIndex.rank(query, limit, {});
    }

    function copy(entry: var): void {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id]);
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                searchIndex.clear();
                const lines = text.split("\n").filter(line => line.length > 0);
                for (const line of lines) {
                    const tab = line.indexOf("\t");
                    const entry = { id: line.slice(0, tab), name: line.slice(tab + 1) };
                    searchIndex.add(entry, entry.name, [], "");
                }
                root.revision++;
            }
        }
    }
}
