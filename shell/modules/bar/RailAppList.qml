pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.theme

// The rail's MIDDLE section (03 RATIFIED 2026-10-16): the CURRENT
// workspace's apps, per monitor, ICON ONLY. Each row is a 36x36 slot with a
// 22px glyph and a 4px gap; no caption. The window title lives in the hover
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

    QsmShellComponents.SvgIcon {
        anchors.centerIn: parent
        visible: root.toplevels.length === 0
        name: "monitor"
        size: Theme.railAppIconSize
        color: Theme.textMuted
    }

    // The rows sit in the middle of the free area between the workspace group
    // and the bottom cluster (owner 2026-10-16), not pinned under the divider.
    ListView {
        id: appList
        anchors.centerIn: parent
        width: parent.width
        height: Math.min(parent.height, contentHeight)
        visible: root.toplevels.length > 0
        clip: true
        spacing: Theme.railAppGap
        boundsBehavior: Flickable.StopAtBounds
        model: root.toplevels

        delegate: Item {
            id: appRow
            required property var modelData
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

            width: appList.width
            height: Theme.railAppSlot

            // The focused row is a state, not a hover: accent at
            // opacitySelected behind the glyph.
            Rectangle {
                anchors.centerIn: parent
                width: Theme.railAppSlot
                height: Theme.railAppSlot
                radius: Theme.radiusSm
                color: appRow.current
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, Theme.opacitySelected)
                    : "transparent"
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
                // Inactive apps sit back; the active one is at full strength.
                // De-emphasis by contrast, never by shrinking the target.
                opacity: appRow.current ? 1 : 0.62
            }

            QsmShellComponents.StateLayer {
                anchors.fill: parent
                // The ICON grows, not the row: the row sits in a clipping
                // ListView, so growing it would shave the response.
                target: rowIcon
                hoverScale: 1.08
                pressScale: 0.92
                onClicked: appRow.modelData.activate()
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
