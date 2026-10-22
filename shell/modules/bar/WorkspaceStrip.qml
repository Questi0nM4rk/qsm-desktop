pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import qs.components
import qs.services
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.theme

// The workspace strip (03): a drum of all ten workspaces around one fixed
// lens. The lens is the library's accent pill with the real number in
// textOnPrimary; the other workspaces are plain small dots in ring order (10
// wraps to 1) that shrink, fade and haze toward both ends, the last ones
// almost gone. A dot's SHAPE is its state: an empty workspace an outline, one
// with windows a filled dot, an urgent one a danger dot in a ring. On a switch
// the ring scrolls the shortest way round until the new workspace sits in the
// lens; the lens never travels. The lens stretches DOWN into one long capsule:
// the number at its top, the workspace's window icons fading in below it. That
// capsule hangs over the dots below the lens, which stay where they are, so
// the strip never changes size. Three icons show at once; with more windows
// the list is a ring buffer that follows the focused window (the middle icon)
// and that the wheel may also turn. An empty workspace is the number only. A
// switch settles in about 210 ms; under reduced motion it lands at once.
// Wheel switches, click jumps.
Item {
    id: root

    property var popouts: null

    // Every rail renders the identical column of ALL workspaces, active =
    // the globally focused one (03).

    // The globally focused workspace via the focused monitor — the same notify chain ShellState and
    // the pre-reel widget already rely on. (When testing
    // switches from a script on this Lua-dispatch Hyprland, use
    // `hl.dsp.focus({ workspace = "N" })`; plain `hyprctl dispatch workspace N`
    // errors and no-ops, which reads exactly like a stale binding — bit us.)
    readonly property int activeWorkspaceId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1
    readonly property int slotCount: Theme.railWorkspaceSlots
    // A workspace past the last dot keeps the lens on the last dot, and the
    // lens names the real number; a special workspace (a negative id) is none
    // of the dots, so no lens shows.
    readonly property bool hasActive: activeWorkspaceId > 0
    readonly property int activeIndex: Math.max(0, Math.min(slotCount - 1, activeWorkspaceId - 1))

    function workspaceFor(id: int): var {
        return Hyprland.workspaces.values.find(workspace => workspace.id === id) ?? null;
    }

    // The windows of the active workspace, and how the rollout shows them: at
    // most three rows, and past three a ring that has no ends.
    readonly property var apps: workspaceFor(activeWorkspaceId)?.toplevels?.values ?? []
    readonly property int visibleRows: 3

    function activate(id: int): void {
        const workspace = workspaceFor(id);
        if (workspace) {
            workspace.activate();
            return;
        }

        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ workspace = "${id}" })`
            : `workspace ${id}`);
    }

    function moveRelative(delta: int): void {
        activate(Math.max(1, Math.min(slotCount, activeWorkspaceId + delta)));
    }

    // The dot the pointer is over, so the lens, which is not inside any dot's
    // layer, answers hover and press like the dots do.
    property int hoveredIndex: -1
    property int pressedIndex: -1
    readonly property var activeSlot: slots.count > root.activeIndex
        ? slots.itemAt(root.activeIndex) : null
    readonly property real chipGrowth: root.hoveredIndex === root.activeIndex
        ? (root.activeSlot?.growth ?? 0) : 0

    // What the lens holds. It is a snapshot taken when the new workspace
    // arrives, so the old capsule empties out before the number changes.
    readonly property int bodyInset: QsmShellStyle.Style.space1
    property int shownIndex: 0
    property int shownWorkspace: 1
    property var shownApps: []
    readonly property int shownCount: shownApps.length
    readonly property bool ring: shownCount > visibleRows
    readonly property int shownRows: Math.min(visibleRows, shownCount)
    function bodyHeight(count: int): real {
        return count === 0 ? 0 : Math.min(visibleRows, count) * Theme.railCellHeight
            + 2 * bodyInset;
    }
    readonly property real targetHeight: hasActive ? bodyHeight(apps.length) : 0

    // The two animated quantities: where the ring is (in dots, unbounded, the
    // index of the dot in the lens) and how far the lens has stretched below
    // its resting height.
    property real drumPos: 0
    property int drumTarget: 0
    property real rolloutHeight: 0
    // The icons fade in as the capsule opens.
    readonly property real revealed: bodyHeight(shownCount) > 0
        ? Math.min(1, rolloutHeight / bodyHeight(shownCount)) : 0

    // The ring buffer: the position (in rows) of the first visible icon.
    property int ringTarget: 0
    property real ringPos: 0

    // The strip takes all the room its host gives it. The lens sits in the
    // middle of it and the ring spreads over the whole height: the dot four
    // places from the lens (the last that can be seen) has its target flush
    // against either end, so the pitch follows the room. The lens centre is
    // fixed, and the rollout hangs over the dots below it without moving them.
    readonly property real lensCentre: height / 2
    readonly property real pitch: Math.max(Theme.railDrumHit,
        QsmShellStyle.Style.snap((height - Theme.railDrumHit) / 8, root))

    // The lens with its rollout is one block and the block is centred in the
    // capsule: the number rises as the icons open below it. The dots stay put.
    readonly property real lensTop: QsmShellStyle.Style.snap(
        lensCentre - (Theme.railWorkspaceChipHeight + rolloutHeight) / 2, root)

    implicitWidth: Theme.railWidth

    // A table read at a distance in dots, linear between the stops.
    function atDistance(table: var, distance: real): real {
        const d = Math.max(0, Math.min(table.length - 1, distance));
        const i = Math.min(table.length - 2, Math.floor(d));
        return table[i] + (table[i + 1] - table[i]) * (d - i);
    }

    // Where the dot of workspace `index` is on the ring: its signed distance
    // from the lens in dots, wrapped into [-5, 5) so the dot that leaves at one
    // end comes back at the other, where it cannot be seen.
    function ringOffset(index: int): real {
        const half = slotCount / 2;
        const shifted = index - drumPos + half;
        return shifted - slotCount * Math.floor(shifted / slotCount) - half;
    }

    function land(): void {
        shownIndex = activeIndex;
        shownWorkspace = activeWorkspaceId;
        shownApps = apps;
        ringTarget = 0;
        ringPos = 0;
        if (ring && focusedIndex >= 0) {
            ringTarget = followTarget();
            ringPos = ringTarget;
        }
    }

    // The ring follows the focused window: it is the middle icon, the shortest
    // way round. The wheel may turn the ring away; focus moving again follows.
    readonly property int focusedIndex: shownApps.findIndex(app => app.activated)
    function followTarget(): int {
        const want = (((focusedIndex - 1) % shownCount) + shownCount) % shownCount;
        let delta = (((want - ringTarget) % shownCount) + shownCount) % shownCount;
        if (delta > shownCount / 2)
            delta -= shownCount;
        return ringTarget + delta;
    }
    onFocusedIndexChanged: {
        if (ring && focusedIndex >= 0 && shownIndex === activeIndex)
            turnRing(followTarget() - ringTarget);
    }

    // The ring turns the shortest way round: a distance of five either way is
    // the same, and turns down.
    function shortestWay(delta: int): int {
        const wrapped = ((delta % slotCount) + slotCount) % slotCount;
        return wrapped > slotCount / 2 ? wrapped - slotCount : wrapped;
    }

    // The active workspace changed: the three phases of a switch.
    function retarget(): void {
        switchAnim.stop();
        resizeAnim.stop();
        drumTarget += shortestWay(activeIndex - drumTarget);
        if (QsmShellStyle.Style.reducedMotion) {
            land();
            drumPos = drumTarget;
            rolloutHeight = targetHeight;
        } else {
            switchAnim.start();
        }
    }

    // The windows of the active workspace changed: only the rollout resizes. A
    // switch still under way takes the windows when its lens lands.
    function refit(): void {
        if (shownIndex !== activeIndex)
            return;
        shownWorkspace = activeWorkspaceId;
        shownApps = apps;
        resizeAnim.stop();
        if (QsmShellStyle.Style.reducedMotion)
            rolloutHeight = targetHeight;
        else
            resizeAnim.start();
    }

    // Deferred one turn: the animations' targets are bindings on the same
    // properties, and read inside the change handler they can still be stale.
    onActiveIndexChanged: Qt.callLater(retarget)
    onHasActiveChanged: Qt.callLater(retarget)
    onAppsChanged: Qt.callLater(refit)
    onActiveWorkspaceIdChanged: Qt.callLater(refit)
    Component.onCompleted: {
        land();
        drumTarget = activeIndex;
        drumPos = activeIndex;
        rolloutHeight = targetHeight;
    }

    ParallelAnimation {
        id: switchAnim

        NumberAnimation {
            target: root; property: "drumPos"; to: root.drumTarget
            duration: QsmShellStyle.Motion.micro; easing.type: QsmShellStyle.Motion.standardEasing
            // The ring has no ends: bring both numbers back into one turn once at rest.
            onFinished: {
                const wrapped = ((root.drumTarget % root.slotCount) + root.slotCount) % root.slotCount;
                root.drumPos = wrapped;
                root.drumTarget = wrapped;
            }
        }
        SequentialAnimation {
            NumberAnimation {
                target: root; property: "rolloutHeight"; to: 0
                duration: root.rolloutHeight > 0 ? QsmShellStyle.Motion.press : 0
                easing.type: QsmShellStyle.Motion.standardEasing
            }
            ScriptAction {
                script: {
                    root.land();
                    resizeAnim.restart();
                }
            }
        }
    }

    NumberAnimation {
        id: resizeAnim
        target: root; property: "rolloutHeight"; to: root.targetHeight
        duration: QsmShellStyle.Motion.micro; easing.type: QsmShellStyle.Motion.standardEasing
    }

    NumberAnimation {
        id: ringAnim
        target: root; property: "ringPos"; to: root.ringTarget
        duration: QsmShellStyle.Motion.micro; easing.type: QsmShellStyle.Motion.standardEasing
        // The ring has no ends: bring both numbers back near zero once at rest.
        onFinished: {
            const wrapped = ((root.ringTarget % root.shownCount) + root.shownCount) % root.shownCount;
            root.ringPos = wrapped;
            root.ringTarget = wrapped;
        }
    }

    function turnRing(delta: int): void {
        ringAnim.stop();
        ringTarget += delta;
        if (QsmShellStyle.Style.reducedMotion)
            ringPos = ringTarget;
        else
            ringAnim.start();
    }

    // The wheel over the rollout turns its ring; anywhere else on the strip it
    // moves the workspace. `y` is in the strip's own coordinates.
    function wheel(y: real, deltaY: real): void {
        const over = y >= bodyBox.y && y < bodyBox.y + bodyBox.height;
        if (over && ring)
            turnRing(deltaY > 0 ? -1 : 1);
        else if (!over)
            moveRelative(deltaY > 0 ? -1 : 1);
    }

    // The capsule every rail item is, in a body sunk darker than the band, under the dots
    // (they stack at z 0 and below).
    Rectangle {
        id: capsule

        z: -root.slotCount - 1
        width: Theme.railWidth
        height: parent.height
        x: QsmShellStyle.Style.snap((parent.width - width) / 2, capsule)
        radius: QsmShellStyle.Style.radiusPill
        // Darker than the band so the body sinks into it instead of lifting off.
        color: Qt.darker(QsmShellStyle.Style.band, 1.4)
        Accessible.ignored: true
    }

    // The lens: a pill with the number, stretched down into a long capsule
    // while the workspace has windows. It sits at the strip's centre and under
    // the dots' layers, which paint nothing but their hover tint.
    Rectangle {
        id: chip

        readonly property real grown: root.chipGrowth
        width: Theme.railWorkspaceChipWidth + 2 * grown
        height: Theme.railWorkspaceChipHeight + root.rolloutHeight + 2 * grown
        x: QsmShellStyle.Style.snap((parent.width - width) / 2, chip)
        y: root.lensTop - grown
        radius: QsmShellStyle.Style.radiusPill
        visible: root.hasActive
        color: QsmShellStyle.Style.tone(Theme.accent, root.hoveredIndex === root.activeIndex,
            root.pressedIndex === root.activeIndex, false, true, Theme.accent)
        Accessible.ignored: true

        QsmShellComponents.Prose {
            y: chip.grown
            width: parent.width
            height: Theme.railWorkspaceChipHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            role: "reading"
            color: QsmShellStyle.Style.textOnPrimary
            text: String(root.shownWorkspace)
        }
    }


    // The stretched part of the lens hangs over the dots below it, so it also
    // keeps the pointer from reaching them through the gaps between its rows.
    MouseArea {
        x: chip.x
        y: chip.y + chip.grown + Theme.railWorkspaceChipHeight
        width: chip.width
        height: root.rolloutHeight
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        visible: height > 0
    }

    // The icons hang below the number inside the lens, clipped to the lens's
    // stretched height.
    Item {
        id: bodyBox

        x: QsmShellStyle.Style.snap((parent.width - width) / 2, bodyBox)
        y: root.lensTop
            + (Theme.railWorkspaceSlot + Theme.railWorkspaceChipHeight) / 2
        width: Theme.railWorkspaceChipWidth
        height: Math.max(0, root.rolloutHeight - root.bodyInset)
        clip: true
        visible: height > 0

        // Three rows, or five while a ring turns (one above and one below the
        // window), each at its own offset from the ring position.
        Item {
            id: viewport

            width: parent.width
            height: root.shownRows * Theme.railCellHeight
            clip: true
            opacity: root.revealed

            Repeater {
                model: root.ring ? root.visibleRows + 2 : root.shownRows

                Item {
                    id: appRow

                    required property int index
                    readonly property int offset: root.ring ? index - 1 : index
                    readonly property real base: Math.floor(root.ringPos)
                    readonly property var modelData: root.shownCount === 0 ? null
                        : root.shownApps[root.ring
                            ? (((base + offset) % root.shownCount) + root.shownCount) % root.shownCount
                            : offset] ?? null
                    // lastIpcObject stays empty on unfocused monitors, so the
                    // shared clients service is the reliable class and title source.
                    readonly property var info: modelData
                        ? (HyprClientsService.infoFor(modelData.address) ?? modelData.lastIpcObject) : null
                    readonly property string appClass: info?.class ?? ""
                    readonly property string appIdentity: appClass.split(".").pop() || "app"
                    readonly property string appContext: {
                        // Unread counters ("(2864) Video") read as a bare number and the
                        // brand suffix after a dash repeats the class: both drop.
                        const raw = modelData?.title || info?.title || appClass || "";
                        const title = String(raw).replace(/^\(\d+\)\s*/, "");
                        const parts = title.split(/\s+[-–—|·]\s+/);
                        const context = (parts.length > 1 ? parts[0] : title).trim();
                        return context.toLowerCase() === appIdentity.toLowerCase() ? "" : context;
                    }
                    readonly property bool current: modelData?.activated ?? false
                    readonly property bool open: root.popouts !== null
                        && root.popouts.kind === "app" && root.popouts.anchor === appRow

                    function focusWindow(): void {
                        if (modelData)
                            HyprClientsService.focus(modelData.address);
                    }

                    // The controller snapshots title and detail when the popout
                    // opens, and a title keeps changing under a resting pointer.
                    onAppContextChanged: {
                        if (open)
                            root.popouts.detail = appContext;
                    }
                    onAppIdentityChanged: {
                        if (open)
                            root.popouts.title = appIdentity;
                    }

                    y: (offset - (root.ring ? root.ringPos - base : 0)) * Theme.railCellHeight
                    width: parent.width
                    height: Theme.railCellHeight
                    visible: modelData !== null

                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: appIdentity
                    Accessible.description: appContext
                    Accessible.onPressAction: focusWindow()
                    Keys.onReturnPressed: focusWindow()
                    Keys.onEnterPressed: focusWindow()
                    Keys.onSpacePressed: focusWindow()
                    onActiveFocusChanged: {
                        if (activeFocus)
                            root.popouts?.show("app", appRow, appIdentity, appContext, null);
                    }

                    // The focused window is a state, not a hover. The row is
                    // clipped by the viewport, so it recolours and never grows.
                    Rectangle {
                        anchors.fill: parent
                        radius: QsmShellStyle.Style.radiusPill
                        color: Qt.rgba(QsmShellStyle.Style.textOnPrimary.r, QsmShellStyle.Style.textOnPrimary.g,
                            QsmShellStyle.Style.textOnPrimary.b, QsmShellStyle.Style.opacitySelected)
                        visible: appRow.current
                    }

                    // Hover authority sits on the row, an ancestor of the icon.
                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered)
                                root.popouts?.show("app", appRow, appRow.appIdentity, appRow.appContext, null);
                        }
                    }

                    AppIcon {
                        anchors.centerIn: parent
                        implicitSize: Theme.railMark
                        icon: appRow.appClass
                        opacity: appRow.current ? 1 : QsmShellStyle.Style.opacityRecede
                    }

                    QsmShellComponents.StateLayer {
                        id: rowLayer
                        anchors.fill: parent
                        growthCap: 0
                        focused: appRow.activeFocus
                        focusRadius: QsmShellStyle.Style.radiusPill
                        onClicked: appRow.focusWindow()
                    }
                }
            }
        }
    }

    // The ring of dots, nearest drawn on top. Each is one pointer target as
    // wide as the rail (and across the band's gutter to the true screen edge)
    // and one hit tall; its mark sits in the middle of it.
    Repeater {
        id: slots
        model: root.slotCount

        Item {
            id: slot

            required property int index
            readonly property int workspaceId: index + 1
            readonly property var workspace: root.workspaceFor(workspaceId)
            readonly property bool active: root.hasActive && index === root.activeIndex
            readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
            readonly property bool urgent: workspace?.urgent ?? false
            readonly property real growth: dotLayer.growth

            readonly property real offset: root.ringOffset(index)
            readonly property real distance: Math.abs(offset)
            // The lens covers its own dot; the dot steps aside instead of
            // doubling under it, and comes back the moment the lens leaves.
            readonly property real cover: root.hasActive && index === root.activeIndex
                ? Math.max(0, Math.min(1, (distance - 0.35) / 0.4)) : 1
            readonly property real fade: root.atDistance(Theme.railDrumOpacity, distance) * cover
            readonly property real haze: root.atDistance(Theme.railDrumHaze, distance)
            readonly property real markSize: QsmShellStyle.Style.snap(root.atDistance(Theme.railDrumSize, distance), slot)
            // Two device pixels on a near dot, one on a far one, so a small
            // outline stays a ring and does not fill in.
            readonly property real ringStroke: QsmShellStyle.Style.stroke(markSize >= QsmShellStyle.Style.space2 - QsmShellStyle.Style.spaceTight
                ? 2 * QsmShellStyle.Style.hairline : QsmShellStyle.Style.hairline, slot)

            y: QsmShellStyle.Style.snap(root.lensCentre + offset * root.pitch - height / 2, slot)
            z: -distance
            width: parent.width
            // A dot too far round the drum to be a target is only its mark,
            // so its faint tail does not lie over the next group.
            height: distance <= Theme.railDrumReachable ? Theme.railDrumHit : markSize
            visible: fade > 0.005

            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: `Workspace ${workspaceId}`
            Accessible.description: [slot.active ? "current" : "",
                slot.urgent ? "needs attention" : slot.occupied ? "has windows" : "empty"]
                .filter(part => part.length > 0).join(", ")
            Accessible.onPressAction: root.activate(slot.workspaceId)
            Keys.onReturnPressed: root.activate(slot.workspaceId)
            Keys.onEnterPressed: root.activate(slot.workspaceId)
            Keys.onSpacePressed: root.activate(slot.workspaceId)

            // The mark and the urgent ring are one fading, hazing layer. Centred
            // by arithmetic, never by `anchors.centerIn`: that rounds to a
            // whole LOGICAL pixel, which is between two device pixels at 1.25
            // once hover has grown the body.
            Item {
                id: mark

                width: parent.width
                height: Theme.railDrumHit
                y: (slot.height - height) / 2
                opacity: slot.fade
                layer.enabled: slot.haze > 0
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: QsmShellStyle.Style.space1
                    blur: slot.haze
                }

                Rectangle {
                    id: dotMark

                    x: QsmShellStyle.Style.snap((parent.width - width) / 2, dotMark)
                    y: QsmShellStyle.Style.snap((parent.height - height) / 2, dotMark)
                    width: slot.markSize + 2 * dotLayer.growth
                    height: width
                    radius: QsmShellStyle.Style.radiusPill
                    // Shape carries the state and colour repeats it: occupied
                    // is a filled dot, empty an outline, urgent a filled dot
                    // with a ring around it (below). Hover and press recolour
                    // it through the one state matrix, so it answers like
                    // every other target.
                    readonly property color ink: QsmShellStyle.Style.tone(
                        slot.urgent ? Theme.danger : Theme.textMuted,
                        dotLayer.hovered, dotLayer.pressed, false, true, Theme.accent)
                    readonly property bool filled: slot.occupied || slot.urgent
                    color: filled ? ink : "transparent"
                    border.width: filled ? 0 : slot.ringStroke
                    border.color: ink
                }

                // An urgent workspace asks for attention, so its dot wears a
                // ring as well as the danger colour.
                Rectangle {
                    id: ringMark

                    x: QsmShellStyle.Style.snap((parent.width - width) / 2, ringMark)
                    y: QsmShellStyle.Style.snap((parent.height - height) / 2, ringMark)
                    width: QsmShellStyle.Style.snap(2 * slot.markSize, ringMark) + 2 * dotLayer.growth
                    height: width
                    radius: QsmShellStyle.Style.radiusPill
                    visible: slot.urgent
                    color: "transparent"
                    border.width: slot.ringStroke
                    border.color: Theme.danger
                }
            }

            // The slot is the hit area, as wide as the rail and across the
            // band's gutter to the true screen edge like every rail cell.
            // Hover grows and recolours what is in it (09): the dot, or the
            // lens on the active dot; a press recolours without resizing. A
            // dot too far round the drum to see is no target.
            QsmShellComponents.StateLayer {
                id: dotLayer
                anchors.fill: parent
                anchors.leftMargin: -Theme.railGutter
                interactive: slot.distance <= Theme.railDrumReachable
                extent: slot.active ? Theme.railWorkspaceChipHeight : slot.markSize
                hoverScale: slot.active ? QsmShellStyle.Motion.hoverScale
                    : Theme.railWorkspaceDotHoverScale
                focused: slot.activeFocus
                focusRadius: QsmShellStyle.Style.radiusPill
                onClicked: root.activate(slot.workspaceId)
            }

            Connections {
                target: dotLayer

                function onHoveredChanged(): void {
                    if (dotLayer.hovered)
                        root.hoveredIndex = slot.index;
                    else if (root.hoveredIndex === slot.index)
                        root.hoveredIndex = -1;
                }

                function onPressedChanged(): void {
                    if (dotLayer.pressed)
                        root.pressedIndex = slot.index;
                    else if (root.pressedIndex === slot.index)
                        root.pressedIndex = -1;
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: event => {
            if (event.angleDelta.y !== 0)
                root.wheel(event.y, event.angleDelta.y);
            else
                event.accepted = false;
        }
    }
}
