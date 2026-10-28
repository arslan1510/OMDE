pragma Singleton

import QtQuick
import Quickshell
import OMDE.Search
import qs

Singleton {
    id: root

    property var extra: []
    onExtraChanged: rebuild()

    property bool ready: false
    property var itemsByKey: ({})

    SearchIndex {
        id: searchIndex
    }

    function keyFor(entry: var): string {
        return entry.id ?? ("action:" + entry.name);
    }

    function rebuild(): void {
        ready = false;
        searchIndex.clear();
        const items = {};
        const apps = DesktopEntries.applications.values
            .filter(app => !app.noDisplay)
            .sort((a, b) => a.name.localeCompare(b.name));
        for (const app of apps) {
            const key = root.keyFor(app);
            const words = [app.genericName, ...app.keywords, app.id].filter(Boolean);
            searchIndex.add(null, app.name, words, key);
            items[key] = app;
        }
        for (const entry of root.extra) {
            const key = root.keyFor(entry);
            searchIndex.add(null, entry.name, entry.keywords ?? [], key);
            items[key] = entry;
        }
        root.itemsByKey = items;
        ready = true;
    }

    Component.onCompleted: rebuild()

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.rebuild(); }
    }

    function search(query: string, limit: int): var {
        const found = [];
        const keys = searchIndex.rankKeys(query, limit, Usage.scores());
        for (const key of keys) {
            const item = root.itemsByKey[key];
            if (item) found.push(item);
        }
        return found;
    }

    function launch(app: var): void {
        Usage.bump(root.keyFor(app));
        if (app.run) {
            app.run();
            return;
        }
        if (!app.runInTerminal) {
            app.execute();
            return;
        }
        Quickshell.execDetached({
            command: Config.terminal.concat(app.command),
            workingDirectory: app.workingDirectory
        });
    }

    function forAppId(appId: string): DesktopEntry {
        return root.ready && appId ? DesktopEntries.heuristicLookup(appId) : null;
    }

    function iconFor(app: var): string {
        return app?.icon ? Quickshell.iconPath(app.icon, true) : "";
    }
}
