pragma Singleton

import QtQuick
import Quickshell
import qs

Singleton {
    id: root

    property Item owner: null
    property Component content: null
    property bool pinned: false
    property bool shown: false
    property bool hovered: false

    property Component extension: null
    property Item extensionOwner: null
    readonly property bool extended: extension !== null
    property real extensionRoom: 0

    readonly property bool grabbing: (shown && pinned) || extended

    function isOpenFor(item: Item): bool {
        return shown && owner === item;
    }

    function extend(item: Item, component: Component): void {
        if (pinned)
            close();
        extensionOwner = item;
        extension = component;
    }

    function retract(): void {
        if (pinned)
            close();
        extension = null;
        extensionOwner = null;
    }

    function toggleExtension(item: Item, component: Component): void {
        if (extended && extensionOwner === item)
            retract();
        else
            extend(item, component);
    }

    function dismiss(): void {
        close();
        retract();
    }

    function show(item: Item, component: Component, pin: bool): void {
        openDelay.stop();
        closeDelay.stop();
        pending.owner = null;
        owner = item;
        content = component;
        pinned = pin;
        shown = true;
    }

    function close(): void {
        openDelay.stop();
        closeDelay.stop();
        pending.owner = null;
        if (!shown)
            return;
        pinned = false;
        shown = false;
        cooldown.restart();
    }

    function release(item: Item): void {
        if (owner === item)
            close();
        if (extensionOwner === item)
            retract();
    }

    function toggle(item: Item, component: Component): void {
        if (shown && pinned && owner === item)
            close();
        else
            show(item, component, true);
    }

    function hoverEntered(item: Item, component: Component): void {
        pointer.over = item;
        if (pinned)
            return;
        if (shown && owner === item) {
            closeDelay.stop();
            return;
        }
        if (shown || cooldown.running) {
            show(item, component, false);
            return;
        }
        pending.owner = item;
        pending.content = component;
        openDelay.restart();
    }

    function hoverExited(item: Item): void {
        if (pointer.over === item)
            pointer.over = null;
        if (pending.owner === item) {
            pending.owner = null;
            openDelay.stop();
        }
        if (shown && !pinned && owner === item)
            closeDelay.restart();
    }

    onHoveredChanged: if (!hovered && shown && !pinned) closeDelay.restart()
    onOwnerChanged: if (!owner) close()

    QtObject {
        id: pending
        property Item owner: null
        property Component content: null
    }

    QtObject {
        id: pointer
        property Item over: null
    }

    Timer {
        id: openDelay
        interval: Theme.tooltipDelay
        onTriggered: {
            if (pending.owner)
                root.show(pending.owner, pending.content, false);
        }
    }

    Timer {
        id: closeDelay
        interval: Theme.popoutCloseDelay
        onTriggered: {
            if (!root.pinned && !root.hovered && pointer.over !== root.owner)
                root.close();
        }
    }

    Timer {
        id: cooldown
        interval: Theme.tooltipDelay
    }
}
