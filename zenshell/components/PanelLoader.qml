import QtQuick

// One island overlay, instantiated only while it can actually be seen.
//
// `panelState` is the displayState that owns the panel (3 launcher, 4
// wallpapers, 13 control centre, …). The overlay is created the first time
// that state is entered and destroyed once its exit animation has finished,
// so delegates, decoded textures, Process handles and Timers do not sit
// resident for the whole session.
//
// `panelActive` lets a panel share a displayState with another one (the
// compact and expanded now-playing surfaces both live in state 1).
//
// The exit is timed rather than read back from `item.opacity`: sampling the
// item from inside the `active` binding makes `active` depend on the object it
// creates, which QML reports as a binding loop.
Loader {
    id: panelLoader

    // The overlays fill their parent (`anchors.fill: parent` + margins), so
    // the loader has to take the pill's geometry — a bare Loader is a 0×0
    // Item and would give every panel a negative size.
    anchors.fill: parent

    property int panelState: -1
    property bool panelActive: true

    // Wanted right now: this panel owns the current displayState.
    readonly property bool wanted: panelActive && root.displayState === panelState

    // Still on screen after `wanted` went false, fading out.
    property bool holding: false

    active: wanted || holding

    // Every overlay drives `reveal` from displayState and fades out on
    // motionExit (the notification pill uses dFast); keep the object alive
    // until the slowest of those fades is done.
    readonly property int holdMs: Math.max(root.motionExit, root.dFast) + 80

    onWantedChanged: {
        if (wanted) {
            holdTimer.stop();
            holding = false;
        } else if (active) {
            holding = true;
            holdTimer.restart();
        }
    }

    Timer {
        id: holdTimer
        interval: panelLoader.holdMs
        onTriggered: panelLoader.holding = false
    }

    asynchronous: false

    // Every overlay holds `entered` false until the frame after creation: a
    // `reveal` binding that is already true at creation snaps to its final
    // value without animating, so the fade-in would be lost.
    onLoaded: Qt.callLater(function() {
        if (item && item.entered !== undefined)
            item.entered = true;
    })

    onActiveChanged: {
        // The item was just destroyed. Hand the pages back now rather than
        // waiting for the engine's next opportunistic sweep.
        if (!active) gc();
    }
}
