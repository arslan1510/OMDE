import QtQuick
import QtQuick.Layouts
import qs

ColumnLayout {
    id: root

    property Item keyRow: null

    signal back()

    function key(event: var): bool {
        switch (event.key) {
        case Qt.Key_Down:
        case Qt.Key_Tab:
            move(1);
            return true;
        case Qt.Key_Up:
        case Qt.Key_Backtab:
            move(-1);
            return true;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            keyRow?.triggered(false);
            return true;
        case Qt.Key_Delete:
            keyRow?.triggered(true);
            return true;
        case Qt.Key_Left:
            back();
            return true;
        }
        return false;
    }

    function move(delta: int): void {
        const list = rows(root);
        if (list.length === 0)
            return;
        const from = list.indexOf(keyRow ?? list.find(r => r.containsMouse));
        keyRow = list[from < 0 ? (delta > 0 ? 0 : list.length - 1)
            : (from + delta + list.length) % list.length];
    }

    function rows(item: Item): var {
        const found = [];
        for (const child of item.children) {
            if (!child.visible)
                continue;
            if (child instanceof MenuRow) {
                if (child.enabled)
                    found.push(child);
            } else {
                found.push(...rows(child));
            }
        }
        return found;
    }

    width: Math.max(Theme.menuMinWidth, Math.min(Theme.menuMaxWidth, implicitWidth))
    spacing: 0

    HoverHandler {
        onPointChanged: root.keyRow = null
    }
}
