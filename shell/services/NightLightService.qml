pragma Singleton

import QtQuick
import Quickshell.Io
import qs.services
import qs.state

// Night light, delegated to hyprsunset (09 delegation law: the shell is UI,
// the tool does the work).
//
// hyprsunset 0.4.0 is a FOREGROUND daemon, not a one-shot: `hyprsunset -t X`
// runs until killed and restores the identity colour transform on exit. Its
// hyprctl socket only exists while it runs, so there is nothing to query when
// it is off — which makes "is the process alive" both the simplest and the
// only honest definition of this toggle's state. Same shape as AwakeService:
// an external owns the effect, we own the reading.
//
// The WARMTH, though, goes over that socket: `hyprctl hyprsunset temperature
// <K>` answers "ok" on a running daemon (probed). Changing the
// warmth therefore does NOT replace the process.
//
// It used to, and that cost the owner a real bug within an hour of the slider
// shipping: each apply ran `pkill; setsid hyprsunset &`, and the `&` means the
// bash wrapper exits IMMEDIATELY, so the pgrep that reconciles `active` raced
// the new daemon and usually lost — the toggle read false on alternate applies
// and the cell flipped off/on as he scrolled. A restart per notch also dropped
// the colour transform for a frame each time.
QtObject {
    id: root

    // The warmth SCALE, in the tool's own unit. 6000K is hyprsunset's own
    // default and reads as no warming at all, so it is strength 0; 2500K is
    // about candlelight and is as far as this is worth going (below it the
    // screen stops being usable for colour work rather than becoming warmer).
    readonly property int neutralTemperature: 6000
    readonly property int warmestTemperature: 2500

    // Owned by the state file: warmth is a SETTING, and a setting that resets
    // every login is a setting the user has to make every login. A read-only
    // VIEW over it, the same shape Theme uses — an alias cannot reach into a
    // singleton, and a service that both reads and writes the same property
    // has no single owner for it. Writers go through setStrength().
    readonly property int temperature: ShellState.nightLightTemperature

    // 0 = neutral, 1 = warmest. The control the owner actually turns is
    // "how warm", and warmth goes UP as Kelvin goes DOWN — exposing Kelvin as
    // the slider would put a control on screen whose right-hand end means less
    // of the thing it is named after.
    readonly property real strength: Math.max(0, Math.min(1,
        (root.neutralTemperature - root.temperature)
            / (root.neutralTemperature - root.warmestTemperature)))

    property bool active

    function refresh(): void {
        if (!statusProcess.running)
            statusProcess.running = true;
    }

    function toggle(): void {
        setActive(!active);
    }

    function setActive(on: bool): void {
        // Optimistic, then reconciled by refresh() when the helper exits: the
        // toggle has to answer the click now, and a new process takes a moment
        // to show up in the table.
        active = on;
        if (on)
            startProcess.running = true;
        else
            stopProcess.running = true;
    }

    // Dragging the warmth up is an instruction to warm the screen, so it turns
    // night light ON rather than quietly storing a number for later — an input
    // that changes nothing visible is not an answer (09: every input gets a
    // visible response).
    //
    // The pairing is the sound cell's, deliberately: click = on/off, level =
    // how much, and level 0 is quiet-but-unmuted rather than off. Two controls
    // doing two jobs on one feature, not two routes to one thing.
    function setStrength(value: real): void {
        const clamped = Math.max(0, Math.min(1, value));
        ShellState.nightLightTemperature = Math.round(root.neutralTemperature
            - clamped * (root.neutralTemperature - root.warmestTemperature));

        if (root.active)
            applyTimer.restart();   // live over the socket, no restart
        else
            root.setActive(true);   // starts AT the new warmth
    }

    // Debounced only to spare a hyprctl call per scroll notch — the readouts
    // bind `temperature` directly, so the NUMBER moves with the finger either
    // way.
    property Timer applyTimer: Timer {
        interval: 120
        onTriggered: {
            if (root.active)
                root.tempProcess.running = true;
        }
    }

    property Process tempProcess: Process {
        command: Delegate.argv("compositor",
            ["hyprsunset", "temperature", String(root.temperature)])
    }

    property Process statusProcess: Process {
        command: ["pgrep", "-x", "hyprsunset"]
        running: true

        stdout: StdioCollector {
            // NEVER while a start is settling. This is the read that used to
            // lose the race and report the daemon dead a moment after we asked
            // for it.
            onStreamFinished: {
                if (!root.settling)
                    root.active = text.trim().length > 0;
            }
        }
    }

    // True while a start or stop is settling. A process table read immediately
    // after either command can still observe the old state, so reconciliation
    // waits until it can answer about the state the user just requested.
    property bool settling: false

    property Timer settleTimer: Timer {
        interval: 400
        onTriggered: {
            root.settling = false;
            // A real check now: a missing binary corrects the optimistic `true`
            // here instead of 30s later.
            root.refresh();
        }
    }

    // START and STOP are two processes, not one reused.
    //
    // hyprsunset runs in the FOREGROUND for as long as the effect lasts, so a
    // single Process object holding it is occupied for the whole time the
    // toggle is on — reassigning its command to `pkill` did nothing and the
    // toggle would not switch back off. Learned the hard way.
    //
    // `setsid … &` also DETACHES it: night light is system state, not a shell
    // child. Restarting the shell (which happens constantly during
    // development) must not silently undo a setting the user made.
    //
    // The leading pkill is belt-and-braces against a stray daemon from an
    // earlier session, NOT how warmth is applied any more (see the header).
    // This runs on a toggle only.
    property Process startProcess: Process {
        command: ["bash", "-c",
            `pkill -x hyprsunset; setsid hyprsunset -t ${root.temperature} >/dev/null 2>&1 &`]
        // NOT refresh(): the `&` means this exits before the daemon exists, so
        // reconciling here IS the race in the header. Settle first.
        onExited: {
            root.settling = true;
            root.settleTimer.restart();
        }
    }

    property Process stopProcess: Process {
        command: ["pkill", "-x", "hyprsunset"]
        onExited: {
            root.settling = true;
            root.settleTimer.restart();
        }
    }

    // Safety net for changes made outside the shell — a terminal `pkill`, or
    // hyprsunset dying with the session's colour transform reset.
    property Timer poll: Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
