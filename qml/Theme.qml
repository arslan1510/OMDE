pragma Singleton

import QtQuick
import Quickshell
import qs

Singleton {
    id: root

    readonly property color background: Scheme.colors.background
    readonly property color foreground: Scheme.colors.foreground
    readonly property color muted: Scheme.colors.muted
    readonly property color accent: Scheme.colors.accent
    readonly property color warning: Scheme.colors.warning
    readonly property color critical: Scheme.colors.critical
    readonly property color border: Qt.tint(background, Qt.rgba(muted.r, muted.g, muted.b, 0x55 / 255))
    readonly property color hover: Qt.rgba(muted.r, muted.g, muted.b, 0x22 / 255)
    readonly property color pressed: Qt.rgba(muted.r, muted.g, muted.b, 0x44 / 255)

    readonly property string fontFamily: Scheme.font.family
    readonly property int fontSize: Math.round(Scheme.font.size * 96 / 72 * Config.scale)
    readonly property real charWidth: metrics.advanceWidth
    readonly property int borderWidth: Scheme.borderWidth

    function em(n: real): int {
        return Math.round(n * fontSize);
    }

    function columns(n: real): int {
        return Math.ceil(n * charWidth);
    }

    readonly property int barHeight: em(2.3)
    readonly property int cellHeight: barHeight - borderWidth * 2
    readonly property int iconSize: em(1.25)

    readonly property int inset: em(0.6)
    readonly property int gutter: em(0.45)
    readonly property int cellPadding: em(0.45)
    readonly property int gap: em(0.3)
    readonly property int lineGap: em(0.15)

    readonly property int sliderThickness: em(0.25)
    readonly property int travel: em(0.6)
    readonly property int barMaxWidth: columns(Config.barColumns)
    readonly property int notificationWidth: columns(Config.notificationColumns)
    readonly property int menuMinWidth: columns(20)
    readonly property int menuMaxWidth: columns(46)
    readonly property int popoutMaxHeight: em(49)
    readonly property int toastWindowHeight: em(49)

    readonly property int tooltipDelay: 450
    readonly property int popoutCloseDelay: 150

    property real motionScale: 1

    function motion(role: string): var {
        const spec = Scheme.motion[role];
        return {
            duration: Math.round(spec.duration * motionScale),
            easing: { type: Easing.BezierSpline, bezierCurve: [...spec.curve, 1, 1] }
        };
    }

    function barSideMargin(screen: var): real {
        return Math.max(gutter, (screen.width - barMaxWidth) / 2);
    }

    // Round to the window's device pixels; fractional scales blur borders otherwise.
    function snap(value: real, dpr: real): real {
        return Math.round(value * dpr) / dpr;
    }

    // One border line, at least a whole device pixel.
    function line(dpr: real): real {
        return Math.max(1, Math.round(borderWidth * dpr)) / dpr;
    }

    // mapToItem misses ancestors that move; walking the chain does not.
    function windowPosition(item: Item): point {
        let x = 0;
        let y = 0;
        for (let i = item; i; i = i.parent) {
            x += i.x;
            y += i.y;
        }
        return Qt.point(x, y);
    }

    TextMetrics {
        id: metrics
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        text: "0"
    }
}
