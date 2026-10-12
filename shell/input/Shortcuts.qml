import Quickshell
import qs.services
import qs.state

// EVERY keyboard route into the shell, in ONE table (09 keybinds + the
// one-path law). Nothing else in the shell registers a global bind, and the
// compositor config holds no shell logic — only key→name mappings, which
// `docs/hyprland-binds.conf` and the Lua snippet beside it mirror.
//
// Level controls (volume, brightness) are routed THROUGH the shell rather
// than through wpctl/brightnessctl in the compositor config, for one reason:
// the OSD has to know. brightnessctl writing sysfs behind the shell's back is
// invisible to it — which is exactly why the brightness keys used to change
// the screen with no OSD at all. Owning the write means the readout, the
// slider and the rollout all follow from the same event.
// A Scope, not an Item: these bind keys, they draw nothing.
Scope {
    id: root

    // One step per press, shared by the keys and the OSD's own wheel nudge so
    // both move the control by the same amount (05: osdWheelStep).
    readonly property real levelStep: 0.05

    Keybind {
        name: "launcher"
        description: "App picker"
        onPressed: ShellState.toggleModal("launcher")
    }

    Keybind {
        name: "quickControls"
        description: "Quick controls"
        onPressed: ShellState.toggleLauncher(">action ")
    }

    Keybind {
        name: "clipboard"
        description: "Clipboard history"
        // Its OWN surface since 2026-08-20, not a launcher preset. `>clip` is
        // gone rather than kept beside it: two routes to one feature is what
        // 09 removes.
        onPressed: ShellState.toggleModal("clipboard")
    }

    Keybind {
        name: "cheatsheet"
        description: "Keybind cheat sheet"
        // Load-bearing discoverability (decision-table row 9): the clipboard
        // rollout is keyboard-only, so the binds themselves need one place
        // they can all be seen.
        onPressed: ShellState.toggleModal("cheatsheet")
    }

    Keybind {
        name: "workspaces"
        description: "Workspaces overview"
        onPressed: ShellState.togglePanel("workspaces")
    }

    Keybind {
        name: "dashboard"
        description: "Top panel, last used tab"
        onPressed: ShellState.togglePanel("")
    }

    Keybind {
        name: "session"
        description: "Session / power"
        onPressed: ShellState.toggleModal("session")
    }

    Keybind {
        name: "lock"
        description: "Lock the session"
        // Through the same seam the session surface's Lock button uses.
        onPressed: Delegate.open("lock")
    }

    Keybind {
        name: "rail"
        description: "Pin / unpin the rail on the focused monitor"
        onPressed: ShellState.toggleRail(ShellState.focusedScreen?.name ?? "")
    }

    Keybind {
        name: "fullscreen"
        description: "Toggle native fullscreen on this workspace"
        onPressed: FullscreenService.toggle()
    }

    // Already-loaded compositor configs may still name the previous action.
    Keybind {
        name: "focusMode"
        description: "Toggle native fullscreen on this workspace"
        onPressed: FullscreenService.toggle()
    }

    Keybind {
        name: "volumeUp"
        description: "Output volume up"
        onPressed: AudioService.setOutput(AudioService.outputValue + root.levelStep)
    }

    Keybind {
        name: "volumeDown"
        description: "Output volume down"
        onPressed: AudioService.setOutput(AudioService.outputValue - root.levelStep)
    }

    Keybind {
        name: "volumeMute"
        description: "Mute / unmute output"
        onPressed: AudioService.toggleOutputMuted()
    }

    Keybind {
        name: "micMute"
        description: "Mute / unmute microphone"
        onPressed: AudioService.toggleMicrophoneMuted()
    }

    // Media keys come here rather than to playerctl in the compositor config
    // because the shell already decides WHICH player is active; playerctl held
    // a second, blind opinion and could drive a different one than the panel
    // was showing. No readout surface: play/pause/next is audible the instant
    // it lands, so unlike a level there is nothing invisible to report.
    Keybind {
        name: "mediaToggle"
        description: "Play / pause"
        onPressed: MediaService.togglePlaying()
    }

    Keybind {
        name: "mediaNext"
        description: "Next track"
        onPressed: MediaService.next()
    }

    Keybind {
        name: "mediaPrev"
        description: "Previous track"
        onPressed: MediaService.previous()
    }

    Keybind {
        name: "brightnessUp"
        description: "Screen brightness up"
        onPressed: BrightnessService.setValue(BrightnessService.value + root.levelStep)
    }

    Keybind {
        name: "brightnessDown"
        description: "Screen brightness down"
        onPressed: BrightnessService.setValue(BrightnessService.value - root.levelStep)
    }
}
