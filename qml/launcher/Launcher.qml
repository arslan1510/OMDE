pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

PromptWindow {
    id: root

    readonly property string query: input.text
    property string mode: "apps"
    property int selected: 0
    property var armed: null
    property var chosen: null

    readonly property var actions: [
        { name: "Lock", glyph: Icons.lock, keywords: ["screen"], run: Session.lock },
        { name: "Suspend", glyph: Icons.suspend, keywords: ["sleep"], run: Session.suspend },
        { name: "Log out", glyph: Icons.logout, keywords: ["exit", "quit"], confirm: true, run: Session.logout },
        { name: "Reboot", glyph: Icons.reboot, keywords: ["restart"], confirm: true, run: Session.reboot },
        { name: "Power off", glyph: Icons.power, keywords: ["shutdown"], confirm: true, run: Session.powerOff },
        { name: "Screenshot region", glyph: Icons.region, keywords: ["capture", "grab", "snip"], run: () => Screenshot.take("region") },
        { name: "Screenshot screen", glyph: Icons.screenshot, keywords: ["capture", "grab", "full"], run: () => Screenshot.take("screen") },
        { name: "Annotate screenshot", glyph: Icons.annotate, keywords: ["capture", "draw", "edit", "markup"], run: () => Screenshot.take("annotate") }
    ]

    Component.onCompleted: Apps.extra = actions

    readonly property var modes: ({
        apps: {
            glyph: Icons.search,
            empty: "",
            rows: q => Apps.search(q, Config.launcherRows),
            run: entry => Apps.launch(entry)
        },
        windows: {
            glyph: Icons.window,
            empty: "no other windows",
            rows: q => Windows.search(q, Config.launcherRows),
            run: entry => Windows.focus(entry)
        },
        clipboard: {
            glyph: Icons.clipboard,
            empty: "clipboard history is empty",
            rows: q => Clipboard.search(q, Config.launcherRows),
            run: entry => Clipboard.copy(entry),
            open: () => Clipboard.refresh()
        }
    })
    readonly property var results: visible ? modes[mode].rows(query) : []

    function show(name: string): void {
        runChosen();
        mode = name;
        modes[mode].open?.();
        input.text = "";
        selected = 0;
        shown = true;
    }

    function hide(): void {
        shown = false;
    }

    function toggle(name: string): void {
        shown && mode === name ? hide() : show(name);
    }

    function choose(): void {
        const entry = results[selected];
        if (!entry)
            return;
        if (entry.confirm && armed !== entry) {
            armed = entry;
            return;
        }
        chosen = { run: modes[mode].run, entry: entry };
        hide();
    }

    function runChosen(): void {
        if (!chosen)
            return;
        const c = chosen;
        chosen = null;
        c.run(c.entry);
    }

    function move(delta: int): void {
        if (results.length === 0) return;
        selected = (selected + delta + results.length) % results.length;
    }

    namespace: "omde-launcher"
    belowBar: true
    onDismissed: hide()
    onVisibleChanged: if (!visible) runChosen()
    onSelectedChanged: armed = null
    onQueryChanged: {
        armed = null;
        selected = 0;
    }
    onResultsChanged: {
        armed = null;
        selected = Math.max(0, Math.min(selected, results.length - 1));
        if (results.length === 0)
            selection.row = null;
        Qt.callLater(selection.snap);
    }
    onShownChanged: {
        armed = null;
        if (shown) {
            input.forceActiveFocus();
            Qt.callLater(selection.snap);
        }
    }

    Glide {
        id: selection
        property Item row: null
        to: row?.y ?? 0
        size: Theme.cellHeight
    }

    Rectangle {
        visible: selection.row !== null
        y: selection.start
        width: column.width
        height: selection.end - selection.start
        color: Theme.hover
    }

    Column {
        id: column
        width: parent.width
        spacing: Theme.gap

        PromptInput {
            id: input
            width: parent.width
            height: Theme.cellHeight
            glyph: root.modes[root.mode].glyph
            placeholder: root.mode === "apps" ? "" : root.mode
            focus: true

            onAccepted: root.choose()

            Keys.onEscapePressed: root.hide()
            Keys.onDownPressed: root.move(1)
            Keys.onUpPressed: root.move(-1)
            Keys.onTabPressed: root.move(1)
            Keys.onBacktabPressed: root.move(-1)
            Keys.onPressed: event => {
                if (!(event.modifiers & Qt.ControlModifier))
                    return;
                event.accepted = true;
                switch (event.key) {
                case Qt.Key_N:
                case Qt.Key_J:
                    root.move(1);
                    break;
                case Qt.Key_P:
                case Qt.Key_K:
                    root.move(-1);
                    break;
                case Qt.Key_C:
                case Qt.Key_G:
                    root.hide();
                    break;
                case Qt.Key_U:
                    input.text = "";
                    break;
                default:
                    event.accepted = false;
                }
            }
        }

        Rule {
            width: parent.width
            visible: root.results.length > 0
        }

        Repeater {
            model: ScriptModel {
                values: root.results
            }

            ResultRow {
                id: row
                required property var modelData
                required property int index

                entry: modelData
                glyph: root.modes[root.mode].glyph
                current: index === root.selected
                label: root.armed === modelData ? "enter again to " + modelData.name.toLowerCase() : ""
                onCurrentChanged: if (current) selection.row = row
                Component.onCompleted: if (current) selection.row = row
                width: column.width
                height: Theme.cellHeight
                onEntered: root.selected = index
                onClicked: {
                    root.selected = index;
                    root.choose();
                }
            }
        }

        Label {
            readonly property string message: root.query.length > 0 ? "no matches" : root.modes[root.mode].empty
            visible: root.results.length === 0 && message.length > 0
            height: Theme.cellHeight
            verticalAlignment: Text.AlignVCenter
            text: "  " + message
            color: Theme.muted
        }
    }
}
