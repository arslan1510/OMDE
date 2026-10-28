pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import qs

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNodeAudio audio: sink?.audio ?? null
    readonly property bool muted: audio?.muted ?? false
    readonly property int percent: Math.round(Math.min(1, audio?.volume ?? 0) * 100)

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool micMuted: source?.audio?.muted ?? false

    property PwNode heard: null

    signal levelChanged()

    function hear(): void {
        if (audio && sink === heard)
            levelChanged();
        heard = audio ? sink : null;
    }

    onPercentChanged: hear()
    onMutedChanged: hear()

    readonly property var outputs: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var inputs: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)

    function nameOf(node: PwNode): string {
        return node.description || node.nickname || node.name;
    }

    function use(node: PwNode): void {
        if (node.isSink)
            Pipewire.preferredDefaultAudioSink = node;
        else
            Pipewire.preferredDefaultAudioSource = node;
    }

    function toggleMute(): void {
        audio.muted = !audio.muted;
    }

    function adjust(steps: int): void {
        setPercent(percent + steps * Config.volumeStep);
    }

    function setPercent(value: real): void {
        audio.volume = Math.max(0, Math.min(100, value)) / 100;
    }

    PwObjectTracker {
        objects: [root.sink, root.source].filter(Boolean)
    }
}
