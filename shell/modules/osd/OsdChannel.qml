import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.theme

// One OSD channel: the library's slider, dressed the way this surface needs.
//
// It used to be `OsdSlider`, and that name is the one the library's own laws
// cite as the mistake — a type named after where it is used, reimplementing a
// slider's orientation, value mapping, fill, thumb, travel, drag, wheel and
// grab margin because the surface wanted three numbers changed. Nothing here
// reimplements anything now; it states colours and fills two slots.
//
// What IS this surface's, and stays:
//
// The thumb is the focal element and the only bright thing on the surface. The
// track reads INSET (darker than the band it is cut into) and the thumb reads
// RAISED (lighter than everything, with a short hard drop under it) — the
// no-shadow depth cues, which is all a shader-only shell has. The number lives
// inside the thumb, so the value is wherever the eye already is: on the thing
// that moved.
//
// Every channel draws the same way (05-osd): track `surface`, fill `primary`,
// thumb `text` while live and `textMuted` otherwise, content `textOnPrimary`.
// Identity is the glyph in the thumb, never a hue.
QsmShellComponents.Slider {
    id: root

    required property string icon
    property bool muted: false
    // Brightness has no mute: its glyph is a LABEL, not a button, and dressing
    // a label as a control that does nothing is worse than leaving it plain.
    property bool mutable: true
    property bool emphasized: false

    signal iconClicked

    orientation: Qt.Vertical
    size: "lg"
    thickness: Theme.osdTrackWidth
    thumbSize: Theme.osdThumbSize
    raised: true
    wheelUnits: Math.round(Theme.osdWheelStep / stepSize)

    trackColor: Theme.surface
    fill: Theme.primary

    // Emphasis is the thumb's job: `text` while this channel is live, one step
    // down in `textMuted` for the others and for a muted channel.
    thumbColor: !root.muted && root.emphasized ? Theme.text : Theme.textMuted

    // The reading rides the thumb.
    // No percent sign: the glyph below says which channel this is, and the
    // sign costs a third of a 32px circle to say what the shape already says.
    thumbText: root.muted ? "—" : `${Math.round(root.value * 100)}`
    thumbContentColor: Theme.textOnPrimary

    // The glyph under the track: a button where muting means something, a
    // plain label where it does not.
    labelIcon: root.icon
    labelPosition: "below"
    labelClickable: root.mutable
    onLabelClicked: root.iconClicked()
}
