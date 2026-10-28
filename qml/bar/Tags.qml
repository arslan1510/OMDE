pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.services

Item {
    id: root

    required property string monitorName
    property var monitor: null

    readonly property bool canControl: monitor !== null
    property Item activeSegment: null
    readonly property int activeId: activeSegment?.tagId ?? -1
    readonly property real activeX: activeSegment?.x ?? 0
    readonly property real activeWidth: activeSegment?.width ?? 0
    property int placedId: -1

    readonly property real tagWidth: Theme.columns(3) + Theme.cellPadding * 2
    property int first: 0
    readonly property int lastFirst: Math.max(0, shownIds.length - Config.visibleTags)

    readonly property var tags: monitor?.tags ?? []

    function tagFor(id: int): var {
        return tags.find(entry => entry.id === id) ?? null;
    }

    readonly property var shownIds: TagState.shown(monitorName)
    readonly property int coveredIndex: activeSegment ? Math.floor((block.start + block.end) / 2 / tagWidth) : -1

    function place(): void {
        block.to = activeX;
        block.size = activeWidth;
        if (activeId === placedId)
            block.snap();
        placedId = activeId;
    }

    function scrollTo(index: int): void {
        first = Math.max(0, Math.min(lastFirst, index));
    }

    function reveal(): void {
        const index = shownIds.indexOf(activeId);
        if (index === -1)
            return;
        if (index < first)
            scrollTo(index);
        else if (index >= first + Config.visibleTags)
            scrollTo(index - Config.visibleTags + 1);
    }

    onActiveXChanged: Qt.callLater(place)
    onActiveWidthChanged: Qt.callLater(place)
    onActiveIdChanged: Qt.callLater(reveal)
    onLastFirstChanged: scrollTo(first)

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout
        height: parent.height
        spacing: 0

        Item {
            id: viewport
            Layout.preferredWidth: root.tagWidth * Config.visibleTags
            Layout.fillHeight: true
            clip: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    const delta = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y)
                        ? wheel.angleDelta.x : wheel.angleDelta.y;
                    const steps = notches.take(delta);
                    if (steps !== 0)
                        root.scrollTo(root.first - steps);
                }

                WheelSteps {
                    id: notches
                }
            }

            Item {
                id: strip
                x: -root.first * root.tagWidth
                width: row.implicitWidth
                height: parent.height
                Behavior on x { Motion { role: Motion.Move } }

                Glide {
                    id: block
                }

                Rectangle {
                    readonly property real windowLeft: -strip.x
                    readonly property real windowRight: windowLeft + viewport.width
                    visible: root.activeSegment !== null && width >= 1
                    x: Math.max(block.start, windowLeft)
                    width: Math.min(block.end, windowRight) - x
                    height: row.height
                    color: Theme.accent
                }

                RowLayout {
                    id: row
                    height: parent.height
                    spacing: 0

                    Repeater {
                        model: ScriptModel {
                            values: root.shownIds
                        }

                        Segment {
                            id: segment
                            required property int modelData
                            required property int index
                            readonly property int tagId: modelData
                            readonly property var tag: root.tagFor(tagId)
                            readonly property string marker: tag?.urgent ? "!" : ""
                            readonly property bool dismissable: !tag?.occupied && root.shownIds.length > 1
                            readonly property bool active: tag?.active === true

                            onActiveChanged: {
                                if (active)
                                    root.activeSegment = segment;
                                else if (root.activeSegment === segment)
                                    root.activeSegment = null;
                            }

                            implicitWidth: root.tagWidth
                            text: tagId + marker
                            textColor: index === root.coveredIndex ? Theme.background
                                : tag?.urgent ? Theme.warning
                                : tag?.occupied ? Theme.foreground : Theme.muted
                            Behavior on textColor { Motion {} }
                            interactive: root.canControl
                            rightClickable: dismissable
                            onClicked: Mango.selectTag(root.monitorName, tagId)
                            onRightClicked: TagState.dismiss(root.monitorName, tagId)

                            opacity: 0
                            Component.onCompleted: {
                                opacity = 1;
                                if (active)
                                    root.activeSegment = segment;
                            }
                            Behavior on opacity { Motion { role: Motion.Enter } }
                        }
                    }
                }
            }
        }

        Segment {
            visible: root.shownIds.length < Mango.tagCount
            text: Icons.plus
            textColor: Theme.muted
            interactive: root.canControl
            onClicked: TagState.add(root.monitorName)
        }
    }
}
