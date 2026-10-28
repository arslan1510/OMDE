import QtQuick
import qs

PropertyAnimation {
    enum Role { Enter, Exit, Move, Effect }

    property int role: Motion.Effect
    readonly property var spec: Theme.motion(["enter", "exit", "move", "effect"][role])

    duration: spec.duration
    easing: spec.easing

    function go(value: real, nextRole: int): void {
        if (running ? to === value : target[property] === value)
            return;
        stop();
        role = nextRole;
        to = value;
        start();
    }
}
