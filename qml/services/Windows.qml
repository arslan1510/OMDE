pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import OMDE.Search
import qs

Singleton {
    id: root

    property var recent: []
    readonly property var ordered: {
        const all = ToplevelManager.toplevels.values;
        return recent.filter(t => all.includes(t)).concat(all.filter(t => !recent.includes(t)));
    }
    readonly property var signature: ordered.map(t => t.title + "\u0000" + t.appId)

    SearchIndex {
        id: searchIndex
    }

    function rebuild(): void {
        searchIndex.clear();
        const active = ToplevelManager.activeToplevel;
        for (const toplevel of root.ordered) {
            if (toplevel === active)
                continue;
            const app = Apps.forAppId(toplevel.appId);
            const row = {
                name: Format.oneLine(toplevel.title) || app?.name || toplevel.appId,
                icon: app?.icon ?? "",
                detail: app?.name ?? toplevel.appId,
                toplevel: toplevel
            };
            searchIndex.add(row, row.name, [row.detail, toplevel.appId].filter(Boolean), "");
        }
    }

    Component.onCompleted: rebuild()
    onSignatureChanged: rebuild()

    function search(query: string, limit: int): var {
        return searchIndex.rank(query, limit, {});
    }

    function focus(row: var): void {
        row.toplevel.activate();
    }

    Connections {
        target: Apps
        function onReadyChanged() { if (Apps.ready) root.rebuild(); }
    }

    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() {
            const active = ToplevelManager.activeToplevel;
            if (active)
                root.recent = [active].concat(root.ordered.filter(t => t !== active));
            else
                root.rebuild();
        }
    }
}
