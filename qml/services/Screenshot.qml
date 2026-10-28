pragma Singleton

import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    readonly property var kinds: ({
        region: { notify: true, script: 'g=$(slurp -d) && grim -g "$g" "$1" && wl-copy < "$1"' },
        screen: { notify: true, script: 'grim -o "$2" "$1" && wl-copy < "$1"' },
        annotate: {
            notify: false,
            script: 'g=$(slurp -d) && grim -l 0 -g "$g" - | satty --filename - --output-filename "$1" --copy-command wl-copy --early-exit'
        }
    })
    property string file: ""

    function take(kind: string): void {
        const spec = kinds[kind];
        if (!spec) {
            console.warn("screenshot: unknown kind", kind);
            return;
        }
        const path = Config.screenshotDir + "/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss") + ".png";
        const command = ["sh", "-c", 'mkdir -p "${1%/*}" && ' + spec.script, "sh", path, Mango.focusedName];
        if (!spec.notify) {
            Quickshell.execDetached(command);
            return;
        }
        if (shot.running)
            return;
        file = path;
        shot.exec(command);
    }

    Process {
        id: shot
        onExited: code => {
            if (code === 0)
                Notifs.post("Screenshot copied", root.file, false);
        }
    }
}
