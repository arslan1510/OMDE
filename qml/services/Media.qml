pragma Singleton

import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property MprisPlayer last: null
    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: players.find(p => p.isPlaying)
        ?? (players.includes(last) ? last : players[0]) ?? null

    onPlayerChanged: if (player) last = player

    function playPause(): void {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }

    function next(): void {
        if (player?.canGoNext)
            player.next();
    }

    function previous(): void {
        if (player?.canGoPrevious)
            player.previous();
    }
}
