import QtQuick
import qs
import qs.components

Segment {
    id: root

    readonly property bool canExtend: Popouts.extensionRoom >= (Theme.iconSize + Theme.cellPadding * 2) * 3

    text: Icons.more
    textColor: Popouts.extensionOwner === root || Popouts.isOpenFor(root) ? Theme.accent : Theme.muted
    interactive: true
    onClicked: canExtend ? Popouts.toggleExtension(root, strip) : Popouts.toggle(root, strip)

    Component {
        id: strip

        TrayStrip {
            menuOwner: Popouts.extended ? null : root
            onDone: Popouts.dismiss()
        }
    }
}
