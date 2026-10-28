import Quickshell
import Quickshell.Wayland
import qs
import qs.components

PanelWindow {
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: Theme.background
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "omde-wallpaper"

    WallpaperImage {}
}
