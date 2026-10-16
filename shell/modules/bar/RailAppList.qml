pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import qs.components
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.theme

// The rail's MIDDLE section: the CURRENT workspace's apps — one uniform
// 40px cell each, icon only, per monitor, click-to-focus, active row
// plugged with the accent. Empty workspace shows the monitor icon +
// "Desktop". Overflow scrolls (wheel), never spills out of the band.
//
// The process name stays IN the cell (owner: that text is a feature) but
// reads horizontally now, not rotated 90° — rotated micro-type was the one
// thing in this shell nobody could read at a glance. The name elides when it
// is too long for the band; the hover popout carries the full name plus the
// live window title, which never fitted in 40px to begin with.
Item {
    id: root

    required property var screen
    property var popouts: null
    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var toplevels: monitor?.activeWorkspace?.toplevels?.values ?? []

    implicitWidth: Theme.railWidth

    // Empty-workspace default (references/rail-closeup.png).
    Column {
        anchors.centerIn: parent
        visible: root.toplevels.length === 0
        spacing: Theme.spaceTight

        QsmShellComponents.SvgIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "monitor"
            size: Theme.railAppIconSize
            color: Theme.textMuted
        }

        QsmShellComponents.Prose {
            role: "metadata"
            technical: true
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Desktop"
        }
    }

    // N rows, ALL THE SAME HEIGHT, sharing the free area between the pin pill
    // and the clock pill, separated by one clear gap. The height is whatever
    // divides the space evenly, floored by railAppNameMin so the caption stays
    // readable; past that floor the list scrolls instead of shrinking further.
    
    
    
    readonly property real rowGap: Theme.space2
    readonly property real rowMin: Theme.railAppIconSize + Theme.space1 + Theme.railAppNameMin
    // Rows DIVIDE the whole area between them: one app takes all of it, two
    // split it, three squash toward the minimum and past that the list
    // scrolls. No preferred ceiling — a lone row filling its area is the point
    // (owner 2026-08-19, replacing the earlier cap).
    readonly property real rowHeight: toplevels.length > 0
        ? Math.max(rowMin, (height - rowGap * (toplevels.length - 1)) / toplevels.length)
        : 0

    ListView {
        id: appList
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Math.min(parent.height, contentHeight)
        visible: root.toplevels.length > 0
        clip: true
        spacing: root.rowGap
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
            // The LIVE window title, compact: browsers/editors append their
            // brand after a dash ("Tab Name — Zen Browser") — keep the FIRST
            // part, so the text is what's RUNNING (the tab, the command),
            // never the app's brand (owner).
            // Identity and live context are kept SEPARATE now that they are
            // shown as popout title + body: the title never gets eaten by an
            // ellipsis, and the context can wrap.
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
            height: root.rowHeight

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusMd
                color: appRow.current
                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
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
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 2
                implicitSize: Theme.railAppIconSize
                icon: appRow.appClass
                // Inactive apps sit back; the active one is at full strength.
                // De-emphasis by contrast, never by shrinking the target.
                opacity: appRow.current ? 1 : 0.62
            }

            // "app · live-title" running SIDEWAYS beneath the icon — the band
            // is 40px wide, so rotation is the only axis that fits a live
            // title at readable size. Identity leads, so the ellipsis can
            // only ever eat the context tail.
            Item {
                id: nameBox
                anchors.top: rowIcon.bottom
                anchors.topMargin: 2
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
                width: 12

                QsmShellComponents.Prose {
                    // Fine print riding sideways under the icon — metadata,
                    // technical because identity+context reads as a run of
                    // tokens rather than prose.
                    role: "metadata"
                    technical: true
                    anchors.centerIn: parent
                    width: nameBox.height
                    rotation: 90
                    horizontalAlignment: Text.AlignHCenter
                    text: appRow.appContext.length > 0
                        ? appRow.appIdentity + " · " + appRow.appContext
                        : appRow.appIdentity
                    color: appRow.current ? Theme.text : Theme.textMuted
                    // No token for this tracking value — left as a raw
                    // number, reported.
                    font.letterSpacing: 1.2
                }
            }

            QsmShellComponents.StateLayer {
                anchors.fill: parent
                // The ICON grows, not the row. The row is 40px wide inside a
                // ListView that clips, so growing it shaved 4.4px off the
                // response (measured by scripts/ui-guard) — and it dragged the
                // sideways title with it, which read as the text wobbling
                // rather than as the app answering.
                target: rowIcon
                hoverScale: 1.08
                pressScale: 0.92
                onClicked: appRow.modelData.activate()
            }
        }
    }

    // "There is more below" was unsaid. The list scrolls as soon as enough
    // windows squash to the row minimum, and nothing marked that boundary.
    QsmShellComponents.ScrollCue {
        view: appList
        fadeColor: Theme.band
        visible: appList.visible
    }
}
