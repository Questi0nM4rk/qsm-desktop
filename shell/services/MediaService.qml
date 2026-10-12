pragma Singleton

import QtQuick
import Quickshell.Services.Mpris

// MPRIS player selection (06 DEFAULT): the active player is the user's
// explicit pick while it lives, else playing > paused > first seen. Both
// the Media tab and the dashboard mini-player read `active`. This is the
// single owner of active-player state: position is smoothed locally (MPRIS
// only pushes position on seeks/track changes) and shuffle/loop are guarded
// by their support flags, so consumers stay pure views over these properties.
QtObject {
    id: root

    readonly property var players: Mpris.players.values
    property var selected: null

    readonly property var active: {
        if (selected && players.includes(selected))
            return selected;

        const playing = players.find(player => player.playbackState === MprisPlaybackState.Playing);
        if (playing)
            return playing;

        const paused = players.find(player => player.playbackState === MprisPlaybackState.Paused);
        return paused ?? (players.length > 0 ? players[0] : null);
    }

    // Transport ------------------------------------------------------------
    //
    // The media keys' route in. It lands here rather than on playerctl in the
    // compositor config because THIS is where "which player is active" is
    // decided (playing > paused > first seen) — playerctl held a second, blind
    // opinion about that and would drive a different player than every surface
    // in the shell was showing.
    //
    // These need no readout surface of their own: unlike a volume or
    // brightness level, the result of play/pause/next is immediately audible,
    // so the audio IS the response (09's visible-response law, satisfied by
    // the medium the control actually acts on).

    readonly property bool canTogglePlaying: active?.canTogglePlaying ?? false
    readonly property bool canGoNext: active?.canGoNext ?? false
    readonly property bool canGoPrevious: active?.canGoPrevious ?? false

    function togglePlaying(): void {
        if (active && canTogglePlaying)
            active.togglePlaying();
    }

    function next(): void {
        if (active && canGoNext)
            active.next();
    }

    function previous(): void {
        if (active && canGoPrevious)
            active.previous();
    }

    // Seek + position ------------------------------------------------------

    readonly property bool canSeek: active?.canSeek ?? false
    readonly property bool lengthSupported: active?.lengthSupported ?? false
    readonly property real length: active?.length ?? 0
    readonly property bool isPlaying: active?.isPlaying ?? false

    // MPRIS only pushes `position` on seeks/track changes; between pushes
    // this timer advances it locally so a seek slider moves without polling.
    readonly property real mprisPosition: active?.position ?? 0
    property real position: 0
    property real tickAnchor: 0
    property double tickWallClock: 0

    function resyncPosition(): void {
        position = mprisPosition;
        tickAnchor = mprisPosition;
        tickWallClock = Date.now();
    }

    Component.onCompleted: resyncPosition()
    onActiveChanged: resyncPosition()
    onMprisPositionChanged: resyncPosition()
    onIsPlayingChanged: resyncPosition()

    property Timer positionTimer: Timer {
        interval: 250
        repeat: true
        running: root.isPlaying && root.lengthSupported
        onTriggered: {
            const elapsed = (Date.now() - root.tickWallClock) / 1000;
            root.position = Math.min(root.length, root.tickAnchor + elapsed);
        }
    }

    // Seeks the active player to a 0..1 fraction of its length. No-op when
    // the player can't seek or doesn't report a usable length.
    function seek(fraction: real): void {
        if (!active || !canSeek || !lengthSupported || length <= 0)
            return;

        active.position = length * Math.max(0, Math.min(1, fraction));
        resyncPosition();
    }

    // mm:ss (or NN:ss past an hour, still fixed-width for typical tracks) —
    // ponytail ceiling: multi-hour tracks widen past the caller's fixed-width
    // template, which is an accepted trade-off for this simple readout.
    function formatTime(totalSeconds: real): string {
        const clamped = Math.max(0, Math.floor(totalSeconds));
        const minutes = Math.floor(clamped / 60);
        const seconds = clamped % 60;
        return `${minutes}:${seconds < 10 ? "0" : ""}${seconds}`;
    }

    // Shuffle ----------------------------------------------------------

    readonly property bool shuffleSupported: active?.shuffleSupported ?? false
    readonly property bool shuffle: active?.shuffle ?? false

    function toggleShuffle(): void {
        if (active && shuffleSupported)
            active.shuffle = !active.shuffle;
    }

    // Loop (repeat) ------------------------------------------------------

    readonly property bool loopSupported: active?.loopSupported ?? false
    readonly property int loopState: active?.loopState ?? MprisLoopState.None

    // Cycle order (06 caelestia-parity ruling): none -> playlist -> track -> none.
    function cycleLoop(): void {
        if (!active || !loopSupported)
            return;

        active.loopState = loopState === MprisLoopState.None ? MprisLoopState.Playlist
            : loopState === MprisLoopState.Playlist ? MprisLoopState.Track
            : MprisLoopState.None;
    }
}
