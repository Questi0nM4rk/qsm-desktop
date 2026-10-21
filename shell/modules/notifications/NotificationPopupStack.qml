import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// Popup presentation (04-notifications): ONE notification window with two
// genuine shell hosts, the same way OsdSurface carries one channel column.
// Normal mode is the attached TOP band Rollout; fullscreen has no frame to
// grow out of, so it is a real shell `DataCapsule`. This file keeps the
// service, host selection, and per-row fullscreen input holes (09), which
// need a screen the library must never see.
Item {
    id: root

    required property var targetScreen
    required property var scene
    // The ShellBorder answering the library's seven-call contract.
    required property var host
    // Injection keeps this exact production surface hostable in an isolated
    // Workbench scene without acquiring the live notification bus/history.
    required property var notificationService
    property bool focused: false
    property string modal: "none"
    property string swatchAppName: ""
    readonly property var stack: notificationService.popups
    readonly property bool fullscreen: root.scene.fullscreen
    readonly property var rolloutSurface: rollout
    readonly property var capsuleSurface: capsule
    readonly property var notificationSurface: notificationStack

    // One intent for both presentations, so they cannot disagree about
    // whether a notification belongs on screen.
    readonly property bool popupActive: root.focused
        && root.modal !== "panel"
        && root.modal !== "session"
        && root.modal !== "notifications"
        && root.stack.length > 0

    // ── selected presentation semantics ─────────────────────────────────
    // Each fact is read from the host actually on screen. DataCapsule has no
    // `animating`, so its fade is read from the two facts it does publish:
    // still present, and opacity not yet at the end `shown` asks for.
    readonly property bool presentationVisible: root.fullscreen
        ? capsule.present : rollout.visible
    readonly property bool presentationActive: root.fullscreen
        ? capsule.shown : rollout.shouldBeActive
    readonly property bool presentationSettling: root.fullscreen
        ? capsule.present && capsule.opacity !== (capsule.shown ? 1 : 0)
        : rollout.animating
    readonly property bool presentationOpen: root.presentationActive
        && !root.presentationSettling
    readonly property bool presentationClosing: root.presentationSettling
        && !root.presentationActive
    readonly property real presentationOffset: root.fullscreen
        ? (capsule.shown ? 0 : 1) : rollout.offsetScale

    signal rowHoverIntent(var notificationId, bool hovered)
    signal rowDismissIntent(var notificationId)
    signal rowPrimaryIntent(var notificationId)
    signal rowPrimaryInvoked(var notificationId)

    function targetForNotification(notificationId: var): var {
        return notificationStack.targetForNotification(notificationId);
    }

    function invokeCurrentDefault(entry: var): bool {
        const id = entry?.notificationId;
        const row = notificationStack.targetForNotification(id);
        const current = notificationService.live.find(item => item.notificationId === id);
        if (!notificationStack.inputEnabled || !row || !row.inputEnabled || !current
                || !(current.actions ?? []).some(action => String(action.id) === "default"
                    && !(action.disabled ?? false)))
            return false;
        root.rowPrimaryIntent(id);
        if (!root.notificationService.invokeDefault(id))
            return false;
        root.rowPrimaryInvoked(id);
        return true;
    }

    // Ids currently carrying a fullscreen input hole, so a row that stops being
    // rendered at all (dismissed, expired, finished evicting — not merely
    // toggled off by leaving fullscreen) has its hole torn down too.
    property var registeredCapsuleIds: []

    // Per-row fullscreen input holes (09). `paint: false`: the capsule paints
    // the one body, so a painted capsule per row would be a second body
    // around content that already has one. Eligibility, not mere presence,
    // decides a hole — a retained or evicting row keeps its picture and loses
    // its input the moment it stops being clickable.
    function syncFullscreenCapsules(): void {
        const rows = notificationStack.cardGeometry();
        const currentIds = [];
        for (const row of rows) {
            const id = "notify-row-" + row.notificationId;
            currentIds.push(id);
            // RENDERED is not ALIVE: `alive` re-joins what `row.eligible`
            // cannot see, because the library keeps a dismissed row on screen
            // for its eviction slide and a hole belongs only to an entry that
            // can still be clicked.
            const alive = notificationService.live.some(
                entry => entry.notificationId === row.notificationId);
            if (root.scene.fullscreen && alive && row.eligible
                    && row.rect.width > 0 && row.rect.height > 0) {
                const p = notificationStack.mapToItem(root.scene.contentItem, row.rect.x, row.rect.y);
                root.host.registerFullscreenCapsule(id,
                    Qt.rect(p.x, p.y, row.rect.width, row.rect.height), QsmShellStyle.Style.radiusPill, false);
            } else {
                root.host.unregisterFullscreenCapsule(id);
            }
        }
        for (const id of root.registeredCapsuleIds) {
            if (!currentIds.includes(id))
                root.host.unregisterFullscreenCapsule(id);
        }
        root.registeredCapsuleIds = currentIds;
    }

    Component.onCompleted: Qt.callLater(syncFullscreenCapsules)

    Connections {
        target: root.scene

        function onFullscreenChanged(): void {
            Qt.callLater(root.syncFullscreenCapsules);
        }
    }

    anchors.fill: parent

    QsmShellComponents.Rollout {
        id: rollout
        host: root.host
        rolloutId: "notify-popups"
        // Expands DOWN; right edge is a flush contact merged into the right
        // band (squared corner + rim burial).
        edges: ["top", "right"]
        // An unbidden, occasional arrival (spec 1.7): the small tier, which
        // its short travel allows.
        tier: "small"
        // The body runs to the monitor's top and right edges and the cards sit
        // one gutter inside it, so their distance to the monitor is the gutter.
        edgeInset: 0
        shouldBeActive: root.popupActive
        // Fullscreen keeps its allowlist (09) through the capsule, which paints
        // that body. There is no frame to melt into there, so no detach.
        suppressed: root.fullscreen
        fullscreenDetached: false
        fullscreenCapsule: false
        settleContent: false
        // Card heights and eviction already animate the column's actual extent.
        animateBodySize: false
        padding: Theme.notificationGutter
        bodyWidth: notificationStack.implicitWidth + padding * 2
        bodyHeight: notificationStack.implicitHeight + padding * 2
        anchors.top: parent.top
        anchors.right: parent.right
    }

    QsmShellComponents.DataCapsule {
        id: capsule
        // The service stays the only lifetime and dismissal owner, so this capsule
        // never expires itself and offers no action of its own.
        shown: root.popupActive && root.fullscreen
        enabled: root.popupActive && root.fullscreen
        timeout: 0
        // Rows keep their own hover, pause and gestures.
        interactive: false
        orientation: Qt.Vertical
        // The rollout's own inner padding, so both bodies inset the column
        // identically.
        padding: Theme.notificationGutter
        bodySize: notificationStack.implicitWidth + padding * 2
        preferredLength: notificationStack.height + padding * 2
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: QsmShellStyle.Style.space2
        anchors.rightMargin: QsmShellStyle.Style.space2
    }

    QsmShellComponents.NotificationStack {
        id: notificationStack
        // ONE stack, two hosts: the slot is the parent, never a duplicate object,
        // so a mode switch moves the same rows with their own state. Centring
        // at its own implicit size is what keeps a row inside the painted
        // body; the rollout's slot is that size already, so it changes
        // nothing there.
        parent: root.fullscreen ? capsule.contentItem : rollout.contentItem
        width: implicitWidth
        height: implicitHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        stack: root.stack
        // Surface cards of the medium radius, a token gap apart (spec 04).
        bodied: true
        bodyRadius: QsmShellStyle.Style.radiusMd
        rowSpacing: QsmShellStyle.Style.space2
        isAlive: id => root.notificationService.live.some(entry => entry.notificationId === id)
        // Retention follows the selected host, including the capsule's fade —
        // DataCapsule still reports `present` after `shown` has gone.
        retainWhenEmpty: root.presentationVisible
        inputEnabled: root.fullscreen
            ? capsule.acceptsInput
            : rollout.shouldBeActive && rollout.hitActive
        // A colour-picker announcement's summary IS the picked hex;
        // the app name that decides this is the one
        // hardcoded name this shell owns and the library must never see.
        swatchFor: entry => entry.appName === root.swatchAppName
            && /^#[0-9a-fA-F]{6}$/.test(entry.summary) ? entry.summary : undefined
        onDismissRequested: entry => {
            root.rowDismissIntent(entry.notificationId);
            root.notificationService.dismiss(entry.notificationId);
        }
        onHoverChanged: (entry, hovered) => {
            root.rowHoverIntent(entry.notificationId, hovered);
            root.notificationService.setPaused(entry.notificationId, hovered);
        }
        onPrimaryActionRequested: entry => root.invokeCurrentDefault(entry)
        onGeometryChanged: Qt.callLater(root.syncFullscreenCapsules)
    }

    Connections {
        target: rollout
        function onVisibleChanged(): void {
            Qt.callLater(root.syncFullscreenCapsules);
        }
    }

    Connections {
        // Reparenting moves every row in the scene without changing the
        // stack's own geometry, and neither does an ancestor moving: a
        // viewport resize or a changed inset moves this capsule without
        // touching any stack-local width, height or card rect, so the
        // scene mapping has no stack-side signal to hear.
        target: capsule

        function onShownChanged(): void {
            Qt.callLater(root.syncFullscreenCapsules);
        }

        function onXChanged(): void {
            Qt.callLater(root.syncFullscreenCapsules);
        }

        function onYChanged(): void {
            Qt.callLater(root.syncFullscreenCapsules);
        }
    }
}
