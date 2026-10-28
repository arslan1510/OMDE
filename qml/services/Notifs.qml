pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs

Singleton {
    id: root

    readonly property int count: server.trackedNotifications.values.length
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    property list<QtObject> popups: []
    property bool dnd: false

    function clear(): void {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    function activate(n: var): void {
        const action = n.actions.find(a => a.identifier === "default");
        if (action)
            action.invoke();
        else
            n.dismiss();
    }

    function post(summary: string, body: string, critical: bool): void {
        Quickshell.execDetached(["notify-send", "--app-name=omde",
            "--urgency=" + (critical ? "critical" : "normal"), summary, body]);
    }

    function toggleDnd(): void {
        dnd = !dnd;
        if (dnd)
            for (const n of popups.slice())
                hidePopup(n);
    }

    function held(n: var): bool {
        return dnd && n.urgency !== NotificationUrgency.Critical;
    }

    function popupDuration(n: var): int {
        if (n.urgency === NotificationUrgency.Critical || n.expireTimeout === 0)
            return 0;
        return n.expireTimeout > 0 ? n.expireTimeout : Config.notificationTimeout;
    }

    function show(n: var): void {
        if (held(n))
            return;
        const stack = [n].concat(popups.filter(p => p !== n));
        popups = stack.slice(0, Config.notificationMaxPopups);
        for (const old of stack.slice(Config.notificationMaxPopups))
            hidePopup(old);
    }

    function hidePopup(n: var): void {
        removePopup(n);
        if (n.transient)
            n.expire();
    }

    function removePopup(n: var): void {
        popups = popups.filter(p => p !== n);
    }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true
        keepOnReload: true
        onNotification: n => {
            if (n.transient && root.held(n))
                return;
            n.tracked = true;
            n.closed.connect(() => root.removePopup(n));
            n.summaryChanged.connect(() => root.show(n));
            n.bodyChanged.connect(() => root.show(n));
            root.show(n);
        }
    }

    Instantiator {
        model: ScriptModel {
            values: [...root.popups]
        }

        Timer {
            required property Notification modelData
            readonly property string content: modelData.summary + modelData.body
            interval: root.popupDuration(modelData)
            running: interval > 0
            onContentChanged: if (interval > 0) restart()
            onTriggered: root.hidePopup(modelData)
        }
    }
}
