import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.state
import qs.theme

// The top panel (06-top-panel): centerpiece rollout from the top band,
// horizontally centered, BOTH dimensions content-driven per tab, 48px tab bar
// at the panel's top. A fixed 854px width left the Media and Workspaces tabs
// as a strip of content against half a panel of empty ground; the panel now
// takes the width its tab actually needs (never narrower than the tab bar,
// never wider than a comfortable reading measure) and MORPHS between tabs, so
// it reads as one surface resizing rather than five panels of different sizes. Opens on the dot handle's hover (EdgeScene
// owns handle + intent delay) or via IPC/keybinds; lands on the LAST USED
// tab. Closes on Escape, click outside (EdgeScene catch), shortcut
// re-press (togglePanel), or the cursor leaving the panel for 400ms.
Item {
    id: root

    required property var targetScreen
    required property var scene
    // The ShellBorder answering the library's seven-call contract.
    required property var host
    // The tab group is the shared control, so the panel's keyboard contract
    // is the library's, not a second hand-rolled one.
    readonly property Item tabsTarget: tabBar
    property bool loadContent: true
    signal tabSelected(string key)
    readonly property bool active: ShellState.modal === "panel"
        && ShellState.focusedScreen === targetScreen
    readonly property bool fullscreen: FullscreenService.fullscreenFor(targetScreen)
    // Still retracting — the host keeps its click-outside catch region
    // alive until the retract settles.
    readonly property bool revealed: rollout.visible
    readonly property bool animating: rollout.animating

    // Handle-ride source of truth (06-top-panel amended 2026-08-18): the
    // rollout's top edge is pinned at the wall (source expansion,
    // 02-rollouts) while height grows downward, so y + height IS the
    // panel's current bottom (leading) edge — already offsetScale-driven,
    // no second animation needed for the dot handle.
    readonly property real leadingEdgeY: rollout.y + rollout.height

    readonly property var tabs: [
        { key: "dashboard", label: "Dashboard", icon: "home", width: Theme.panelWidthGrid },
        { key: "media", label: "Media", icon: "music", width: Theme.panelWidthColumn },
        { key: "performance", label: "Performance", icon: "activity", width: Theme.panelWidthGrid },
        { key: "workspaces", label: "Workspaces", icon: "workspace", width: Theme.panelWidthColumn },
        { key: "notifications", label: "Notifications", icon: "bell", width: Theme.panelWidthColumn }
    ]

    // The open tab's designed width, floored by the tab bar so the set of tabs
    // is never itself the thing that overflows.
    readonly property real tabWidth: {
        const tab = tabs.find(candidate => candidate.key === ShellState.panelTab);
        return Math.max(tabBar.implicitWidth, tab?.width ?? Theme.panelWidthGrid);
    }

    // Tab stepping is the shared control's own action; Left/Right, Tab/Shift+Tab
    // and Home/End therefore mean exactly what they mean everywhere else. The
    // ends are visible landmarks, so navigation stops there instead of wrapping.
    function stepTab(delta: int): bool {
        return tabBar.step(delta);
    }

    anchors.fill: parent

    QsmShellComponents.Rollout {
        id: rollout
        host: root.host
        rolloutId: "panel"
        edges: ["top"]
        tier: "large"
        registerHitRect: false // the host's full-scene catch region is the hit area
        shouldBeActive: root.active
        suppressed: root.fullscreen || root.scene.focusMode
        bodyWidth: root.tabWidth + Theme.space4 * 2
        bodyHeight: panelColumn.implicitHeight + Theme.space4 * 2
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: root.scene.panelCenterX - root.scene.width / 2

        FocusScope {
            id: panelFocus
            anchors.fill: parent
            Keys.onEscapePressed: ShellState.closeModal()
            Keys.onLeftPressed: {
                ShellState.claimKeyboardSelection();
                root.stepTab(-1);
            }
            Keys.onRightPressed: {
                ShellState.claimKeyboardSelection();
                root.stepTab(1);
            }

            ColumnLayout {
                id: panelColumn
                anchors.fill: parent
                anchors.margins: Theme.space4
                spacing: Theme.space3

                // The tab bar: icon + label per tab, active = accent, and the group takes
                // Tab/Shift+Tab. It is sized to the panel's reading measure, not
                // stretched across the widest tab's panel, which read as five
                // separate controls instead of one set.
                QsmShellComponents.Segmented {
                    id: tabBar
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Theme.panelWidthColumn
                    implicitWidth: Theme.panelWidthColumn
                    barHeight: Theme.panelTabBarHeight
                    options: root.tabs
                    currentIndex: Math.max(0, root.tabs.findIndex(tab => tab.key === ShellState.panelTab))
                    tabNavigation: true
                    wrapNavigation: false
                    Accessible.name: "Panel sections"
                    onSelected: index => {
                        ShellState.claimKeyboardSelection();
                        ShellState.panelTab = root.tabs[index].key;
                        root.tabSelected(root.tabs[index].key);
                    }
                    // Down is the way INTO the selected tab; content owns its
                    // own keys once focus is there.
                    Keys.onDownPressed: {
                        const content = contentLoader.item as Item;
                        if (content) content.forceActiveFocus();
                    }
                }

                Loader {
                    id: contentLoader
                    Layout.fillWidth: true
                    // Content stays loaded through the retract (never a
                    // blank panel sliding away).
                    active: root.loadContent && (root.active || rollout.visible)
                    sourceComponent: {
                        switch (ShellState.panelTab) {
                        case "media": return mediaTab;
                        case "performance": return performanceTab;
                        case "workspaces": return workspacesTab;
                        case "notifications": return notificationsTab;
                        default: return dashboardTab;
                        }
                    }
                }
            }
        }

        // Leaving the panel for 400ms closes it (06 DEFAULT).
        HoverHandler {
            id: panelHover
            onHoveredChanged: {
                if (hovered)
                    leaveTimer.stop();
                else if (root.active)
                    leaveTimer.restart();
            }
        }
    }

    Timer {
        id: leaveTimer
        interval: 400
        onTriggered: {
            if (root.active && !panelHover.hovered)
                ShellState.closeModal();
        }
    }

    onActiveChanged: {
        if (active)
            tabBar.forceActiveFocus();
    }

    Component { id: dashboardTab; DashboardTab {} }
    Component { id: mediaTab; MediaTab {} }
    Component { id: performanceTab; PerformanceTab {} }
    Component { id: workspacesTab; WorkspacesTab { targetScreen: root.targetScreen } }
    Component { id: notificationsTab; NotificationCenterTab {} }
}
