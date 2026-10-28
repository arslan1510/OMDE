pragma Singleton

import Quickshell

Singleton {
    readonly property string plus: "\u{f0415}"
    readonly property string more: "\u{f01d9}"
    readonly property string desktop: "\u{f0379}"
    readonly property string search: "\u{f0349}"
    readonly property string selected: "\u{f0142}"
    readonly property string chip: "\u{f035b}"

    readonly property string lock: "\u{f033e}"
    readonly property string key: "\u{f0306}"
    readonly property string suspend: "\u{f0904}"
    readonly property string logout: "\u{f0343}"
    readonly property string reboot: "\u{f0709}"
    readonly property string power: "\u{f0425}"
    readonly property string awake: "\u{f0176}"
    readonly property string awakeOff: "\u{f06ca}"

    readonly property string back: "\u{f0141}"
    readonly property string submenu: "\u{f0142}"
    readonly property string checked: "\u{f0132}"
    readonly property string unchecked: "\u{f0131}"
    readonly property string radioOn: "\u{f043e}"
    readonly property string radioOff: "\u{f043d}"

    readonly property string bell: "\u{f009c}"
    readonly property string bellUnread: "\u{f0178}"
    readonly property string bellOff: "\u{f009b}"

    readonly property string bluetooth: "\u{f00af}"
    readonly property string bluetoothOff: "\u{f00b2}"
    readonly property string bluetoothConnected: "\u{f00b1}"

    readonly property string ethernet: "\u{f0200}"
    readonly property string networkOff: "\u{f05aa}"
    readonly property string secured: "\u{f0341}"

    readonly property string speaker: "\u{f04c3}"
    readonly property string microphone: "\u{f036c}"

    readonly property string music: "\u{f075a}"
    readonly property string play: "\u{f040a}"
    readonly property string pause: "\u{f03e4}"

    readonly property var profileGlyphs: ({
        PowerSaver: "\u{f032a}",
        Balanced: "\u{f05d1}",
        Performance: "\u{f04c5}"
    })

    readonly property string window: "\u{f10ac}"
    readonly property string clipboard: "\u{f0a38}"
    readonly property string screenshot: "\u{f0e51}"
    readonly property string region: "\u{f0a6d}"
    readonly property string annotate: "\u{f19b9}"

    readonly property string floating: "\u{f05b2}"

    readonly property var layoutGlyphs: ({
        tile: "\u{f0574}",
        scroller: "\u{f056b}",
        grid: "\u{f0570}",
        monocle: "\u{f0763}",
        deck: "\u{f056c}",
        center_tile: "\u{f056d}",
        right_tile: "\u{f06fe}",
        vertical_scroller: "\u{f0729}",
        vertical_tile: "\u{f0bcb}",
        vertical_grid: "\u{f0573}",
        vertical_deck: "\u{f056f}",
        dwindle: "\u{f056e}",
        fair: "\u{f0bcc}",
        vertical_fair: "\u{f056a}"
    })

    function step(levels: var, percent: int): string {
        const i = Math.round(Math.max(0, Math.min(100, percent)) / 100 * (levels.length - 1));
        return levels[i];
    }

    function wifi(percent: int): string {
        return step(["\u{f092e}", "\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"], percent);
    }

    function volume(percent: int, muted: bool): string {
        if (muted)
            return "\u{f075f}";
        return step(["\u{f0581}", "\u{f057f}", "\u{f0580}", "\u{f057e}"], percent);
    }

    function battery(percent: int, charging: bool): string {
        if (charging)
            return step(["\u{f089c}", "\u{f089c}", "\u{f0086}", "\u{f0087}", "\u{f0088}", "\u{f089d}",
                "\u{f0089}", "\u{f089e}", "\u{f008a}", "\u{f008b}", "\u{f0085}"], percent);
        return step(["\u{f008e}", "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}",
            "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"], percent);
    }

    function brightness(percent: int): string {
        return step(["\u{f00dd}", "\u{f00de}", "\u{f00df}", "\u{f00e0}"], percent);
    }
}
