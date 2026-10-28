pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    readonly property JsonObject colors: adapter.colors
    readonly property JsonObject font: adapter.font
    readonly property int borderWidth: adapter.borderWidth
    readonly property JsonObject motion: adapter.motion

    function reload(): void {
        file.reload();
    }

    FileView {
        id: file
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omde/palette.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            property JsonObject colors: JsonObject {
                property color background
                property color foreground
                property color muted
                property color accent
                property color warning
                property color critical
            }
            property JsonObject font: JsonObject {
                property string family
                property real size
            }
            property int borderWidth
            property JsonObject motion: JsonObject {
                property JsonObject enter: JsonObject {
                    property int duration
                    property list<real> curve
                }
                property JsonObject exit: JsonObject {
                    property int duration
                    property list<real> curve
                }
                property JsonObject move: JsonObject {
                    property int duration
                    property list<real> curve
                }
                property JsonObject effect: JsonObject {
                    property int duration
                    property list<real> curve
                }
            }
        }
    }
}
