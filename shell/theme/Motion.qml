pragma Singleton

import QtQuick

QtObject {
    // Micro-interaction tiers, used across every conformed surface.
    // A press has to land under the finger, not after it — anything on the
    // micro tier reads as the button lagging the click (09: every input gets a
    // visible response). Release returns on `micro`, so a control settles back
    // instead of snapping.
    readonly property int press: Theme.reducedMotion ? 40 : 80
    readonly property int micro: Theme.reducedMotion ? 60 : 130
    readonly property int fast: Theme.reducedMotion ? 80 : 180
    readonly property int normal: Theme.reducedMotion ? 100 : 260

    // A workspace dot is 6px: the library's 1.08 growth would be under half a
    // pixel, so it grows by half again to be seen at all.
    readonly property real dotHoverScale: 1.5

    readonly property int standardEasing: Easing.OutCubic
    readonly property int emphasizedEasing: Easing.OutQuart

    // 10-motion vocabulary (owner-amended 2026-08-17 twice): NO spring —
    // overshoot made every reveal read as a popup, not a roll. Reveal is a
    // strong decelerate (fast out of the border, soft landing); retract a
    // gentle accelerate-decelerate. Goo, where enabled, supplies any
    // organic feel. Reduced motion shortens each duration (press 40, micro 60,
    // fast 80, normal 100); the reveal and glide durations clamp to 120.
    // Only the SMALL tier has a desktop consumer left (BarPopouts): the
    // large tier and the settle pair (microPopScale/microPopDuration) moved
    // with Rollout to the library's own Motion (qsm-shell, 11c).
    readonly property int revealSmall: Theme.reducedMotion ? 120 : 250
    readonly property var revealCurve: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var retractCurve: [0.3, 0.0, 0.2, 1.0, 1.0, 1.0]
    // Popout entry-to-entry morph glide (10-motion DEFAULT): 250ms, no
    // overshoot.
    readonly property int morphGlide: Theme.reducedMotion ? 120 : 250
}
