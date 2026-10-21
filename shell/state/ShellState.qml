pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.services

QtObject {
    id: root

    // Only modals with an existing surface. Grow this list WITH each new modal module —
    // registering a name here is what makes `qsm toggle <name>` report success over IPC.
    readonly property var modalNames: [
        "launcher",
        "panel",
        "session",
        "clipboard",
        "notifications",
        "cheatsheet"
    ]
    // Panel tab names double as IPC toggle aliases: `qsm toggle media` opens
    // the panel on the Media tab (06-top-panel).
    readonly property var panelTabs: [
        "dashboard",
        "media",
        "performance",
        "workspaces"
    ]
    property string modal: "none"
    // Fullscreen and qsm focus mode are hard modal boundaries: suppressed
    // surfaces must not leave latent state that reappears when the boundary
    // clears. The optional geometry transformation publishes its workspace
    // here to avoid a singleton cycle; it must never block another workspace.
    property string focusModeScreen: ""
    property int focusModeWorkspaceId: 0
    property alias panelTab: persisted.lastPanelTab
    // A keyboard accelerator can enter the launcher at a specific command
    // without giving that command a duplicate surface.
    property string launcherSeed: ""

    // A NON-MODAL surface that needs the keyboard names itself here (e.g. the
    // network popout's wifi password prompt). While set: the scene grants
    // keyboard focus (EdgeScene's focus list) and hover popouts refuse to
    // auto-close (PopoutController) — a surface being typed into must not
    // vanish when the pointer drifts. The claimant clears it; "" = none.
    property string keyboardGrab: ""


    // While TRUE, hovering a row must not move the selection: the keyboard is
    // driving and the pointer has not moved since.
    //
    // Every search surface lets hover pick the selected row, because pointer
    // and keyboard drive ONE cursor rather than two competing highlights (09
    // one-path). The flaw only shows while typing: the results RESHUFFLE under
    // a cursor that never moved, so whichever row slid beneath it grabbed the
    // selection and Enter launched something never aimed at (searching with
    // the pointer resting mid-launcher). A hover
    // that the LIST caused is not a pointer gesture and gets no say.
    //
    // Claimed by SearchField on each typed character; released by the scene's
    // pointer tracker on real pointer motion (EdgeScene). No timeout, because
    // "the pointer moved" is the actual fact — moving the mouse a pixel hands
    // control straight back.
    property bool keyboardOwnsSelection: false

    function claimKeyboardSelection(): void {
        keyboardOwnsSelection = true;
    }

    // A surface that just opened has not been typed into, so the pointer is
    // free again. Without this, a claim left standing by the last search kept
    // hover inert in the NEXT surface until the pointer moved — including in
    // surfaces that have no search field at all, like the session column.
    onModalChanged: keyboardOwnsSelection = false

    readonly property var focusedScreen: {
        const monitor = Hyprland.focusedMonitor;
        for (const screen of Quickshell.screens) {
            if (monitor && Hyprland.monitorFor(screen) === monitor)
                return screen;
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }
    // A modal may not open over a fullscreen window, or on the screen and
    // workspace that focus mode holds. Every operand is already a bool.
    readonly property bool modalBlocked: !!focusedScreen
        && (FullscreenService.fullscreenFor(focusedScreen)
            || (focusModeScreen === focusedScreen.name
                && FullscreenService.workspaceFor(focusedScreen)?.id === focusModeWorkspaceId))

    onModalBlockedChanged: {
        if (modalBlocked)
            closeModal();
    }

    // How the open modal was reached. A key, the IPC and a launcher command
    // open it in one frame, and it leaves the same way: they are repeated a
    // hundred times a day and a person is waiting on the result. The pointer's
    // routes (the power cell, the bell) keep the rollout's motion in and out.
    property bool modalByPointer: false

    function toggleModal(name: string): bool {
        return changeModal(name, false);
    }

    function toggleModalByPointer(name: string): bool {
        return changeModal(name, true);
    }

    function changeModal(name: string, byPointer: bool): bool {
        if (panelTabs.includes(name))
            return togglePanel(name);
        if (!modalNames.includes(name))
            return false;

        if (modal === name) {
            closeModal();
            return true;
        }
        if (modalBlocked)
            return false;

        // Before `modal` moves, so the surface that reveals reads the way in.
        modalByPointer = byPointer;
        modal = name;
        return true;
    }

    function openLauncher(seed: string): bool {
        if (modalBlocked)
            return false;

        // Publish the seed before the modal activates: LauncherSurface opens
        // synchronously on the modal transition and must see this invocation's
        // command mode instead of its ordinary app-search default.
        launcherSeed = seed;
        modalByPointer = false;
        modal = "launcher";
        return true;
    }

    // Seeded launcher routes (Super+A) must toggle like the plain launcher
    // route: a second press closes the open command centre rather than merely
    // re-seeding a modal that is already active.
    function toggleLauncher(seed: string): bool {
        if (modal === "launcher") {
            closeModal();
            return true;
        }
        return openLauncher(seed);
    }

    // Opening lands on the LAST USED tab (06) unless a tab is named;
    // re-toggling the same tab (or the bare panel) closes.
    function togglePanel(tab: string): bool {
        // A persisted tab that is not a panel tab lands on Dashboard.
        const target = panelTabs.includes(tab) ? tab
            : panelTabs.includes(panelTab) ? panelTab : "dashboard";
        if (modal === "panel" && panelTab === target) {
            closeModal();
            return true;
        }
        if (modalBlocked)
            return false;

        panelTab = target;
        modal = "panel";
        return true;
    }

    function closeModal(): void {
        modal = "none";
    }

    // Per-monitor rail collapse. Keyed by output name; reassigned (never
    // mutated) so bindings through isRailCollapsed re-evaluate. EdgeScene
    // renders it, FrameExclusions shrinks the reserved zone with it.
    // Persisted with the last panel tab (09-input persistence).
    property alias collapsedRails: persisted.collapsedRails
    // Dashboard weather location (09 persistence key; empty = IP-based).
    property alias weatherLocation: persisted.weatherLocation

    function isRailCollapsed(screenName: string): bool {
        return collapsedRails[screenName] === true;
    }

    function toggleRail(screenName: string): bool {
        const next = Object.assign({}, collapsedRails);
        next[screenName] = !isRailCollapsed(screenName);
        collapsedRails = next;
        return next[screenName];
    }

    function setRailCollapsed(screenName: string, collapsed: bool): bool {
        const next = Object.assign({}, collapsedRails);
        next[screenName] = collapsed;
        collapsedRails = next;
        return collapsed;
    }

    // Theme choice and effect flags — owned here since the one-file merge;
    // Theme.qml exposes read-only views of these.
    property alias theme: persisted.theme
    property alias reducedMotion: persisted.reducedMotion
    property alias reducedEffects: persisted.reducedEffects
    // DND (09 persistence key).
    property alias dnd: persisted.dnd
    // Bounded notification history; NotificationService owns its shape.
    property alias notificationHistory: persisted.notificationHistory
    // Night-light warmth in Kelvin (NightLightService owns the scale). A
    // setting that resets every login is a setting the user makes every login.
    property alias nightLightTemperature: persisted.nightLightTemperature
    // Picked colours, newest first, bounded (ColorPickService owns the shape).
    // JSON rather than a database: this is a recent list of ~24 short strings,
    // not an archive anybody queries; the 200-entry cap on notificationHistory
    // is the list that would want a DB.
    property alias colorHistory: persisted.colorHistory

    // ONE state file (09 DEFAULT): ~/.local/state/qsm/state.json.
    readonly property string qsmStateDir:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/qsm"

    // FileView does not create directories; the first write needs one.
    property Process stateDirMaker: Process {
        command: ["mkdir", "-p", root.qsmStateDir]
        onExited: stateFile.writeAdapter()
    }

    property FileView stateFile: FileView {
        id: stateFile
        path: root.qsmStateDir + "/state.json"
        atomicWrites: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: {
            persisted.lastPanelTab = "dashboard";
            persisted.collapsedRails = {};
            root.stateDirMaker.running = true;
        }

        JsonAdapter {
            id: persisted
            property string theme: "deep-night"
            property bool reducedMotion: false
            property bool reducedEffects: false
            property string lastPanelTab: "dashboard"
            property var collapsedRails: ({})
            property string weatherLocation: ""
            property bool dnd: false
            property var notificationHistory: []
            property int nightLightTemperature: 4000
            property var colorHistory: []
        }
    }
}
