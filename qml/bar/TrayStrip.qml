pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs
import qs.components

Flickable {
    id: root

    property Item menuOwner: null

    signal done()

    implicitWidth: row.implicitWidth + Theme.inset
    implicitHeight: Theme.cellHeight
    width: Math.min(implicitWidth, Theme.barMaxWidth - Theme.inset * 2)
    height: implicitHeight
    contentWidth: implicitWidth
    contentHeight: height
    flickableDirection: Flickable.HorizontalFlick
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    WheelHandler {
        target: null
        onWheel: event => {
            const delta = event.pixelDelta.y || event.pixelDelta.x
                || (event.angleDelta.y || event.angleDelta.x) / 120 * Theme.iconSize * 2;
            root.contentX = Math.max(0, Math.min(root.contentWidth - root.width, root.contentX - delta));
        }
    }

    Row {
        id: row
        height: root.height
        spacing: Theme.gutter

        Repeater {
            model: SystemTray.items

            MouseArea {
                id: cell
                required property SystemTrayItem modelData
                width: Theme.iconSize + Theme.cellPadding * 2
                height: row.height
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                function triggerOpenAction(): bool {
                    const openEntry = menuOpener.children.values.find(entry => {
                        const text = entry.text.trim().toLowerCase();
                        return entry.enabled && !entry.isSeparator
                            && /^(open|show|restore)\b/.test(text);
                    });
                    if (!openEntry)
                        return false;
                    openEntry.triggered();
                    return true;
                }

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                        Popouts.toggle(root.menuOwner || cell, menu);
                        return;
                    }
                    if (mouse.button === Qt.MiddleButton) {
                        if (modelData.onlyMenu && modelData.hasMenu)
                            Popouts.toggle(root.menuOwner || cell, menu);
                        else
                            modelData.secondaryActivate();
                        root.done();
                        return;
                    }
                    if (cell.triggerOpenAction()) {
                        root.done();
                        return;
                    }
                    if (modelData.onlyMenu && modelData.hasMenu) {
                        Popouts.toggle(root.menuOwner || cell, menu);
                        return;
                    }
                    modelData.activate();
                    root.done();
                }

                QsMenuOpener {
                    id: menuOpener
                    menu: cell.modelData.hasMenu ? cell.modelData.menu : null
                }

                HoverFill {
                    active: cell.containsMouse
                    pressed: cell.pressed
                }

                Icon {
                    anchors.centerIn: parent
                    source: cell.modelData.icon
                }

                Component {
                    id: menu

                    TrayMenu {
                        menu: cell.modelData.menu
                        onDone: root.done()
                    }
                }
            }
        }
    }
}
