import QtQml

QtObject {
    property real remainder: 0

    function take(delta: real): int {
        remainder += delta;
        const steps = Math.trunc(remainder / 120);
        remainder -= steps * 120;
        return steps;
    }
}
