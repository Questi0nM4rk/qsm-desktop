pragma Singleton

import QtQuick
import Quickshell

// Every third-party command the shell delegates to, in ONE place.
//
// The delegation law says this shell is UI only: it never rebuilds a mixer, a
// network editor or a power manager, it hands the job to the tool that owns it.
// That makes the tool names an external dependency, and external dependencies
// belong behind a seam — swapping pavucontrol for pwvucontrol, blueman for
// overskride, or systemctl for loginctl should be one edit here, not a hunt
// through the surfaces.
//
// Two kinds of entry:
//   `apps`  — GUI programs a surface OPENS and forgets (fire and forget).
//   `tools` — CLI programs a service RUNS for its output (argv only; the
//             parsing stays with the service that understands the format).
//
// Roles are named for the JOB, never for the binary, so a swap cannot leak
// into call sites: `Delegate.open("mixer")`, not `open("pavucontrol")`.
QtObject {
    id: root

    // ---- GUI applications ---------------------------------------------------
    readonly property var apps: ({
        "mixer": ["pavucontrol"],
        "bluetooth": ["blueman-manager"],
        "network": ["nm-connection-editor"],
        "lock": ["hyprlock"],
        "logout": ["hyprctl", "dispatch", "exit"],
        "hibernate": ["systemctl", "hibernate"],
        "reboot": ["systemctl", "reboot"],
        "shutdown": ["systemctl", "poweroff"],
        // The full system upgrade in a terminal (owner 2026-08-25, HyDE
        // parity): repo + AUR via the owner's helper, holding the terminal
        // open at the end so the result is readable before it closes.
        // Swap the helper here, nowhere else.
        "upgrade": ["foot", "-e", "sh", "-c",
            "yay -Syu; echo; read -n 1 -s -r -p 'Done — press any key'"]
    })

    // ---- CLI tools ----------------------------------------------------------
    // Base argv; callers append their own arguments through `argv()`. This
    // seam covers plain argv Processes only — the bash PIPELINES in the
    // launcher and clipboard surfaces (qalc, cliphist decode | wl-copy,
    // hyprctl dispatch kill) name their binaries inline, so swapping those
    // is a surface edit, not a one-line change here.
    readonly property var tools: ({
        "brightness": ["brightnessctl"],
        "powerProfile": ["powerprofilesctl"],
        "compositor": ["hyprctl"],
        "clipboard": ["cliphist"],
        // Read-only update COUNT (UpdateService): local sync DB vs installed,
        // no network, changes nothing. pacman-contrib.
        "updates": ["checkupdates"],
        // A colour EDITOR, not a picker: it takes a colour, opens a window on
        // it, and prints the edited value back. That output is why it is a tool
        // and not an app — `open()` would throw the answer away.
        "colorEditor": ["oklch-color-picker"]
    })

    // Fire and forget a delegated application. Unknown role = no-op rather
    // than a crash: a missing tool must never take the shell down with it.
    function open(role: string): bool {
        const command = apps[role];
        if (!command) {
            console.warn("Delegate: no application registered for role", role);
            return false;
        }
        Quickshell.execDetached(command);
        return true;
    }

    // argv for a Process `command:` binding — `Delegate.argv("brightness",
    // ["-m"])` yields ["brightnessctl", "-m"].
    function argv(role: string, args: var): var {
        const base = tools[role];
        if (!base) {
            console.warn("Delegate: no tool registered for role", role);
            return [];
        }
        return args && args.length > 0 ? base.concat(args) : base.slice();
    }
}
