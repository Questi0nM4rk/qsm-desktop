import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.QsmShell.Components as QsmShellComponents
import qs.components
import qs.modules.bar
import qs.modules.cheatsheet
import qs.modules.clipboard
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.osd
import qs.modules.panel
import qs.modules.session
import qs.services
import qs.state
import qs.theme

// The single-scene architecture (adopt-single-scene-rendering, activated
// 3.2): one full-screen window per monitor hosting the frame border, the bar
// rail, and every rollout as plain items in one scene — the previous
// per-window path is gone, so this is the only surface composition.
// The melt mechanism itself — the two registries, the uniform packing, the
// shader — is a hosted ShellBorder (qsm-shell, docs/design-2026-09-06-
// shell-border.md); EdgeScene owns everything Wayland-shaped around it: the
// window, the layer shell, the input mask, fullscreen/focus-mode policy, and
// rail hosting. Every rollout's own composition is a module-owned component
// (OsdSurface, NotificationPopupStack, PanelSurface, LauncherSurface) that
// this file only instantiates thinly.
PanelWindow {
    id: root

    required property var modelData
    readonly property bool fullscreen: FullscreenService.fullscreenFor(modelData)
    readonly property bool focusMode: FocusModeService.focusFor(modelData)
    // Focus mode always reduces its own left edge to the 16px frame. The
    // persisted rail snapshot still decides what returns after focus exits.
    readonly property bool railCollapsed: root.focusMode || ShellState.isRailCollapsed(modelData.name)
    // The "panel" and "session" modals, scoped to whichever monitor is focused.
    readonly property bool panelActive: !root.focusMode && ShellState.modal === "panel"
        && ShellState.focusedScreen === root.modelData
    readonly property bool sessionActive: !root.focusMode && ShellState.modal === "session"
        && ShellState.focusedScreen === root.modelData
    // The "launcher" modal, scoped to whichever monitor is focused.
    readonly property bool launcherActive: !root.focusMode && ShellState.modal === "launcher"
        && ShellState.focusedScreen === root.modelData
    // The "clipboard" modal — same scoping; reachable only by its keybind.
    readonly property bool clipboardActive: !root.focusMode && ShellState.modal === "clipboard"
        && ShellState.focusedScreen === root.modelData
    // The "cheatsheet" modal — same scoping; SUPER + / only.
    readonly property bool cheatSheetActive: !root.focusMode && ShellState.modal === "cheatsheet"
        && ShellState.focusedScreen === root.modelData
    readonly property string launcherDetailId: launcherSurface.detailId
    readonly property string launcherRestoredParentActionId: launcherSurface.restoredParentActionId
    readonly property string launcherQuery: launcherSurface.query
    readonly property int launcherCursor: launcherSurface.selectedIndex
    readonly property string launcherConfirmId: launcherSurface.confirmId
    readonly property var launcherResultLabels: launcherSurface.results.map(item => item.label)
    // Peek is explicit state, not a hover binding: entering the collapsed
    // strip sets it, leaving clears it, and RETRACTING ALWAYS CLEARS IT —
    // the stuck-rail rule.
    property bool railPeeking: false
    readonly property bool railRevealed: !railCollapsed || railPeeking

    onRailCollapsedChanged: railPeeking = false
    onFullscreenChanged: {
        if (fullscreen) {
            // Fullscreen is a boundary for keyboard modals, not a temporary
            // visual suppression: leaving fullscreen must not resurrect one.
            if (ShellState.focusedScreen === root.modelData)
                ShellState.closeModal();
            popoutStack.parentController.dismiss();
        }
    }
    onFocusModeChanged: {
        if (focusMode) {
            railPeeking = false;
            popoutStack.parentController.dismiss();
        }
    }

    // Mask model (design.md decision 2). Rail rect tracks pin/peek/collapse;
    // fullscreen collapses the whole mask to nothing, relocating the same
    // suppression FullscreenService already drove for the previous
    // per-window frame/rail visibility. Exposed as plain readonly properties
    // so tests can assert the numbers without inspecting Quickshell internals.
    readonly property rect railMaskRect: fullscreen
        ? Qt.rect(0, 0, 0, 0)
        : Qt.rect(0, 0, railRevealed ? Theme.reservedLeft : Theme.frameThickness, root.height)

    // Fullscreen keeps only the explicit popup/OSD allowlist in the mask;
    // every other rollout is filtered out even if its closing transition has
    // not yet removed its registration.
    function allowsFocusOverlay(id: string): bool {
        return id === "osd" || id === "notify-popups";
    }

    // ShellBorder.entryFilter (11c gap): the library's registries are not
    // filtered by fullscreen or focus mode — that policy is Wayland-shaped
    // knowledge the mechanism must never hold — so this is where the
    // allowlist above actually applies, to every one of the border's three
    // registries at once. `notify-row-*` is a THIRD id space (the popup
    // stack's per-row fullscreen capsules, never a bulge or mask id) with
    // its own rule: a capsule only ever exists while fullscreen, by
    // construction of what registers one, but the popup stack's own resync
    // runs through Qt.callLater and can leave one behind for a frame after
    // fullscreen already turned off.
    function entryVisible(id: string): bool {
        if (root.allowsFocusOverlay(id))
            return true;
        if (id.startsWith("notify-row-"))
            return root.fullscreen;
        return !root.fullscreen && !root.focusMode;
    }

    // The border's own registries, exposed under EdgeScene's pre-lift names
    // so the IPC status contract (shell.qml) and the mask below need no
    // changes: `border` owns storage and filtering now, this is a plain view.
    //
    // The mask is a UNION of two registries: rollout hit rects always, plus
    // the fullscreen capsules registered as INPUT-ONLY holes (paint: false)
    // while fullscreen. Those holes are per-row eligibility rectangles, so a
    // row's hole is withdrawn the moment it stops being eligible while the
    // DataCapsule still paints the retained column — the mask never covers
    // padding, shadow or a row on its way out. entryFilter has already been
    // applied inside both views, and the fixed slot cap below is shared with
    // the shader's rollout cap, so both stay inside one budget.
    readonly property var rolloutMaskRects: root.fullscreen
        ? border.maskRects.concat(border.fullscreenCapsuleEntries.map(entry => entry.rect))
        : border.maskRects
    readonly property var rolloutMaskIds: Object.keys(border.rolloutRegions)
        .concat(root.fullscreen ? Object.keys(border.fullscreenCapsules) : [])
        .filter(root.entryVisible)
    readonly property var bulgeEntries: border.bulgeEntries
    readonly property var fullscreenCapsuleEntries: border.fullscreenCapsuleEntries
    readonly property var fullscreenCapsules: border.fullscreenCapsules

    // Test seams for the keyboard command-centre contract. They call the live
    // surface, not a duplicate state model, so IPC smoke covers the same
    // parent/detail path used by SearchField.
    function launcherEnterDetail(): bool {
        if (!launcherActive || launcherSurface.results.length === 0)
            return false;
        launcherSurface.activate(launcherSurface.selectedIndex);
        return launcherSurface.inDetail;
    }

    function launcherEnterDetailFor(id: string): bool {
        if (!launcherActive)
            return false;
        const index = launcherSurface.results.findIndex(item => item.data === id);
        if (index < 0)
            return false;
        launcherSurface.resultsListIndexForTest(index);
        launcherSurface.activate(index);
        return launcherSurface.inDetail;
    }

    function launcherActivateControlFor(id: string): bool {
        if (!launcherActive)
            return false;
        const index = launcherSurface.results.findIndex(item => item.data === id);
        if (index < 0)
            return false;
        launcherSurface.resultsListIndexForTest(index);
        launcherSurface.activate(index);
        return true;
    }

    function launcherSetQueryForTest(query: string): bool {
        if (!launcherActive)
            return false;
        launcherSurface.setQueryForTest(query);
        return true;
    }

    function launcherBack(): bool {
        if (!launcherActive || !launcherSurface.inDetail)
            return false;
        launcherSurface.leaveDetail();
        return !launcherSurface.inDetail;
    }

    function launcherActivateDetailFor(id: string): bool {
        if (!launcherActive || !launcherSurface.inDetail)
            return false;
        const index = launcherSurface.results.findIndex(item => item.data === id);
        if (index < 0)
            return false;
        launcherSurface.resultsListIndexForTest(index);
        launcherSurface.activate(index);
        return true;
    }

    // Activate the first result whose confirmId starts with `prefix`, without
    // knowing the exact address. Bluetooth-forget rows use
    // `forget-<address>` as their confirmId, and the address is runtime-
    // specific, so a prefix match is the only stable seam.
    function launcherActivateConfirmPrefix(prefix: string): bool {
        if (!launcherActive || !launcherSurface.inDetail)
            return false;
        const index = launcherSurface.results.findIndex(
            item => (item.confirmId ?? "").startsWith(prefix));
        if (index < 0)
            return false;
        launcherSurface.resultsListIndexForTest(index);
        launcherSurface.activate(index);
        return true;
    }

    // Non-destructive device info seam: returns the label, default status,
    // and data-presence for a device row at the given index, without calling
    // setDefaultSink or setDefaultSource. The `data` field is an object-backed
    // row (the PipeWire device), so this proves the row exists and carries its
    // object without changing real defaults in smoke.
    function launcherDeviceInfoTest(kind: string, index: int): string {
        if (!launcherActive || !launcherSurface.inDetail)
            return "{}";
        const devices = launcherSurface.results.filter(item => item.kind === kind);
        if (index < 0 || index >= devices.length)
            return "{}";
        const device = devices[index];
        return JSON.stringify({
            label: device.label,
            isCurrent: (device.sub ?? "").includes("Current"),
            hasData: device.data !== undefined && device.data !== null
        });
    }

    // Panel tab stepping seam (S2): drives the same stepTab the Left/Right
    // keys call, so smoke covers the keyboard contract's logic without
    // injecting key events.
    function panelTabStepTest(delta: int): bool {
        if (ShellState.modal !== "panel")
            return false;
        return panelSurface.stepTab(delta);
    }

    // Region's "regions" list only accepts declared Region children (a
    // Repeater/Instantiator delegate can't append to it — verified against
    // Quickshell 0.3: assigning a Repeater raises "Cannot assign object of
    // type QQuickRepeater to list property regions"). A fixed slot cap,
    // each bound to one array index, is the supported shape for a dynamic
    // rollout count. 8 matches design.md decision 6's already-declared
    // shader uniform cap for the same rect set, so the mask and the melt
    // shader share one ceiling instead of two invented ones.
    readonly property int maxRolloutMaskSlots: 8

    function rolloutRectAt(index) {
        return index < root.rolloutMaskRects.length ? root.rolloutMaskRects[index] : Qt.rect(0, 0, 0, 0);
    }

    // Every registered silhouette, for measurement. The radii, the blend and
    // the edge bits are SHADER UNIFORMS: they do not appear in the item tree, so
    // without this a defect in any of them can only be argued about from a
    // screenshot. This exists because three attempts at one seam were each
    // debugged by reasoning instead of by reading the numbers. Reads the
    // border's RAW registry (unfiltered): a dump is a debugging tool and must
    // show what is actually registered, not what the shader is currently
    // allowed to paint.
    readonly property var bulgeDump: Object.keys(border.bulgeRegions).map(id => {
        const b = border.bulgeRegions[id];
        return {
            id: id,
            rect: [b.rect.x, b.rect.y, b.rect.width, b.rect.height],
            radius: [b.radius.x, b.radius.y, b.radius.z, b.radius.w],
            blend: b.blend,
            outness: b.outness,
            edgeBits: b.edgeBits
        };
    })

    // Motion trace: bulgeDump above answers "where is it NOW"; a reveal is a
    // time series, and sub-500ms motion cannot be judged from snapshots or
    // screenshots — three wrong fixes shipped in one session for exactly that
    // reason. This records one silhouette's geometry once per frame so a
    // curve's duration, overshoot and settle can be READ as numbers. Sampled
    // against the border's bulgeRegions because that is the exact post-snap
    // data the shader consumes; per component would read pre-snap rects and
    // be a dozen copies of itself. FrameAnimation, not Timer: timer ticks are
    // not frame-locked and would alias the very curve being measured.
    property string traceId: ""
    property var traceSamples: []
    property real traceDurationMs: 0
    // Monotonic within one trace; lets the reader spot a frame the sampler
    // did not get (a gap in `i` is a real finding about the compositor).
    property int traceIndex: 0
    // 600 ≈ 10s at 60Hz. The cap is not tunable generosity: an unbounded
    // array behind a per-frame callback is a leak with no off switch.
    readonly property int maxTraceSamples: 600

    function startTrace(id, durationMs) {
        if (id.length === 0 || durationMs <= 0)
            return false;

        root.traceId = id;
        root.traceDurationMs = durationMs;
        root.traceIndex = 0;
        root.traceSamples = [];
        traceAnim.restart();
        return true;
    }

    function traceResult() {
        return { id: root.traceId, samples: root.traceSamples };
    }

    FrameAnimation {
        id: traceAnim

        onTriggered: root.sampleTrace()
    }

    // An absent id is RECORDED as absent, not skipped: a silhouette
    // unregistering mid-flight (a popout that closed early, a rollout that
    // lost its registration) is exactly the kind of finding this exists for.
    function sampleTrace() {
        const elapsed = Math.round(traceAnim.elapsedTime * 1000);
        if (root.traceSamples.length >= root.maxTraceSamples || elapsed >= root.traceDurationMs) {
            traceAnim.stop();
            return;
        }

        const b = border.bulgeRegions[root.traceId];
        const sample = { i: root.traceIndex, t: elapsed };
        root.traceIndex = root.traceIndex + 1;
        if (b)
            sample.rect = [b.rect.x, b.rect.y, b.rect.width, b.rect.height];
        else
            sample.absent = true;
        root.traceSamples.push(sample);
    }

    // The left frame span follows the rail: collapsed rail = plain border,
    // revealed rail (pinned or peeking) = the full rail band. Peek widens the
    // band OVER the windows below — the exclusion zone (FrameExclusions)
    // tracks only the pin state, never the peek.
    property int leftEdge: railRevealed ? Theme.reservedLeft : Theme.frameThickness
    // The asymmetric 60/16px bands make the physical midpoint the wrong viewport center.
    readonly property real panelCenterX: (leftEdge + width - Theme.frameThickness) / 2

    Behavior on leftEdge {
        NumberAnimation { duration: Motion.normal; easing.type: Motion.emphasizedEasing }
    }

    // An open surface owns its region AND its triggers. A handle hover zone is
    // a discoverability target — "there is something here, pull it out" — and
    // discovery is meaningless while a modal already owns the screen. Worse,
    // the zones sit UNDER the modals: the session column and the OSD share the
    // right edge, so mousing toward a logout button crossed the OSD strip and
    // rolled the brightness bulge out from beneath the buttons the owner was
    // aiming at (owner 2026-08-24). The panel handle already carried this
    // guard inline (audit UX-2); hoisted here it is ONE rule for every handle
    // instead of one rule per handle, remembered or not.
    readonly property bool handlesArmed: ShellState.modal === "none" && !root.fullscreen && !root.focusMode

    screen: modelData
    color: "transparent"
    exclusiveZone: 0
    mask: Region {
        x: root.railMaskRect.x
        y: root.railMaskRect.y
        width: root.railMaskRect.width
        height: root.railMaskRect.height

        Region { readonly property rect r: osdSurface.corridorZone; x: r.x; y: r.y; width: r.width; height: r.height }
        Region { readonly property rect r: osdSurface.capsuleInputRect; x: r.x; y: r.y; width: r.width; height: r.height }
        Region { readonly property rect r: root.panelHandleZone; x: r.x; y: r.y; width: r.width; height: r.height }

        // 8 fixed slots (see maxRolloutMaskSlots above); unused slots are a
        // zero-size rect and contribute nothing to the Combine (union).
        Region { readonly property rect r: root.rolloutRectAt(0); x: r.x; y: r.y; width: r.width; height: r.height }
        Region { readonly property rect r: root.rolloutRectAt(1); x: r.x; y: r.y; width: r.width; height: r.height }
        Region { readonly property rect r: root.rolloutRectAt(2); x: r.x; y: r.y; width: r.width; height: r.height }
        Region { readonly property rect r: root.rolloutRectAt(3); x: r.x; y: r.y; width: r.width; height: r.height }
        Region { readonly property rect r: root.rolloutRectAt(4); x: r.x; y: r.y; width: r.width; height: r.height }
        Region { readonly property rect r: root.rolloutRectAt(5); x: r.x; y: r.y; width: r.width; height: r.height }
        Region { readonly property rect r: root.rolloutRectAt(6); x: r.x; y: r.y; width: r.width; height: r.height }
        Region { readonly property rect r: root.rolloutRectAt(7); x: r.x; y: r.y; width: r.width; height: r.height }
    }
    // The fullscreen allowlist is painted by children that remain visible
    // below. Overlay is required for those items to sit above a fullscreen
    // client; every other shell surface still suppresses itself explicitly.
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    // OnDemand-equivalent: the shared window only claims keyboard focus while
    // one of this monitor's own modals is open. EVERY keyboard-driven modal
    // must be listed — a surface missing from here renders and takes the
    // pointer but never receives a key, so its search field is dead and Escape
    // does nothing (which is exactly how the clipboard rollout first behaved).
    WlrLayershell.keyboardFocus: (root.panelActive || root.launcherActive
        || root.sessionActive || root.clipboardActive || root.cheatSheetActive
        || (ShellState.keyboardGrab.length > 0 && ShellState.focusedScreen === root.modelData))
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qsm-edge-scene"

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    // Pointer-motion tracker: the RELEASE half of
    // ShellState.keyboardOwnsSelection, and the same reader the bar-popout
    // region test below (03-rail "Popouts") asks whether the pointer is
    // inside a rect. A `HoverHandler` is shadowed by stacking order, not
    // shared by it: only the one nearest the pointer along the z-stack is
    // notified. Declared as a SIBLING under the interactive surfaces it
    // never sees the pointer; declared on their ANCESTOR every handler at
    // any depth is told independently. `root` (this `PanelWindow`) IS that
    // ancestor for every surface below, so `ScenePointer` is declared
    // directly on it rather than on an `Item` stacked alongside them.
    QsmShellComponents.ScenePointer {
        id: scenePointer
        onPointChanged: ShellState.keyboardOwnsSelection = false
    }

    // Silhouette suppression is item-level (not window-level): the window
    // itself stays mapped so an in-scene critical popup can still show while
    // this monitor is fullscreen — only the painting hides (ShellBorder's own
    // fullscreenMode uniform, driven by the `fullscreen` binding below).
    //
    // The mechanism itself — both registries, the uniform packing, the melt
    // shader (spec/12-mechanism.md) — is the library's ShellBorder
    // (qsm-shell, docs/design-2026-09-06-shell-border.md); everything bound
    // here is either dynamic Wayland-shaped state the library may never hold
    // (leftEdge, fullscreen) or a consumer-owned handle affordance (handle0,
    // dotsHandle). Every other uniform default (band paint, meltSmoothing,
    // edgeSnapReach, seamOverlap, viewportRadius, edge) resolves through
    // Style.backend, which shell.qml already binds to this Theme — so it
    // already matches without being repeated here.
    QsmShellComponents.ShellBorder {
        id: border
        anchors.fill: parent
        pointer: scenePointer
        leftEdge: root.leftEdge
        fullscreen: root.fullscreen
        entryFilter: root.entryVisible
        handle0: osdHandle.shaderHandle
    }

    // Bar rail + popouts, hosted directly (Rail/RailPopout/PopoutController
    // are already thin module components, not compositions this migration
    // duplicated — nothing to extract here).
    // Exposed so the status IPC can name the open rail rollout: a bulge count
    // proves something opened, not WHICH thing, and that distinction is the
    // whole point of a rollout test.
    readonly property var popoutController: popoutStack.parentController
    readonly property var actionPopoutController: popoutStack.childController
    readonly property var popout: popoutStack.parentPopout
    readonly property var actionPopout: popoutStack.childPopout
    readonly property string openPopoutKind: popoutStack.parentKind
    // The nested host's state, exposed for the same reason as the first: a
    // count proves something is open, not WHICH thing — and with two hosts
    // that can hold each other open, "why is this still up" is unanswerable
    // from the outside without the hover flags that decide it.
    readonly property string openSubPopoutKind: popoutStack.childKind
    // Live readout of the geometric region test below (03-rail "Popouts",
    // RATIFIED 2026-09-07) — exposed for IPC status the same way the old
    // hovered/closing flags were, so a live check can see the decision the
    // rollout is actually being held open (or not) by.
    readonly property bool popoutInRegion: popoutStack.parentHeld
    readonly property bool subPopoutInRegion: popoutStack.childHeld
    // Exposed for the chained-rollout smoke assertion: a child must begin at
    // the parent's settled right edge, never at its animated viewport edge.
    readonly property real popoutSettledRight: popout.x + popout.nonAnimWidth
    readonly property real subPopoutOriginX: actionPopout.x
    readonly property real subPopoutTop: actionPopout.y
    readonly property real subPopoutHeight: actionPopout.height

    readonly property rect popout1Rect: popoutStack.parentRect
    readonly property rect popout2Rect: popoutStack.childRect

    readonly property bool inPopout1Region: popoutStack.parentHeld
    readonly property bool inPopout2Region: popoutStack.childHeld

    // Hover authority for the collapsed-rail peek reveal. Width matches the
    // rail strip, or rail+gap+popout once a popout is open. The HoverHandler
    // MUST sit on an ANCESTOR of Rail and
    // RailPopout — hover consumed by an entry's MouseArea keeps an ancestor
    // hovered, while a sibling stacked underneath receives a leave, which
    // flapped railPeeking and made the rail show/hide jitter under the
    // cursor (checkpoint 3.1 finding).
    Item {
        id: railHoverZone
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        // Must reach the FAR edge of whatever is open, level two included:
        // this is the ancestor that keeps the rail peeked, and a zone ending
        // short of the detail card would report a leave the moment the pointer
        // entered it.
        width: popoutController.active
            ? Theme.reservedLeft + popout.width + actionPopout.width
            : root.railRevealed ? Theme.reservedLeft : Theme.frameThickness

        HoverHandler {
            id: contentHover
            onHoveredChanged: {
                if (!root.fullscreen && !root.focusMode && root.railCollapsed)
                    root.railPeeking = contentHover.hovered;
            }
        }

        Rail {
            id: rail
            visible: root.railRevealed && !root.fullscreen && !root.focusMode
            // 08: while the session surface is open EVERYTHING else fades
            // back — only the rolled-out buttons stay in focus. The blur
            // backdrop dims the desktop and the windows, but the rail lives
            // in the SAME scene as the session buttons and therefore sits
            // above that backdrop; without this it stayed at full strength
            // over a dimmed desktop, which read as the rail being the thing
            // in focus.
            opacity: root.sessionActive ? 0.35 : 1

            Behavior on opacity {
                NumberAnimation { duration: Motion.normal; easing.type: Motion.standardEasing }
            }
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            // Center the rail column in the 60px left band (01-frame): the
            // band is thicker than frameThickness, so the old
            // frameThickness margin pushed the column toward screen center.
            anchors.leftMargin: (Theme.reservedLeft - Theme.railWidth) / 2
            width: Theme.railWidth
            screen: root.modelData
            popouts: popoutController
        }

        RailPopoutStack {
            id: popoutStack
            anchors.fill: parent
            host: border
            hostBandArea: root.railMaskRect
            keyboardRetained: ShellState.keyboardGrab.length > 0
            suppressed: root.fullscreen || root.focusMode
        }
    }

    // The bar-popout HIT strip: the popout card(s) themselves, plus the
    // level-2 card's width when it is open (the nested Rollout clamps its
    // free axis inside level 1, so level 1's height covers both).
    // The rail band is NOT re-added here — it is already permanently in the
    // mask via railMaskRect — so this id only ever needs to reach the card.
    //
    // ACCEPTED COST (03-rail "Popouts", RATIFIED 2026-09-07): this used to be
    // the full-height strip from the screen edge through the popout, which
    // made the whole column below/above the card solid whenever any popout
    // was open. Registering only the card's own bounding box instead means
    // the strip above/below a short card is click-through again while the
    // card is open — narrower than before, and the exact cost the spec names
    // (the travel-triangle bounding box, not the whole column, stops being
    // click-through). The popout's silhouette bulge is self-registered by
    // BarPopouts; this strip uses a DISTINCT id.
    readonly property real popoutMaskRight: actionPopoutController.active
        ? root.popout2Rect.x + root.popout2Rect.width
        : root.popout1Rect.x + root.popout1Rect.width
    readonly property rect popoutMaskRect: popoutController.active && !root.fullscreen && !root.focusMode
        ? Qt.rect(root.popout1Rect.x, root.popout1Rect.y,
            root.popoutMaskRight - root.popout1Rect.x, root.popout1Rect.height)
        : Qt.rect(0, 0, 0, 0)

    onPopoutMaskRectChanged: {
        if (popoutMaskRect.width > 0 && popoutMaskRect.height > 0)
            border.registerRolloutRegion("bar-popout-strip", popoutMaskRect);
        else
            border.unregisterRolloutRegion("bar-popout-strip");
    }

    // Module surfaces, unified on the Rollout mechanism: each owns its
    // composition and registers its own silhouette + hit rects through its
    // Rollout. `scene` is this window (modelData, focusMode, fullscreen);
    // `host` is the ShellBorder answering the library's seven-call contract —
    // EdgeScene only instantiates and hands over both refs.
    OsdSurface {
        id: osdSurface
        targetScreen: root.modelData
        scene: root
        host: border
    }

    OsdHandle {
        id: osdHandle
        surface: osdSurface
        scene: root
    }

    NotificationPopupStack {
        id: popupStack
        targetScreen: root.modelData
        scene: root
        host: border
        notificationService: NotificationService
        focused: ShellState.focusedScreen === root.modelData
        modal: ShellState.modal
        swatchAppName: ColorPickService.notifyAppName
    }

    // Top panel: full-scene click-outside catch (declared FIRST so the
    // panel's own content stays clickable above it), then the surface.
    MouseArea {
        anchors.fill: parent
        enabled: !root.fullscreen && !root.focusMode && (root.panelActive || panelSurface.revealed)
        visible: enabled
        onClicked: ShellState.closeModal()
    }

    PanelSurface {
        id: panelSurface
        targetScreen: root.modelData
        scene: root
        host: border
    }

    readonly property rect panelMaskRect: (root.panelActive || panelSurface.revealed)
        ? Qt.rect(0, 0, root.width, root.height)
        : Qt.rect(0, 0, 0, 0)

    onPanelMaskRectChanged: {
        if (panelMaskRect.width > 0 && panelMaskRect.height > 0)
            border.registerRolloutRegion("panel-catch", panelMaskRect);
        else
            border.unregisterRolloutRegion("panel-catch");
    }

    // Session: full-scene click-outside catch + the surface (08).
    MouseArea {
        anchors.fill: parent
        enabled: !root.fullscreen && !root.focusMode && (root.sessionActive || sessionSurface.revealed)
        visible: enabled
        onClicked: ShellState.closeModal()
    }

    SessionSurface {
        id: sessionSurface
        targetScreen: root.modelData
        scene: root
        host: border
    }

    readonly property rect sessionMaskRect: (root.sessionActive || sessionSurface.revealed)
        ? Qt.rect(0, 0, root.width, root.height)
        : Qt.rect(0, 0, 0, 0)

    onSessionMaskRectChanged: {
        if (sessionMaskRect.width > 0 && sessionMaskRect.height > 0)
            border.registerRolloutRegion("session-catch", sessionMaskRect);
        else
            border.unregisterRolloutRegion("session-catch");
    }

    // The screen-top discovery zone remains parked while the reading rides
    // the panel rim. Both are mask-active so neither becomes click-through.
    readonly property rect panelHandleZone: fullscreen || focusMode
        ? Qt.rect(0, 0, 0, 0)
        : Qt.rect(root.panelCenterX - panelHandle.width / 2, 0,
            panelHandle.width, Theme.frameThickness + Theme.panelHandleHeight / 2 + Theme.panelHandleProud)

    PanelHandle {
        id: panelHandle
        host: border
        visible: !root.fullscreen && !root.focusMode
        width: implicitWidth
        height: implicitHeight
        x: root.panelCenterX - width / 2
        y: panelSurface.leadingEdgeY - height / 2 + Theme.panelHandleProud
        onActivated: ShellState.togglePanel("dashboard")
        readonly property rect hitRect: visible ? Qt.rect(x, y, width, height) : Qt.rect(0, 0, 0, 0)
        onHitRectChanged: {
            if (visible) border.registerRolloutRegion("panel-handle", hitRect);
            else border.unregisterRolloutRegion("panel-handle");
        }
    }

    Item {
        readonly property rect r: root.panelHandleZone
        x: r.x; y: r.y; width: r.width; height: r.height

        HoverHandler {
            id: panelHandleHover
            onHoveredChanged: {
                if (hovered && !root.fullscreen && !root.focusMode)
                    panelIntentTimer.restart();
                else
                    panelIntentTimer.stop();
            }
        }

        Timer {
            id: panelIntentTimer
            interval: 150
            onTriggered: {
                // Only from a CLEAN desktop. Hover intent is not a deliberate
                // act, and it used to fire over any open modal — mousing
                // toward the cheat sheet's own search field crossed this zone
                // and silently swapped the sheet for the panel (audit UX-2).
                // `handlesArmed` is that rule, now shared with the OSD handle.
                if (panelHandleHover.hovered && root.handlesArmed)
                    ShellState.togglePanel("dashboard");
            }
        }
    }

    // The keyboard modals ride ModalHost (click-catch + Rollout + open()
    // re-fire + catch-region registration — see the component). Declared
    // LAST so the full-scene catch wins z-order over the rail.
    //
    // Launcher: bottom-center; the body follows the visible result count
    // (owner 2026-08-21) with a plain transform morph; the >theme carousel
    // keeps the full height — cards, not rows. 07 RATIFIED numbers: width
    // 600, max 7 rows of 57px + the search field.
    ModalHost {
        scene: root
        host: border
        name: "launcher"
        edges: ["bottom"]
        bodyWidth: Theme.launcherWidth
        bodyHeight: Math.min(
            launcherSurface.preferredBodyHeight,
            root.height - Theme.space6 * 2)
        onOpened: launcherSurface.open()

        LauncherSurface {
            id: launcherSurface
            anchors.fill: parent
        }
    }

    // Clipboard: the same host scaffolding as the launcher — a full-scene
    // click-catch so clicking anywhere dismisses, and a Rollout that registers
    // only its silhouette. It descends from the TOP band at the LEFT (owner
    // 2026-08-20), so it corner-joins the rail as well as the top border, and
    // it starts beside the rail rather than under it.
    ModalHost {
        scene: root
        host: border
        name: "clipboard"
        edges: ["top", "left"]
        bodyWidth: Theme.clipboardWidth
        bodyHeight: Math.min(
            Theme.clipboardMaxRows * Theme.clipboardRowHeight
                + (Theme.clipboardMaxRows - 1) * Theme.space1
                + Theme.controlHeight + Theme.space3 + Theme.space4 * 2,
            root.height - Theme.space6 * 2)
        onOpened: clipboardSurface.open()

        ClipboardSurface {
            id: clipboardSurface
            anchors.fill: parent
        }
    }

    // Cheat sheet: top-CENTER — a reference card, not a workflow surface, so
    // it takes the one top-band position no other modal descends from.
    ModalHost {
        scene: root
        host: border
        name: "cheatsheet"
        edges: ["top"]
        bodyWidth: Theme.cheatSheetWidth
        bodyHeight: root.height - Theme.space6 * 4
        onOpened: cheatSheetSurface.open()

        CheatSheetSurface {
            id: cheatSheetSurface
            anchors.fill: parent
        }
    }

    // Test-only IPC seam (notifyTest style, shell.qml's railPopoutTest):
    // drives the real PopoutController.show/dismiss path so the smoke suite
    // can prove the rollout rect joins/leaves the live mask without
    // synthesizing a pointer hover.
    function testTogglePopout(open) {
        if (open)
            popoutController.show("test", rail, "Test", "Smoke test popout", null);
        else
            popoutController.dismiss();
    }

    // testTogglePopout's generalisation (shell.qml's popoutTest): any tier on
    // either host, pointer-free. Level 1 is the rail popout host, level 2 the
    // nested quick-actions detail host; the tiers themselves are BarPopouts
    // names ("sound", "actions", "nightlight", ...). The anchor is always
    // `rail` because it is the only item guaranteed to exist — show() only maps
    // its center for clamping.
    //
    // LEVEL 2 OPENS LEVEL 1 FIRST, and that is not politeness. A level-2 tier
    // is always a quick-action detail card, so the `actions` column IS its only
    // real parent. Opened alone, the child has no parent span to attach to, so
    // the seam would be a synthetic state rather than the one users reach.
    //
    // Close goes through dismiss(), not by faking a hover leave: dismissing
    // level 2 alone just clears its own kind (the region test above has
    // nothing left to hold open once `active` is false), and dismissing
    // level 1 cascades to its child via popoutController's onKindChanged —
    // both are the controller's own retirement paths, so this seam invents
    // none.
    function testShowPopout(kind, level, open) {
        let controller = null;
        if (level === 1)
            controller = popoutController;
        else if (level === 2)
            controller = actionPopoutController;
        if (!controller || kind.length === 0)
            return false;

        if (open) {
            if (level === 2 && !popoutController.active)
                popoutController.show("actions", rail, "Quick actions", "", null);
            controller.show(kind, rail, "Test", "Opened over IPC", null);
        } else {
            controller.dismiss();
        }
        return true;
    }

    // Phase 2 gate rollouts: one Rollout per edge, driven over IPC
    // (rolloutTest), proving reveal choreography, live-rect registries,
    // the near-settled hit law, flush attachment, and corner auto-join
    // (the bottom rollout sits near the left band on purpose). Removed
    // when real surfaces cover all four edges.
    property var testRollouts: ({})

    function testToggleRollout(edge, open) {
        if (!["top", "bottom", "left", "right"].includes(edge))
            return false;

        const next = Object.assign({}, testRollouts);
        next[edge] = open;
        testRollouts = next;
        return true;
    }

    QsmShellComponents.Rollout {
        id: topRollout
        host: border
        rolloutId: "test-top"
        edges: ["top"]
        tier: "large"
        shouldBeActive: root.testRollouts["top"] ?? false
        suppressed: root.fullscreen
        bodyWidth: 340; bodyHeight: 220
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        // Centred in the whole shape, band included -- these surfaces exist
        // to show the mechanism, so they must not display the defect it fixes.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: topRollout.contentCenterOffsetX
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: topRollout.contentCenterOffsetY
            text: "top rollout"
            color: Theme.text
            font.family: Theme.fontFamily
        }
    }

    QsmShellComponents.Rollout {
        id: bottomRollout
        host: border
        rolloutId: "test-bottom"
        edges: ["bottom"]
        tier: "large"
        shouldBeActive: root.testRollouts["bottom"] ?? false
        suppressed: root.fullscreen
        bodyWidth: 300; bodyHeight: 200
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        // 10px off the left band's inner wall — inside melt reach, so the
        // corner auto-join arc to the second band segment must appear.
        anchors.leftMargin: 70

        // Centred in the whole shape, band included -- these surfaces exist
        // to show the mechanism, so they must not display the defect it fixes.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: bottomRollout.contentCenterOffsetX
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: bottomRollout.contentCenterOffsetY
            text: "bottom rollout"
            color: Theme.text
            font.family: Theme.fontFamily
        }
    }

    QsmShellComponents.Rollout {
        id: rightRollout
        host: border
        rolloutId: "test-right"
        edges: ["right"]
        tier: "small"
        shouldBeActive: root.testRollouts["right"] ?? false
        suppressed: root.fullscreen
        bodyWidth: 220; bodyHeight: 300
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        // Centred in the whole shape, band included -- these surfaces exist
        // to show the mechanism, so they must not display the defect it fixes.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: rightRollout.contentCenterOffsetX
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: rightRollout.contentCenterOffsetY
            text: "right rollout"
            color: Theme.text
            font.family: Theme.fontFamily
        }
    }

    QsmShellComponents.Rollout {
        id: leftRollout
        host: border
        rolloutId: "test-left"
        edges: ["left"]
        tier: "small"
        shouldBeActive: root.testRollouts["left"] ?? false
        suppressed: root.fullscreen
        bodyWidth: 220; bodyHeight: 260
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        // Centred in the whole shape, band included -- these surfaces exist
        // to show the mechanism, so they must not display the defect it fixes.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: leftRollout.contentCenterOffsetX
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: leftRollout.contentCenterOffsetY
            text: "left rollout"
            color: Theme.text
            font.family: Theme.fontFamily
        }
    }
}
