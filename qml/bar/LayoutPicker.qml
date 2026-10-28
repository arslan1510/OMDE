import qs
import qs.components
import qs.services

Segment {
    property var monitor: null
    readonly property var layouts: Mango.layouts
    readonly property int index: layouts.findIndex(l => l.symbol === monitor?.layout)

    function cycle(delta: int): void {
        Mango.setLayout(layouts[(index + delta + layouts.length) % layouts.length].name);
    }

    readonly property bool floating: monitor?.active === true && Mango.focusedFloating

    text: floating ? Icons.floating : (Icons.layoutGlyphs[layouts[index]?.name] ?? "")
    textColor: monitor?.active ? Theme.accent : Theme.muted
    interactive: true
    rightClickable: true
    onClicked: cycle(1)
    onRightClicked: cycle(-1)
}
