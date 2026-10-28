pragma Singleton

import Quickshell

Singleton {
    function oneLine(text: string): string {
        return text.replace(/[\r\n\t]+/g, " ");
    }

    function truncate(text: string, length: int): string {
        return text.length > length ? text.slice(0, length - 1) + "…" : text;
    }

    function headline(notification: var): string {
        return (notification.appName ? notification.appName + ": " : "") + notification.summary;
    }

    function percent(fraction: real): string {
        return Math.round(fraction * 100) + "%";
    }

    function mebibytes(mib: real): string {
        return mib >= 1024 ? (mib / 1024).toFixed(1) + "G" : Math.round(mib) + "M";
    }

    function duration(seconds: real): string {
        return Math.floor(seconds / 3600) + "h "
            + String(Math.floor(seconds % 3600 / 60)).padStart(2, "0") + "m";
    }
}
