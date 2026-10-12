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
// Each channel carries its OWN hue. That is legitimate and not accent sprawl:
// these are three distinct categories, not three peers of one kind, and every
// one already has a redundant cue in its glyph — colour is never the only
// signal. Emphasis between them is carried by LIGHTNESS of the same hue rather
// than by opacity, which reads as disabled.
QsmShellComponents.Slider {
    id: root

    required property string icon
    // The channel's identity colour, from the palette — never invented here.
    required property color hue
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

    // Inset: darker than the band it is cut into. "Lighter than the background
    // = raised; darker = inset".
    trackColor: Qt.darker(Theme.bandFill, 1.6)

    // The hue is IDENTITY, not emphasis, so it does not change with which
    // channel is live: darkening it to de-emphasise pushed the amber
    // brightness track to olive, and a chrome colour at low lightness
    // collapses to muddy grey unless its saturation is raised to compensate.
    // Emphasis is the thumb's job.
    fill: root.muted ? Qt.darker(root.hue, 2.2) : Qt.darker(root.hue, 1.15)

    // ALWAYS the lightest thing on the surface when live — that is what makes
    // it read as raised out of the track rather than as a hole cut into it. A
    // thumb 12% lighter than its own fill merged into it; a thumb darker than
    // the fill inverted the depth entirely.
    thumbColor: root.muted ? Theme.textMuted
        : root.emphasized ? Theme.text
        : Qt.darker(Theme.text, 1.4)

    // The reading rides the thumb.
    // No percent sign: the glyph below says which channel this is, and the
    // sign costs a third of a 32px circle to say what the shape already says.
    thumbText: root.muted ? "—" : `${Math.round(root.value * 100)}`
    thumbContentColor: Theme.bandFill

    // The glyph under the track: a button where muting means something, a
    // plain label where it does not.
    labelIcon: root.icon
    labelPosition: "below"
    labelClickable: root.mutable
    onLabelClicked: root.iconClicked()
}
