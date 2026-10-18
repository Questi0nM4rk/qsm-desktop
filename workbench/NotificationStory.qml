import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.modules.notifications as Notifications
import qs.services as Services
import qs.state as State
import qs.theme

Item {
    id: root

    property var previewEnvironment: null
    property int viewportWidth: 980
    property int viewportHeight: 680
    property var inputDriver: null
    property bool interactive: false
    property int resetGeneration: 0
    property var notificationService: null
    property bool resetPresentationPending: false
    property bool observing: true
    property bool dnd: false
    property string selectedUrgency: "normal"
    property int selectedTimeoutMs: -1
    property int transferId: 0
    property int newestId: 0
    property int lastDismissedId: 0
    property string rejectedField: ""
    property string rejectedMessage: ""
    property int operationCount: 0
    property int primaryIntentCount: 0
    property int primaryCallbackCount: 0
    property int lastPrimaryId: 0
    property var replacementSourceRow: null
    property bool replacementKeptRow: false
    property double dismissedHeight: 0
    property int expiryCompletionCount: 0
    property bool resetObservationWindow: false

    readonly property var notificationModel: notificationService?.store
        ?? notificationService ?? notificationStore

    readonly property bool fullscreen: previewEnvironment?.fullscreen === true
    readonly property rect screenRect: previewEnvironment?.screenRect
        ?? Qt.rect(0, 0, viewportWidth, viewportHeight)
    readonly property real contentExtentWidth: width
    readonly property real contentExtentHeight: height
    readonly property var targetScreen: screenFacts
    readonly property var integration: ({
        events: ["hovered", "dismissed", "primary-triggered", "action-invoked"],
        observables: {
            "live-count": () => notificationModel.live.length,
            "live-ids": () => notificationModel.live.map(entry => entry.notificationId),
            "source-live-ids": () => notificationModel.live.map(entry => entry.notificationId),
            "popup-ids": () => notificationModel.popups.map(record => record.notificationId),
            "archive-count": () => notificationModel.archive.length,
            "latest-id": () => root.newestId,
            "latest-summary": () => notificationModel.live[0]?.summary ?? "",
            "latest-app-name": () => notificationModel.live[0]?.appName ?? "",
            "latest-body": () => notificationModel.live[0]?.body ?? "",
            "latest-primary-available": () => popup.targetForNotification(root.newestId)?.primaryActionAvailable ?? false,
            "primary-intent-count": () => root.primaryIntentCount,
            "primary-callback-count": () => root.primaryCallbackCount,
            "last-primary-id": () => root.lastPrimaryId,
            "latest-urgency": () => notificationModel.live[0]?.urgency ?? "",
            "latest-expiry-ms": () => notificationModel.live[0]?.expiryMs ?? -1,
            "latest-paused": () => notificationModel.live.find(entry => entry.notificationId === root.newestId)?.paused ?? false,
            "paused-count": () => notificationModel.live.filter(entry => entry.paused).length,
            "rejected-field": () => root.rejectedField,
            "rejected-message": () => root.rejectedMessage,
            "transfer-id": () => root.transferId,
            "transfer-created-at": () => notificationModel.live.find(entry => entry.notificationId === root.transferId)?.createdAt ?? 0,
            "transfer-summary": () => notificationModel.live.find(entry => entry.notificationId === root.transferId)?.summary ?? "",
            // Settled means the SELECTED host has caught up with the expanded
            // row: the attached Rollout's body height and its registered
            // silhouette in normal mode, the DataCapsule's own body in
            // fullscreen. Both are read from the host that is really on
            // screen; neither is faked from the other mode's numbers.
            "transfer-expanded-settled": () => {
                const card = popup.targetForNotification(root.transferId);
                const stack = popup.notificationSurface;
                const epsilon = 0.01;
                const rowSettled = !!card && card.expanded && !card.expansionAnimating
                    && Math.abs(card.height - card.implicitHeight) < epsilon
                    && Math.abs(stack.implicitHeight - card.height) < epsilon;
                if (!rowSettled)
                    return false;
                if (popup.fullscreen) {
                    const capsule = popup.capsuleSurface;
                    return !popup.presentationSettling
                        && Math.abs(capsule.height - (stack.implicitHeight + capsule.padding * 2)) < epsilon;
                }
                const rollout = popup.rolloutSurface;
                const bulge = border.bulgeRegions[rollout.rolloutId];
                return Math.abs(rollout.bodyHeight - (stack.implicitHeight + rollout.padding * 2)) < epsilon
                    && !rollout.animating
                    && !!bulge && Math.abs(bulge.rect.height - rollout.bodyHeight) < epsilon;
            },
            "transfer-drag-active": () => popup.targetForNotification(root.transferId)?.dragActive ?? false,
            "transfer-input-enabled": () => popup.targetForNotification(root.transferId)?.inputEnabled ?? false,
            "last-dismissed-id": () => root.lastDismissedId,
            "dismissed-height": () => root.dismissedHeight,
            "archive-summaries": () => notificationModel.archive.map(record => record.summary),
            "row-phases": () => root.rowFacts().map(row => ({ id: row.notificationId, phase: row.phase, eligible: row.eligible })),
            "row-geometry": () => root.rowFacts(),
            "evicting-count": () => root.rowFacts().filter(row => row.phase === "evicting").length,
            "row-identity": () => root.rowIdentity(root.transferId),
            "replacement-kept-row": () => root.replacementKeptRow,
            "retained-row": () => root.rowFacts().some(row => row.phase === "retained"),
            "retained-height": () => root.retainedHeight(),
            "retained-content": () => root.retainedCard()?.entry?.summary ?? "",
            "retained-frozen": () => root.retainedCard()?.expansionFrozen ?? false,
            "retained-height-matches": () => root.retainedHeight() > 0
                && root.retainedHeight() === root.dismissedHeight,
            // Presentation facts, read from whichever host is selected. The
            // names stay the flow API's own; the source is the real surface.
            "rollout-visible": () => popup.presentationVisible,
            "rollout-open": () => popup.presentationOpen,
            "rollout-closing": () => popup.presentationClosing,
            "rollout-offset": () => popup.presentationOffset,
            "presentation-fullscreen": () => popup.fullscreen,
            "capsule-shown": () => popup.capsuleSurface.shown,
            "capsule-present": () => popup.capsuleSurface.present,
            "capsule-accepts-input": () => popup.capsuleSurface.acceptsInput,
            "rollout-region-ids": () => Object.keys(border.rolloutRegions),
            "rollout-bulge-ids": () => Object.keys(border.bulgeRegions),
            "rendered-row-count": () => popup.notificationSurface.cardGeometry().length,
            "fullscreen": () => root.fullscreen,
            "fullscreen-mask-count": () => root.fullscreenMaskIds().length,
            "fullscreen-mask-ids": () => root.fullscreenMaskIds(),
            "reduced-motion": () => State.ShellState.reducedMotion,
            "dnd": () => notificationModel.dnd,
            "reset-presentation-pending": () => root.resetPresentationPending,
            "operation-count": () => root.operationCount,
            "expiry-completions": () => root.expiryCompletionCount,
            "reset-observation-window": () => root.resetObservationWindow,
            "input-simulated": () => root.inputDriver?.simulated === true,
            "input-error": () => root.inputDriver?.error ?? ""
        },
        targets: {
            "scene": () => root,
            "latest-row": () => popup.targetForNotification(root.newestId),
            "transfer-row": () => popup.targetForNotification(root.transferId),
            "oldest-row": () => {
                const oldest = popup.notificationSurface.displayStack[0];
                return oldest ? popup.targetForNotification(oldest.notificationId) : null;
            },
            "outside": () => outsideTarget
        },
        idle: () => !popup.presentationSettling
            && !notificationModel.live.some(entry => entry.expiryMs > 0 && !entry.paused)
            && !notificationModel.live.some(entry => entry.paused)
    })

    readonly property var controls: [{
        label: "presentation",
        options: [
            { label: "show-transfer", call: "publish-transfer", enabled: () => root.actionAvailable("publish-transfer") },
            { label: "show-review-request", call: "publish-review-request", enabled: () => root.actionAvailable("publish-review-request") },
            { label: "remove-default", call: "replace-review-no-default", enabled: () => root.actionAvailable("replace-review-no-default") },
            { label: "activate-primary", call: "activate-primary", enabled: () => root.actionAvailable("activate-primary") },
            { label: "complete-transfer", call: "replace-transfer", enabled: () => root.actionAvailable("replace-transfer") },
            { label: "show-overflow", call: "publish-overflow", enabled: () => root.actionAvailable("publish-overflow") },
            { label: "dismiss-newest", call: "dismiss-newest", enabled: () => root.actionAvailable("dismiss-newest") },
            { label: "dismiss-all", call: "dismiss-all", enabled: () => root.actionAvailable("dismiss-all") },
            { label: "reset", call: "reset", enabled: () => root.actionAvailable("reset") }
        ]
    }, {
        label: "urgency",
        type: "choice",
        options: [
            { label: "low", checked: () => root.selectedUrgency === "low" },
            { label: "normal", checked: () => root.selectedUrgency === "normal" },
            { label: "critical", checked: () => root.selectedUrgency === "critical" }
        ]
    }, {
        label: "timeout",
        type: "choice",
        options: [
            { label: "urgency-default", checked: () => root.selectedTimeoutMs === -1 },
            { label: "sticky", checked: () => root.selectedTimeoutMs === 0 },
            { label: "250ms-override", checked: () => root.selectedTimeoutMs === 250 },
            { label: "2500ms-override", checked: () => root.selectedTimeoutMs === 2500 }
        ]
    }, {
        label: "policy",
        type: "toggle",
        options: [
            { label: "dnd", checked: () => root.notificationModel.dnd },
            { label: "reduced-motion", checked: () => State.ShellState.reducedMotion }
        ]
    }]

    readonly property var actions: [
        { label: "publish-default", trigger: "publish-default", enabled: () => root.actionAvailable("publish-default") },
        { label: "publish-review-request", trigger: "publish-review-request", enabled: () => root.actionAvailable("publish-review-request") },
        { label: "replace-review-no-default", trigger: "replace-review-no-default", enabled: () => root.actionAvailable("replace-review-no-default") },
        { label: "activate-primary", trigger: "activate-primary", enabled: () => root.actionAvailable("activate-primary") },
        { label: "publish-transfer", trigger: "publish-transfer", enabled: () => root.actionAvailable("publish-transfer") },
        { label: "replace-transfer", trigger: "replace-transfer", enabled: () => root.actionAvailable("replace-transfer") },
        { label: "publish-overflow", trigger: "publish-overflow", enabled: () => root.actionAvailable("publish-overflow") },
        { label: "publish-short", trigger: "publish-short", enabled: () => root.actionAvailable("publish-short") },
        { label: "publish-invalid", trigger: "publish-invalid", enabled: () => root.actionAvailable("publish-invalid") },
        { label: "push-overflow", trigger: "push-overflow", enabled: () => root.actionAvailable("push-overflow") },
        { label: "dismiss-newest", trigger: "dismiss-newest", enabled: () => root.actionAvailable("dismiss-newest") },
        { label: "dismiss-all", trigger: "dismiss-all", enabled: () => root.actionAvailable("dismiss-all") },
        { label: "dismiss-transfer", trigger: "dismiss-transfer", enabled: () => root.actionAvailable("dismiss-transfer") },
        { label: "arrive-during-retract", trigger: "arrive-during-retract", enabled: () => root.actionAvailable("arrive-during-retract") },
        { label: "watch-reset-cancellation", trigger: "watch-reset-cancellation", enabled: () => root.actionAvailable("watch-reset-cancellation") },
        { label: "reset", trigger: "reset", enabled: () => root.actionAvailable("reset") }
    ]

    signal eventRecorded(var record)
    signal inspectionReady(var inspection)

    width: screenRect.width
    height: screenRect.height

    function record(origin: string, kind: string, name: string, payload: var): void {
        if (observing)
            eventRecorded({ origin: origin, kind: kind, name: name, payload: payload });
    }

    function rowFacts(): var {
        return popup.notificationSurface.cardGeometry().map(row => ({
            notificationId: row.notificationId,
            phase: row.phase,
            eligible: row.eligible,
            rect: { x: row.rect.x, y: row.rect.y, width: row.rect.width, height: row.rect.height }
        }));
    }

    function rowIdentity(id: int): string {
        const row = popup.targetForNotification(id);
        return row ? row.objectName : "";
    }

    function retainedCard(): var {
        return popup.targetForNotification(lastDismissedId);
    }

    function retainedHeight(): real {
        const card = retainedCard();
        return card && card.expansionFrozen ? card.frozenHeight : 0;
    }

    function fullscreenMaskIds(): var {
        return Object.keys(border.fullscreenCapsules).filter(id => id.startsWith("notify-row-"));
    }

    // The one statement of which scenario actions this story can run right
    // now. triggerAction refuses whatever it answers false for, and every
    // declared control/action option reads this same predicate.
    function actionAvailable(name: string): bool {
        if (name === "reset" || name === "watch-reset-cancellation")
            return true;
        if (resetPresentationPending)
            return false;
        const live = notificationModel.live;
        // The store replaces only a LIVE id, so a stale transferId would
        // publish a NEW card that still reads as the transfer being completed.
        const transferIsLive = transferId > 0
            && live.some(entry => entry.notificationId === transferId);
        switch (name) {
        case "publish-default":
        case "publish-review-request":
            return notificationService === null;
        case "replace-review-no-default":
            return notificationService === null && transferId > 0 && transferIsLive;
        case "activate-primary":
            return !!popup.targetForNotification(newestId)?.primaryActionAvailable
                && popup.targetForNotification(newestId)?.inputEnabled === true;
        case "publish-transfer":
        case "publish-overflow":
        case "publish-short":
        case "publish-invalid":
        case "push-overflow":
            return true;
        case "replace-transfer":
        case "dismiss-transfer":
            return transferIsLive;
        case "dismiss-newest":
            return notificationModel.popups.length > 0 || live.length > 0;
        case "dismiss-all":
            return live.length > 0;
        case "arrive-during-retract":
            return popup.presentationClosing;
        }
        return false;
    }

    function applyControl(groupIndex: int, optionIndex: int): bool {
        const group = controls[groupIndex];
        const option = group?.options[optionIndex];
        if (!option)
            return false;
        if (group.label === "presentation")
            return triggerAction(actions.findIndex(action => action.trigger === option.call));
        if (group.label === "urgency") {
            selectedUrgency = ["low", "normal", "critical"][optionIndex];
            record("scenario", "control", "applied", { group: "urgency", option: selectedUrgency });
            return true;
        }
        if (group.label === "timeout") {
            selectedTimeoutMs = [-1, 0, 250, 2500][optionIndex];
            record("scenario", "control", "applied", { group: "timeout", option: option.label });
            return true;
        }
        if (group.label === "policy") {
            if (option.label === "dnd") {
                root.dnd = !root.notificationModel.dnd;
                if (root.notificationService)
                    State.ShellState.dnd = root.dnd;
            } else if (option.label === "reduced-motion")
                State.ShellState.reducedMotion = !State.ShellState.reducedMotion;
            else
                return false;
            record("scenario", "control", "applied", { group: "policy", option: option.label,
                checked: option.checked() });
            return true;
        }
        return false;
    }

    function optionsFor(summary: string, replaceId: int): var {
        const options = {
            appName: "Files",
            body: "Copying annual-report.pdf to the Archive drive. The transfer stays available in notification history after this popup closes.",
            urgency: selectedUrgency,
            isTransient: false
        };
        if (selectedTimeoutMs >= 0)
            options.timeoutMs = selectedTimeoutMs;
        if (replaceId > 0)
            options.replaceId = replaceId;
        return options;
    }

    function publish(summary: string, replaceId: int): int {
        if (resetPresentationPending)
            return 0;
        const id = notificationModel.notify(summary, optionsFor(summary, replaceId));
        if (id > 0) {
            newestId = id;
            if (replaceId === 0)
                transferId = id;
        }
        return id;
    }

    function publishReviewRequest(): int {
        if (resetPresentationPending || notificationService !== null)
            return 0;
        const id = notificationStore.addSource({
            appName: "Discord",
            summary: "Alice · #frontend",
            body: "Could you review the new keyboard interaction before it ships? The focus order now follows the conversation and keeps the current message visible. Please check the edge cases when you have a moment; no change is needed if everything reads clearly.",
            urgency: "normal",
            isTransient: false,
            imagePath: "",
            actions: [
                { id: "mark-read", label: "Mark read" },
                { id: "default", label: "Open conversation" }
            ],
            expiryMs: 0
        });
        if (id > 0) {
            newestId = id;
            transferId = id;
        }
        return id;
    }

    function replaceReviewWithoutDefault(): bool {
        if (notificationService !== null || transferId <= 0)
            return false;
        return notificationStore.syncSource(transferId, {
            appName: "Discord",
            summary: "Alice · #frontend",
            body: "Could you review the new keyboard interaction before it ships? The focus order now follows the conversation and keeps the current message visible. Please check the edge cases when you have a moment; no change is needed if everything reads clearly.",
            urgency: "normal",
            isTransient: false,
            imagePath: "",
            actions: [{ id: "mark-read", label: "Mark read" }],
            expiryMs: 0
        });
    }

    function triggerAction(index: int): bool {
        const action = actions[index]?.trigger ?? "";
        // The single gate: the branches below say what an action DOES, never
        // whether it may run.
        if (!actionAvailable(action))
            return false;
        let result = false;
        if (action === "publish-default") {
            const id = notificationModel.notify("Transfer started");
            if (id > 0) {
                newestId = id;
                transferId = id;
                result = true;
            }
        } else if (action === "publish-review-request")
            result = publishReviewRequest() > 0;
        else if (action === "replace-review-no-default")
            result = replaceReviewWithoutDefault();
        else if (action === "activate-primary") {
            const card = popup.targetForNotification(newestId);
            result = !!card && card.activatePrimary();
        } else if (action === "publish-transfer")
            result = publish("Transfer started", 0) > 0;
        else if (action === "replace-transfer") {
            replacementSourceRow = popup.targetForNotification(transferId);
            replacementKeptRow = false;
            const oldCreatedAt = notificationModel.live.find(entry => entry.notificationId === transferId)?.createdAt ?? 0;
            result = publish("Transfer complete", transferId) > 0;
            if (result) {
                Qt.callLater(() => {
                    const updated = popup.targetForNotification(transferId);
                    const entry = notificationModel.live.find(candidate => candidate.notificationId === transferId);
                    replacementKeptRow = !!updated && updated === replacementSourceRow
                        && entry?.createdAt === oldCreatedAt;
                });
            }
        }
        else if (action === "publish-overflow") {
            for (let i = 1; i <= 6; i++) {
                selectedTimeoutMs = 0;
                const id = notificationModel.notify(`Transfer ${i} complete`, {
                    appName: "Files", body: `Archive item ${i} has been copied successfully.`,
                    urgency: "normal", timeoutMs: 0
                });
                if (id <= 0)
                    return false;
                newestId = id;
            }
            result = true;
        } else if (action === "publish-short") {
            const id = notificationModel.notify("Brief update", {
                appName: "Files", body: "This entry expires through its real timer.",
                urgency: "normal", timeoutMs: 250
            });
            if (id > 0) {
                newestId = id;
                transferId = id;
                result = true;
            }
        } else if (action === "push-overflow") {
            const id = notificationModel.notify("Additional transfer complete", {
                appName: "Files", body: "This arrival pushes the oldest visible row out.",
                urgency: "normal", timeoutMs: 0
            });
            if (id > 0) {
                newestId = id;
                result = true;
            }
        } else if (action === "publish-invalid") {
            rejectedField = "";
            rejectedMessage = "";
            result = notificationModel.notify("Invalid urgency", { urgency: "urgent" }) === 0;
        } else if (action === "dismiss-newest") {
            const id = notificationModel.popups[0]?.notificationId
                ?? notificationModel.live[0]?.notificationId ?? 0;
            if (id > 0) {
                lastDismissedId = id;
                dismissedHeight = popup.targetForNotification(id)?.height ?? 0;
                result = notificationModel.dismiss(id);
            }
        } else if (action === "dismiss-all") {
            lastDismissedId = notificationModel.popups[0]?.notificationId ?? 0;
            dismissedHeight = popup.targetForNotification(lastDismissedId)?.height ?? 0;
            result = notificationModel.dismissAll();
        } else if (action === "dismiss-transfer") {
            lastDismissedId = transferId;
            dismissedHeight = popup.targetForNotification(transferId)?.height ?? 0;
            result = notificationModel.dismiss(transferId);
        } else if (action === "arrive-during-retract") {
            result = publish("Transfer resumed during retract", 0) > 0;
        } else if (action === "reset") {
            resetStory();
            result = true;
        } else if (action === "watch-reset-cancellation") {
            expiryCompletionCount = 0;
            resetObservationWindow = false;
            resetObservationTimer.restart();
            result = true;
        }
        if (result)
            record("action", "notification-story", action, {
                notificationId: action.startsWith("dismiss-") ? lastDismissedId : newestId
            });
        return result;
    }

    function resetStory(): void {
        resetObservationTimer.stop();
        observing = false;
        if (inputDriver && typeof inputDriver.cancel === "function")
            inputDriver.cancel();
        resetPresentationPending = notificationService === null
            && popup.presentationVisible;
        if (notificationService === null)
            notificationStore.reset();
        dnd = false;
        State.ShellState.reducedMotion = false;
        selectedUrgency = "normal";
        selectedTimeoutMs = -1;
        transferId = 0;
        newestId = 0;
        lastDismissedId = 0;
        rejectedField = "";
        rejectedMessage = "";
        operationCount = 0;
        primaryIntentCount = 0;
        primaryCallbackCount = 0;
        lastPrimaryId = 0;
        replacementSourceRow = null;
        replacementKeptRow = false;
        dismissedHeight = 0;
        expiryCompletionCount = 0;
        resetObservationWindow = false;
        if (resetPresentationPending)
            Qt.callLater(root.finishResetPresentation);
        else
            Qt.callLater(() => observing = true);
    }

    function finishResetPresentation(): void {
        if (!resetPresentationPending || popup.presentationVisible || rowFacts().length > 0)
            return;
        resetPresentationPending = false;
        Qt.callLater(() => observing = true);
    }

    function dumpTree(): void {
        inspectionReady({ story: "notification-layer", liveIds: notificationModel.live.map(entry => entry.notificationId),
            rowFacts: rowFacts(), fullscreenMaskIds: fullscreenMaskIds(),
            presentation: popup.fullscreen ? "capsule" : "rollout",
            presentationVisible: popup.presentationVisible,
            presentationOpen: popup.presentationOpen,
            presentationClosing: popup.presentationClosing });
    }

    onResetGenerationChanged: resetStory()

    Timer {
        id: resetObservationTimer
        interval: 350
        onTriggered: root.resetObservationWindow = true
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.band
    }

    Rectangle {
        x: Theme.frameThickness
        y: Theme.frameThickness
        width: Math.max(0, root.width - Theme.frameThickness * 2)
        height: Math.max(0, root.height - Theme.frameThickness * 2)
        radius: Theme.frameRadius
        color: Theme.surface

        Column {
            anchors.left: parent.left
            anchors.leftMargin: Theme.space6 * 2
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - Theme.space6 * 4)
            spacing: Theme.space2
            Text {
                text: "Archive drive"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textLg
            }
            Text {
                text: "annual-report.pdf  ·  Copying"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textMd
            }
            Text {
                width: parent.width
                text: root.resetPresentationPending ? "Clearing notifications…"
                    : root.notificationModel.live.length === 0
                        ? "No notifications. Use presentation → show-transfer in Controls."
                    : root.notificationModel.popups.length === 0
                        ? "Do not disturb is hiding these notifications. Uncheck policy → dnd."
                    : "Urgency and timeout apply to the next notification."
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textMd
                wrapMode: Text.WordWrap
            }
        }
    }

    QsmShellComponents.ScenePointer { id: scenePointer }

    QsmShellComponents.ShellBorder {
        id: border
        anchors.fill: parent
        pointer: scenePointer
        fullscreen: root.fullscreen
        leftEdge: Theme.frameThickness
        entryFilter: id => id === "notify-popups" || id.startsWith("notify-row-")
    }

    QtObject {
        id: screenFacts
        readonly property string name: "notification-preview-screen"
        readonly property rect screenRect: root.screenRect
    }

    QtObject {
        id: sceneFacts
        readonly property bool fullscreen: root.fullscreen
        readonly property var contentItem: root
        readonly property bool focusMode: false
    }

    Services.NotificationStore {
        id: notificationStore
        dnd: root.dnd
        invokeSourceAction: (notificationId, actionId) => {
            if (actionId !== "default")
                return false;
            root.primaryCallbackCount++;
            root.record("client", "action-invoked", "default", {
                notificationId: notificationId,
                outcome: "isolated-fixture-callback-only"
            });
            return true;
        }
    }

    Connections {
        target: root.notificationModel
        function onNotifyRejected(field: string, message: string): void {
            root.rejectedField = field;
            root.rejectedMessage = message;
            root.record("service", "notification-store", "rejected", { field: field, message: message });
        }
        function onPublication(notificationId: int, operation: string): void {
            if (root.notificationService && operation === "posted") {
                root.newestId = notificationId;
                if (root.transferId === 0)
                    root.transferId = notificationId;
            }
            if (!root.observing)
                return;
            root.operationCount += 1;
            if (operation === "expired")
                root.expiryCompletionCount += 1;
            root.record("service", "notification-store", "operated", {
                notificationId: notificationId, operation: operation
            });
        }
    }

    Notifications.NotificationPopupStack {
        id: popup
        anchors.fill: parent
        targetScreen: root.targetScreen
        scene: sceneFacts
        host: border
        notificationService: root.notificationModel
        focused: !root.resetPresentationPending
        modal: "none"
        swatchAppName: ""
    }

    Item {
        id: outsideTarget
        x: root.width * 0.72
        y: root.height * 0.8
        width: Theme.iconLg
        height: Theme.iconLg
    }

    Connections {
        target: popup
        function onRowHoverIntent(notificationId: var, hovered: bool): void {
            root.record("component", "notification-card", "hovered", {
                notificationId: notificationId, hovered: hovered
            });
        }
        function onRowDismissIntent(notificationId: var): void {
            root.lastDismissedId = notificationId;
            root.dismissedHeight = popup.targetForNotification(notificationId)?.height ?? 0;
            root.record("component", "notification-card", "dismissed", {
                notificationId: notificationId
            });
        }
        function onRowPrimaryIntent(notificationId: var): void {
            root.primaryIntentCount++;
            root.lastPrimaryId = notificationId;
            root.record("component", "primary-triggered", "default", {
                notificationId: notificationId
            });
        }
    }

    Connections {
        // The SELECTED presentation's own visibility, so reset's wait is
        // driven by the Rollout in normal mode and by the DataCapsule's
        // present (post-fade) in fullscreen.
        target: popup
        function onPresentationVisibleChanged(): void {
            Qt.callLater(root.finishResetPresentation);
        }
    }

    Connections {
        target: popup.notificationSurface
        function onGeometryChanged(): void {
            Qt.callLater(root.finishResetPresentation);
        }
    }

    Component.onCompleted: resetStory()
    Component.onDestruction: {
        observing = false;
        if (notificationService === null)
            notificationStore.reset();
    }
}
