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
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.state
import qs.theme

// Session surface (08): right-edge rollout, single column of action buttons —
// lock, logout, hibernate, reboot, shutdown (hyprlock; hyprland exit;
// systemctl). Destructive actions arm-then-fire. The 35% dim + blur backdrop is
// SessionBackdrop (the one sanctioned second surface).
//
// KEYBOARD-DRIVEN as well as pointer-driven: Up/Down move
// the selection, Enter or Space activates it, and activation runs the same
// arm-then-fire — so reaching shutdown by keyboard costs two presses, exactly
// as it costs two clicks. Hover writes the SAME selection, so there is one mark
// on screen rather than a hover highlight racing a keyboard highlight (09
// one-path).
//
// This surface owns the selection; the arm is the library's ArmedAction, one
// per tile, so the timeout and the disarm rules are the library's and not a
// second copy. The keyboard fires the selected tile through the same
// ArmedAction its click does (`trigger`).
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

    // The set and its order are spec/08, so this list IS the spec.
    // Five near-identical declarations were five places to keep in step, and
    // the keyboard needs an index anyway. Hibernate REPLACES suspend: this machine hibernates rather than sleeps, and one path to
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

        // The tile the selection leaves disarms itself (its onSelectedChanged):
        // what the selection left must not stay one Enter from firing.
        root.selectedIndex = index;
    }

    function moveSelection(delta: int): void {
        root.select(Math.max(0, Math.min(root.actions.length - 1, root.selectedIndex + delta)));
    }

    // Untyped: a Repeater hands back a bare Item, and the delegate's `arm` is
    // not on that type.
    function tileAt(index: int): var {
        return tiles.itemAt(index);
    }

    // THE activation path, reached by a click on a button and by Enter/Space on
    // the selected one. Two ways in, one function: that is one path, not two.
    // The tile's ArmedAction decides: arm a destructive one, fire the rest.
    function activate(index: int): void {
        const tile = root.tileAt(index);
        if (!tile)
            return;

        root.select(index);
        tile.arm.trigger();
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
        // One token for spec-08's 96, shared with the button itself.
        bodyWidth: QsmShellStyle.Style.tileWidth + QsmShellStyle.Style.rolloutPadding * 2
        bodyHeight: column.implicitHeight + QsmShellStyle.Style.rolloutPadding * 2
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
                spacing: QsmShellStyle.Style.space2

                Repeater {
                    id: tiles
                    model: root.actions

                    QsmShellComponents.ActionTile {
                        id: tile
                        required property var modelData
                        required property int index

                        // 08 DEFAULT: an armed button disarms after 3s (the
                        // library's timeout) or when the cursor leaves.
                        readonly property QsmShellComponents.ArmedAction arm: QsmShellComponents.ArmedAction {
                            destructive: tile.modelData.destructive
                            onFired: root.run(tile.modelData.role)
                        }

                        icon: modelData.icon
                        label: modelData.label
                        // The armed tile names its next press: the fill alone
                        // differs from selected only in hue.
                        confirmLabel: "Confirm"
                        // Selected is PRIMARY here, not the accent: the
                        // accent is spent on armed, and on this surface what
                        // happens next matters more than what is picked.
                        accent: Theme.primary
                        // 08: shutdown, the one destructive action, is set
                        // apart by a full step (space4 including the column's
                        // own gap) and draws in danger.
                        danger: modelData.role === "shutdown"
                        Layout.topMargin: modelData.role === "shutdown" ? QsmShellStyle.Style.space4 - QsmShellStyle.Style.space2 : 0
                        buttonWidth: QsmShellStyle.Style.tileWidth
                        buttonHeight: QsmShellStyle.Style.tileHeight
                        selected: root.selectedIndex === index
                        focused: selected && sessionFocus.activeFocus
                        armed: arm.armed
                        onSelectedChanged: if (!selected) arm.disarm()
                        onEntered: root.select(index)
                        onExited: arm.disarm()
                        onActivated: root.activate(index)
                    }
                }
            }
        }
    }

    onActiveChanged: {
        if (active) {
            // Every open starts from Lock; the tile the selection leaves
            // disarms itself, so nothing stays armed. A surface that remembers
            // where you left off remembers it next to a shutdown button.
            selectedIndex = 0;
            sessionFocus.forceActiveFocus();
        }
    }
}
