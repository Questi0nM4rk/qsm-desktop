// ComponentBehavior: Bound — this surface's Repeater delegate reads the
// surface's own selection and arm state, which qmllint rejects as unqualified
// unless outer IDs are explicitly captured. The delegate already declares its
// modelData/index as `required`, which is the shape Bound wants, so the pragma
// is the actual fix here rather than a suppression (scripts/qml-lint header:
// the repo-wide migration is out of scope, one file at a time is not).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.state
import qs.theme

// Session surface (08): right-edge rollout, single column of action buttons —
// lock, logout, hibernate, reboot, shutdown (hyprlock; hyprland exit;
// systemctl). Destructive actions arm-then-fire. The 35% dim + blur backdrop is
// SessionBackdrop (the one sanctioned second surface).
//
// KEYBOARD-DRIVEN as well as pointer-driven (owner 2026-08-24): Up/Down move
// the selection, Enter or Space activates it, and activation runs the same
// arm-then-fire — so reaching shutdown by keyboard costs two presses, exactly
// as it costs two clicks. Hover writes the SAME selection, so there is one mark
// on screen rather than a hover highlight racing a keyboard highlight (09
// one-path).
//
// This surface owns BOTH the selection and the arm, and the buttons are pure
// views of them. The alternative — arm state inside each button — means the
// keyboard has to reach into the delegate to fire it, and "which one is armed"
// then lives in five places that have to be talked out of it one by one.
Item {
    id: root

    required property var targetScreen
    required property var scene
    // The ShellBorder answering the library's seven-call contract.
    required property var host
    readonly property bool active: ShellState.modal === "session"
        && ShellState.focusedScreen === targetScreen
    readonly property bool fullscreen: FullscreenService.fullscreenFor(targetScreen)
    readonly property bool revealed: rollout.visible

    // The set and its order are spec/08 RATIFIED, so this list IS the spec.
    // Five near-identical declarations were five places to keep in step, and
    // the keyboard needs an index anyway. Hibernate REPLACED suspend (owner
    // 2026-08-21): this machine hibernates rather than sleeps, and one path to
    // one feature means suspend is gone rather than kept beside it.
    readonly property var actions: [
        { icon: "lock", label: "Lock", role: "lock", destructive: false },
        { icon: "log-out", label: "Logout", role: "logout", destructive: true },
        { icon: "moon", label: "Hibernate", role: "hibernate", destructive: false },
        { icon: "rotate-cw", label: "Reboot", role: "reboot", destructive: true },
        { icon: "power", label: "Shutdown", role: "shutdown", destructive: true }
    ]

    // Opens on Lock: the harmless one. A power column that opens with shutdown
    // selected is one stray Enter away from a very bad afternoon.
    property int selectedIndex: 0
    // -1 = nothing armed.
    property int armedIndex: -1

    anchors.fill: parent

    // Takes a delegation ROLE, not a command — which binary locks or reboots
    // this machine is Delegate's business, not the session surface's.
    function run(role: string): void {
        Delegate.open(role);
        ShellState.closeModal();
    }

    function select(index: int): void {
        if (index === root.selectedIndex)
            return;

        // Moving off an armed button disarms it, the same as the pointer
        // leaving does: what the selection left must not stay one Enter from
        // firing.
        root.armedIndex = -1;
        root.selectedIndex = index;
    }

    function moveSelection(delta: int): void {
        root.select(Math.max(0, Math.min(root.actions.length - 1, root.selectedIndex + delta)));
    }

    // THE activation path, reached by a click on a button and by Enter/Space on
    // the selected one. Two ways in, one function: that is one path, not two.
    function activate(index: int): void {
        const action = root.actions[index];
        if (!action)
            return;

        root.select(index);
        if (!action.destructive || root.armedIndex === index) {
            root.armedIndex = -1;
            disarmTimer.stop();
            root.run(action.role);
        } else {
            root.armedIndex = index;
            disarmTimer.restart();
        }
    }

    // 08 DEFAULT: an armed button disarms after 3s or when the cursor leaves.
    Timer {
        id: disarmTimer
        interval: 3000
        onTriggered: root.armedIndex = -1
    }

    QsmShellComponents.Rollout {
        id: rollout
        host: root.host
        rolloutId: "session"
        edges: ["right"]
        tier: "large"
        registerHitRect: false // the host's full-scene catch region is the hit area
        shouldBeActive: root.active
        suppressed: root.fullscreen || root.scene.focusMode
        // One token for spec-08's 96, shared with the button itself (was the
        // literal duplicated across both files — S5-F14).
        bodyWidth: Theme.sessionButtonWidth + Theme.space4 * 2
        bodyHeight: column.implicitHeight + Theme.space4 * 2
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        FocusScope {
            id: sessionFocus
            anchors.fill: parent

            Keys.onEscapePressed: ShellState.closeModal()
            Keys.onUpPressed: root.moveSelection(-1)
            Keys.onDownPressed: root.moveSelection(1)
            Keys.onReturnPressed: root.activate(root.selectedIndex)
            Keys.onEnterPressed: root.activate(root.selectedIndex)
            Keys.onSpacePressed: root.activate(root.selectedIndex)

            ColumnLayout {
                id: column
                anchors.horizontalCenter: parent.horizontalCenter
                // The column centres in the whole silhouette -- its own body
                // plus the band it bulges out of -- not in the body alone.
                // Centred in the body it sat half a band-depth left of the
                // middle of the shape a person actually sees.
                anchors.horizontalCenterOffset: rollout.contentCenterOffsetX
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.space2

                Repeater {
                    model: root.actions

                    QsmShellComponents.ActionTile {
                        required property var modelData
                        required property int index

                        icon: modelData.icon
                        label: modelData.label
                        // Selected is SECONDARY here, not the accent: the
                        // accent is spent on armed, and on this surface what
                        // happens next matters more than what is picked.
                        accent: Theme.secondary
                        buttonWidth: Theme.sessionButtonWidth
                        buttonHeight: Theme.sessionButtonHeight
                        selected: root.selectedIndex === index
                        armed: root.armedIndex === index
                        onEntered: root.select(index)
                        onExited: {
                            if (root.armedIndex === index)
                                root.armedIndex = -1;
                        }
                        onActivated: root.activate(index)
                    }
                }
            }
        }
    }

    onActiveChanged: {
        if (active) {
            // Every open starts from Lock with nothing armed. A surface that
            // remembers where you left off remembers it next to a shutdown
            // button.
            selectedIndex = 0;
            armedIndex = -1;
            sessionFocus.forceActiveFocus();
        }
    }
}
