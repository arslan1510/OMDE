import Quickshell.Services.Mpris
import qs
import qs.components
import qs.services

Segment {
    readonly property MprisPlayer player: Media.player

    text: player?.isPlaying ? Icons.music : Icons.pause
    textColor: player?.isPlaying ? Theme.accent : Theme.muted
    tooltip: player ? [
        { text: Format.truncate(Format.oneLine(player.trackTitle || player.identity), 60) },
        { text: Format.truncate(Format.oneLine(player.trackArtist), 60), muted: true },
        { text: player.trackTitle ? player.identity : "", muted: true }
    ] : []
    interactive: true
    rightClickable: true
    onClicked: Media.playPause()
    onRightClicked: Media.next()
}
