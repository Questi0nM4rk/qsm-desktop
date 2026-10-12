pragma Singleton

import QtQuick
import Quickshell.Io
import qs.state

// Screen colour picker, delegated to hyprpicker: pick any pixel on any
// monitor, get its value.
//
// The readout is a NOTIFICATION rather than a popout row, and that is
// deliberate. Picking takes over the screen with a zoom lens and moves the
// cursor far away from the rail, so by the time a colour exists the rollout
// that started it has closed. The shell owns org.freedesktop.Notifications, so
// the answer arrives on its own bus — the one surface guaranteed to be
// somewhere the eye already is after an interaction that hijacked the screen.
QtObject {
    id: root

    property bool busy
    // Retained so the action's row can show the last pick as its reading when
    // the rollout is next opened.
    property string lastColor

    // Newest first, deduped, bounded. The cap is what a person can SCAN in a
    // strip -- past that the list stops being a memory aid and becomes an
    // archive, which is a different feature with a different storage answer.
    // The name this service posts its notifications under, and therefore the
    // name the two notification surfaces recognise to draw a colour swatch
    // instead of an app icon. It was written out as a literal in three places
    // — here, the card and the centre — which is three chances for a rename to
    // half-land. The service that CHOOSES the name owns it.
    readonly property string notifyAppName: "Colour picker"

    readonly property int historyLimit: 24
    readonly property var history: ShellState.colorHistory

    // A repeat pick MOVES to the front rather than appearing twice: the same
    // colour twice in a history is one fact, and a duplicate would push a
    // colour you have not seen off the end.
    function remember(value: string): void {
        const next = [value].concat(
            (ShellState.colorHistory ?? []).filter(entry => entry !== value));
        ShellState.colorHistory = next.slice(0, root.historyLimit);
    }

    function forget(value: string): void {
        ShellState.colorHistory = (ShellState.colorHistory ?? [])
            .filter(entry => entry !== value);
    }

    // The last value put on the clipboard, cleared after a beat. Lives here
    // rather than in a surface because TWO surfaces copy colours (the level-2
    // card and the level-3 workspace) and "what was just copied" must have one
    // answer, not one per card.
    property string copied: ""

    function copy(value: string): void {
        if (value.length === 0)
            return;

        root.copied = value;
        // wl-copy is named inline, like the shell's other clipboard pipelines:
        // the Delegate seam covers argv tools a service PARSES output from, and
        // this is a fire-and-forget write.
        copyProcess.command = ["wl-copy", value];
        copyProcess.running = true;
        copiedSettle.restart();
    }

    property Process copyProcess: Process {}

    property Timer copiedSettle: Timer {
        interval: 1600
        onTriggered: root.copied = ""
    }

    function pick(): void {
        if (busy)
            return;

        busy = true;
        pickProcess.running = true;
    }

    property Process pickProcess: Process {
        // NO -a. hyprpicker's autocopy writes the clipboard behind our back, so
        // the shell never learned what was copied and no surface could
        // acknowledge it -- the swatch ticks all read `copied`, which stayed
        // empty after a pick. Copying through our own copy() gives that one
        // owner, and it removes any dependence on whether autocopy also feeds
        // stdout (which is the value everything else here is parsed from).
        //
        // -r is NOT optional on this machine. hyprpicker does not freeze
        // INACTIVE displays without it, so picking on the monitor that is not
        // focused returns nothing and exits 0 — indistinguishable from a
        // cancel. That is exactly what the owner hit: "I picked a color on the
        // second monitor" and the display never updated. This shell is
        // two-monitor by default, so rendering inactive outputs is the normal
        // case, not a flag for an edge case.
        //
        // NO -q, and this was the bug the owner reported for days. hyprpicker
        // prints the picked colour through the same logging path its chatter
        // uses, so --quiet ("Disable most logs") eats the ANSWER. Measured on
        // v0.4.7 with a driven click, one variable at a time:
        //
        //   -r -f hex -l -q  -> exit 0, stdout EMPTY
        //   -r -f hex -l     -> exit 0, stdout "#1e1e2e\n"
        //
        // Every pick therefore landed in the empty-stdout branch below and was
        // read as a cancel, which is why `lastColor` was never set once, the
        // history stayed empty, and the accent squares and editor row -- both
        // gated on having a colour -- were never drawn. One flag, three
        // symptoms. Without -q stdout is exactly the hex and nothing else (od
        // -c confirms: no ANSI, no prefix), so there was never any chatter to
        // keep out; -b is not needed either.
        //
        // -f hex + -l give the form anyone pastes into code.
        command: ["hyprpicker", "-r", "-f", "hex", "-l"]

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                // Cancelling the picker (Escape) exits cleanly with no output.
                // That is a user decision, not a failure, so it must not
                // overwrite the last real pick or announce anything.
                //
                // But it must not be SILENT either. This branch swallowed a
                // real defect for as long as it existed: with hyprpicker unable
                // to render the inactive monitor, every pick over there landed
                // here and looked to the owner like a dead button, with nothing
                // in the log to say otherwise. A path that cannot be told apart
                // from a bug has to announce itself.
                if (value.length === 0) {
                    console.info("ColorPickService: pick returned nothing"
                        + " (cancelled, or hyprpicker could not read that output)");
                    return;
                }

                root.lastColor = value;
                root.remember(value);
                root.copy(value);
                root.notifyProcess.command = ["notify-send", `--app-name=${root.notifyAppName}`,
                    "--icon=color-select", value, "Copied to the clipboard"];
                root.notifyProcess.running = true;
            }
        }

        // stderr is KEPT, not swallowed: if hyprpicker cannot start -- no
        // compositor grab, missing wl-clipboard -- an empty stdout is
        // indistinguishable from a cancel, and this is the only thing that can
        // tell them apart.
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.warn("ColorPickService: hyprpicker:", text.trim());
            }
        }

        onExited: exitCode => {
            root.busy = false;
            if (exitCode !== 0)
                console.warn("ColorPickService: hyprpicker exited", exitCode);
        }
    }

    // --- editing --------------------------------------------------------------
    //
    // Hand the current colour to a real editor and take back what comes out.
    // The shell does not build one: 03 says anything needing real UI belongs in
    // a delegated app, and a colour editor is squarely that.
    //
    // oklch-color-picker's contract, read from its source rather than guessed:
    // `[COLOR]` positional pre-selects, `-f hex` fixes the output format, and
    // Done prints the value while Quit prints NOTHING. So empty stdout means
    // cancelled — the same signal hyprpicker gives, handled the same way, and
    // for the same reason: a cancel is a decision, not a failure, and must not
    // overwrite what was there.
    property bool editing: false
    // Until a run says otherwise. 127 is the shell's "command not found".
    property bool editorAvailable: true

    function edit(value: string): void {
        if (root.editing || value.length === 0)
            return;

        root.editing = true;
        editProcess.command = Delegate.argv("colorEditor", ["-f", "hex", value]);
        editProcess.running = true;
    }

    property Process editProcess: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                if (value.length === 0)
                    return;

                // An edited colour IS a pick: it goes to the top, joins the
                // history and lands on the clipboard, exactly as a screen pick
                // does. Anything less would make the editor a dead end.
                root.lastColor = value;
                root.remember(value);
                root.copy(value);
            }
        }

        onExited: exitCode => {
            root.editing = false;
            root.editorAvailable = exitCode !== 127;
        }
    }

    property Process notifyProcess: Process {}
}
