import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.state
import qs.theme

// The session backdrop (08): the library's scrim strength over a
// background the compositor genuinely blurs — the ONE sanctioned second
// surface besides the scene window (09), because compositor blur needs its own
// layer surface. Always mapped (transparent + input-transparent when idle) so
// it stays stacked BELOW the later-mapped EdgeScene in the same layer.
PanelWindow {
    id: root

    required property var modelData
    readonly property bool active: ShellState.modal === "session"
        && ShellState.focusedScreen === modelData
        && !root.fullscreen && !FocusModeService.focusFor(modelData)
    readonly property bool fullscreen: FullscreenService.fullscreenFor(modelData)

    screen: modelData
    color: "transparent"
    exclusiveZone: 0
    mask: Region {} // never intercepts input; the scene's catch region closes
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "qsm-session-backdrop-" + modelData.name

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    // Runtime layer rule so the compositor blurs beneath the dim without a
    // config edit; phase 9 integration persists it in the Hyprland config.
    // Lua-parser Hyprland rejects the legacy `keyword layerrule` form
    // outright ("keyword can't work with non-legacy parsers") — the old
    // command failed silently forever (audit U15). eval + hl.layer_rule is
    // the working runtime path, mirroring the owner's hyprland.lua rules.
    // The rule must follow `active`: this surface is ALWAYS mapped (only
    // transparent when idle), and Hyprland blurs behind the surface region
    // regardless of its alpha — a standing blur=true rule blurred the whole
    // desktop permanently (owner-caught the moment it shipped).
    // The rule is a WRITE to the compositor, not a binding, so it needs to
    // CONVERGE. The old `onWantBlurChanged: running = true` dropped any flip
    // that arrived while the previous write was still in flight — assigning
    // running = true on a running Process does nothing — and the compositor
    // kept whatever it had last been told. Open the session menu and close it
    // quickly and the desktop stayed blurred with no way back.
    //
    // So: remember what was actually written (`applied`), write only what we
    // will record (`writing`), and re-check on every exit until the two agree.
    // `applied` starts TRUE while nothing is blurred, which forces one blur=false
    // write at startup — that is also the recovery path for a rule left behind
    // by a crash or a previous build.
    Process {
        id: blurRule

        property bool wantBlur: root.active
        property bool applied: true
        property bool writing: false

        function sync(): void {
            if (running || wantBlur === applied)
                return;
            writing = wantBlur;
            running = true;
        }

        command: Delegate.argv("compositor", ["eval",
            // Retire the old all-output rule before writing this output's rule.
            'hl.layer_rule({ name = "blur-qsm-session", match = { namespace = "qsm-session-backdrop" }, blur = false })\n'
            + "hl.layer_rule({ name = " + JSON.stringify("blur-qsm-session-" + root.modelData.name)
            + ", match = { namespace = " + JSON.stringify("qsm-session-backdrop-" + root.modelData.name)
            + " }, blur = "
            + (writing ? "true" : "false") + " })"])

        onWantBlurChanged: sync()
        onExited: exitCode => {
            // Only a successful write may be believed; a failure retries.
            if (exitCode === 0)
                applied = writing;
            sync();
        }
        Component.onCompleted: sync()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.band
        opacity: root.active && !root.fullscreen ? QsmShellStyle.Style.scrimOpacity : 0

        Behavior on opacity {
            NumberAnimation { duration: Motion.fast; easing.type: Motion.standardEasing }
        }
    }
}
