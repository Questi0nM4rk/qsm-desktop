pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.services
import qs.theme

// The rail's MIDDLE section (03 RATIFIED 2026-10-16): the CURRENT
// workspace's apps, per monitor, ICON ONLY. Each row is a 32px slot with a
// 22px glyph, the rail's own gap; no caption. The window title lives in the hover
// popout as "app · live-title". The focused row carries accent at
// opacitySelected behind it. Click focuses; more rows than fit scroll
// (wheel), never spill out of the band. An empty workspace shows the
// monitor glyph.
Item {
    id: root

    required property var screen
    property var popouts: null
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var toplevels: monitor?.activeWorkspace?.toplevels?.values ?? []

    implicitWidth: Theme.railWidth

    // The empty state holds the first row's slot, so rows arriving replace it
    // in place.
    QsmShellComponents.SvgIcon {
        anchors.top: parent.top
        anchors.topMargin: (Theme.railAppSlot - Theme.railAppIconSize) / 2
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.toplevels.length === 0
        name: "monitor"
        size: Theme.railAppIconSize
        color: Theme.textMuted
    }

    // The rows start at a fixed origin under the workspace group, so the
    // first row never moves while rows come and go (owner 2026-10-19:
    // "NENAVIDIM RANDOM UI JUMPING"). Centring on contentHeight shifted every
    // row by half a slot per window opened or closed.
    ListView {
        id: appList
        anchors.top: parent.top
        width: parent.width
        height: Math.min(parent.height, contentHeight)
        visible: root.toplevels.length > 0
        clip: true
        spacing: Theme.railItemGap
        boundsBehavior: Flickable.StopAtBounds
        model: root.toplevels

        delegate: Item {
            id: appRow
            required property var modelData
            required property int index
            // lastIpcObject stays empty on unfocused monitors — the shared
            // clients service is the reliable class/title source.
            readonly property var info: HyprClientsService.infoFor(modelData.address)
                ?? modelData.lastIpcObject
            readonly property string appClass: appRow.info?.class ?? ""
            // Identity and live context are shown as popout title + body: the
            // title never gets eaten by an ellipsis, and the context can wrap.
            readonly property string appIdentity: appRow.appClass.split(".").pop() || "app"
            readonly property string appContext: {
                // Unread counters ("(2864) Video") stripped — they read as a
                // bare number (owner once mistook one for a PID). The brand
                // suffix after a dash drops; the class carries identity.
                const raw = modelData.title || appRow.info?.title || appRow.appClass || "";
                const title = String(raw).replace(/^\(\d+\)\s*/, "");
                const parts = title.split(/\s+[-–—|·]\s+/);
                const context = (parts.length > 1 ? parts[0] : title).trim();
                return context.toLowerCase() === appRow.appIdentity.toLowerCase()
                    ? "" : context;
            }
            readonly property bool current: modelData.activated

            readonly property bool open: root.popouts !== null
                && root.popouts.kind === "app" && root.popouts.anchor === appRow

            function focusWindow(): void {
                HyprClientsService.focus(appRow.modelData.address);
            }

            // The controller snapshots title and detail when the popout
            // opens, and a window's title keeps changing under a pointer that
            // rests on its row (a page loading, a track changing): push the
            // new text while this row's popout is the open one.
            onAppContextChanged: {
                if (open)
                    root.popouts.detail = appContext;
            }
            onAppIdentityChanged: {
                if (open)
                    root.popouts.title = appIdentity;
            }

            width: appList.width
            height: Theme.railAppSlot

            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: appIdentity
            Accessible.description: appContext
            Accessible.onPressAction: appRow.focusWindow()
            Keys.onReturnPressed: appRow.focusWindow()
            Keys.onEnterPressed: appRow.focusWindow()
            Keys.onSpacePressed: appRow.focusWindow()
            // Tabbing to a row names it the way hovering does, and brings it
            // into the clipped list.
            onActiveFocusChanged: {
                if (!activeFocus)
                    return;
                appList.positionViewAtIndex(index, ListView.Contain);
                root.popouts?.show("app", appRow, appRow.appIdentity, appRow.appContext, null);
            }

            // The focused row is a state, not a hover: accent at
            // opacitySelected behind the glyph.
            QsmShellComponents.Surface {
                anchors.centerIn: parent
                width: Theme.railAppSlot
                height: Theme.railAppSlot
                radius: Theme.radiusMd
                base: "transparent"
                selected: appRow.current
                hovered: rowLayer.hovered
                pressed: rowLayer.pressed
            }

            // Hover authority sits on the delegate — an ANCESTOR of the icon,
            // never a sibling underneath it (PRIMER: hover law). Hover-enter
            // opens/morphs the popout; whether it stays open is EdgeScene's
            // geometric region test, not a leave-time close call here.
            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        root.popouts?.show("app", appRow, appRow.appIdentity,
                            appRow.appContext, null);
                }
            }

            AppIcon {
                id: rowIcon
                anchors.centerIn: parent
                implicitSize: Theme.railAppIconSize
                icon: appRow.appClass
                // One tone of the glyph set: text when active, muted and
                // receded when not. De-emphasis by contrast, never by
                // shrinking the target.
                tint: appRow.current ? Theme.text : Theme.textMuted
                opacity: appRow.current ? 1 : Theme.railInactiveAppOpacity
            }

            QsmShellComponents.StateLayer {
                id: rowLayer
                anchors.fill: parent
                // The ICON grows, not the row: the row sits in a clipping
                // ListView, so growing it would shave the response. The
                // row's slot above recolours on hover and press.
                target: rowIcon
                hoverScale: QsmShellStyle.Motion.hoverScale
                pressScale: QsmShellStyle.Motion.pressScale
                focused: appRow.activeFocus
                focusRadius: Theme.radiusMd
                onClicked: appRow.focusWindow()
            }
        }
    }

    // "There is more below" was unsaid. The list scrolls as soon as rows
    // overflow, and nothing marked that boundary.
    QsmShellComponents.ScrollCue {
        view: appList
        fadeColor: Theme.band
        visible: appList.visible
    }
}
