import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.services

Segment {
    readonly property Toplevel window: ToplevelManager.activeToplevel
    readonly property string appId: window?.appId ?? ""
    readonly property DesktopEntry entry: Apps.forAppId(appId)
    readonly property string title: window ? Format.oneLine(window.title) : "desktop"

    iconSource: Apps.iconFor(entry)
    text: appId ? "" : Icons.desktop
    tooltip: [{ text: Format.truncate(title, 60) }]
}
