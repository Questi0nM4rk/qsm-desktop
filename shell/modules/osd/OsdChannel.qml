import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// One OSD channel: the library's slider, dressed the way this surface needs.
//
// It used to be `OsdSlider`, and that name is the one the library's own laws
// cite as the mistake — a type named after where it is used, reimplementing a
// slider's orientation, value mapping, fill, thumb, travel, drag, wheel and
// grab margin because the surface wanted three numbers changed. Nothing here
// reimplements anything now; it states colours and fills two slots.
//
// What IS this surface's, and stays: the thumb is the one thing a channel
// draws besides its track (05-osd). It rests as the channel's 16px glyph and
// shows the reading while the channel is live; double-clicking it mutes.
//
// Every channel draws the same way: track `surface`, fill `primary`, content
// `textOnPrimary`. The thumb rests in `textMuted` on every channel, the same
// for all three; only the channel being changed (showingValue) lights up in
// `text`. A muted channel stays `textMuted` even while changed. No shadow under
// the thumb, nothing at the track's end, never a hue.
QsmShellComponents.Slider {
    id: root

    required property string icon
    property bool muted: false
    // Brightness has no mute: its thumb's double-click does nothing.
    property bool mutable: true

    // 05-osd, Sliders: the value stays on the thumb for 1s after the last
    // change, the same budget as the OSD's expiry. No Motion/Theme token has 1s.
    readonly property int valueHoldMs: 1000
    // Pressed, or changed (drag, wheel, keys, service) within valueHoldMs.
    // Not named `live`: Slider already owns a FINAL `live` property.
    readonly property bool showingValue: root.pressed || holdTimer.running

    // The one mute route: the thumb's double-click, Space on the focused
    // thumb, and the workbench story all end here.
    signal muteToggled
    function toggleMute(): bool {
        if (!root.mutable || !root.enabled)
            return false;
        root.muteToggled();
        return true;
    }

    orientation: Qt.Vertical
    size: "lg"
    thickness: Theme.osdTrackWidth
    thumbSize: Theme.osdThumbSize
    thumbIconSize: QsmShellStyle.Style.iconSm
    grabThumb: true
    wheelUnits: Math.round(Theme.osdWheelStep / stepSize)

    trackColor: Theme.surface
    fill: Theme.primary

    // Lit only while this channel is being changed; every other thumb, and a
    // muted channel, stays in `textMuted`.
    thumbColor: root.showingValue && !root.muted ? Theme.text : Theme.textMuted

    // Glyph at rest (the muted variant comes from `icon`), reading while live.
    // No percent sign: the glyph says which channel this is.
    thumbIcon: root.showingValue ? "" : root.icon
    thumbText: root.showingValue ? (root.muted ? "—" : `${Math.round(root.value * 100)}`) : ""
    thumbContentColor: Theme.textOnPrimary

    Timer {
        id: holdTimer
        interval: root.valueHoldMs
    }
    onValueChanged: holdTimer.restart()
    onMutedChanged: holdTimer.restart()
    onPressedChanged: holdTimer.restart()

    // Double-click on the THUMB only (the Slider reports it from its one
    // pointer path). `grabThumb` makes the first press a plain grab, so it
    // moves nothing; a bare-track double-click is two jumps.
    onThumbDoubleClicked: if (root.mutable && root.enabled) root.toggleMute()

    Keys.onSpacePressed: event => {
        if (root.toggleMute())
            event.accepted = true;
    }
}
