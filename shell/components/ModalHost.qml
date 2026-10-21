import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.state
import qs.theme

// THE modal host. One component for the scaffolding every keyboard modal
// needs and none of them owns: the full-scene click-catch (click ANYWHERE
// closes — the mask must therefore cover the whole scene, not the drawer),
// the Rollout with the modal's silhouette, the open() re-fire when the modal
// becomes active, and the catch-region registration under `<name>-catch`.
// A new modal is ~10 lines on top of it.
//
// The consumer provides content (default property) and calls its surface's
// open() from onOpened. Placement follows from `edges` — the shell-wide
// policy, not a per-consumer choice: a left-attached modal starts beside the
// rail (reservedLeft), an unattached axis centers.
//
// NOT handled here: WlrLayershell.keyboardFocus (EdgeScene enumerates every
// keyboard modal in ONE expression — splitting that list across hosts is how
// a surface ends up rendering with a dead keyboard) and ShellState.modalNames
// (the IPC registry).
Item {
    id: root

    // The EdgeScene hosting this modal; must expose modelData, fullscreen,
    // and focusMode.
    required property var scene
    // The ShellBorder answering the library's seven-call contract — the
    // rollout-region registry this modal's own catch-region calls target.
    required property var host
    // ShellState modal name; doubles as rolloutId and the mask id.
    required property string name
    // Window side(s) the drawer is flush with — Rollout semantics.
    property var edges: ["top"]
    property real bodyWidth
    property real bodyHeight

    default property alias content: drawer.content

    readonly property bool active: !scene.focusMode && ShellState.modal === name
        && ShellState.focusedScreen === scene.modelData
    readonly property bool revealed: drawer.visible
    readonly property bool animating: drawer.animating

    // Fires when this modal becomes the active one — the consumer resets and
    // focuses its surface here.
    signal opened

    onActiveChanged: {
        if (active)
            root.opened();
    }

    anchors.fill: parent

    MouseArea {
        anchors.fill: parent
        enabled: !root.scene.fullscreen && !root.scene.focusMode && (root.active || drawer.visible)
        visible: enabled
        onClicked: ShellState.closeModal()
    }

    QsmShellComponents.Rollout {
        id: drawer

        host: root.host
        rolloutId: root.name
        edges: root.edges
        tier: "large"
        instantReveal: !ShellState.modalByPointer
        instantRetract: !ShellState.modalByPointer
        // The catch region below is the hit area; the Rollout registers only
        // its silhouette bulge.
        registerHitRect: false
        shouldBeActive: root.active
        suppressed: root.scene.fullscreen || root.scene.focusMode
        bodyWidth: root.bodyWidth
        bodyHeight: root.bodyHeight

        // Anchors are assigned imperatively: the declarative ternary form
        // (left/right/horizontalCenter all declared, resolving to undefined)
        // trips qml-lint's anchor-combinations check, which is static.
        // A left-attached modal starts beside the rail, not under it.
        anchors.leftMargin: root.edges.includes("left") ? Theme.reservedLeft : 0

        Component.onCompleted: {
            if (root.edges.includes("top"))
                anchors.top = parent.top;
            if (root.edges.includes("bottom"))
                anchors.bottom = parent.bottom;
            if (root.edges.includes("left"))
                anchors.left = parent.left;
            else if (root.edges.includes("right"))
                anchors.right = parent.right;
            else
                anchors.horizontalCenter = parent.horizontalCenter;
        }
    }

    // Full-scene mask (not the drawer's bounds): the mask must match what is
    // actually intercepting clicks — the catch MouseArea above.
    readonly property rect maskRect: !root.scene.fullscreen && !root.scene.focusMode && (active || drawer.visible)
        ? Qt.rect(0, 0, width, height)
        : Qt.rect(0, 0, 0, 0)

    onMaskRectChanged: {
        if (maskRect.width > 0 && maskRect.height > 0)
            host.registerRolloutRegion(name + "-catch", maskRect);
        else
            host.unregisterRolloutRegion(name + "-catch");
    }
}
