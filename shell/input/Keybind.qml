import Quickshell.Hyprland

// One shell-owned global keybind. Hyprland binds it BY NAME —
// `bind = SUPER, SPACE, global, qsm:launcher` — so the compositor config says
// WHICH key and the shell says WHAT it does. Rebinding never touches QML, and
// adding an action never touches the compositor config.
//
// WHY not `exec, qs ipc --path ... call qsm toggle launcher`: that spawns a
// process per press (measured ~68ms on this machine, before the shell even
// hears about it), and it writes a second, undocumented route to every feature
// into the compositor config — the exact duplication the 09 one-path law
// forbids. This is a direct compositor→shell message with no process in it.
//
// `hyprctl globalshortcuts` lists every one of these live, with its
// description, which makes the shell's keyboard surface self-documenting.
GlobalShortcut {
    appid: "qsm"
}
