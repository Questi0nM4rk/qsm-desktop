import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components as QsmShellComponents
import qs.services
import qs.state
import qs.theme

// One responsive shell body. Static tabs overflow inside it; model-backed tabs
// keep their own scrolling. EdgeScene owns the handle, hover intent and catch.
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
    property Component performanceContent: Component { PerformanceTab {} }
    signal tabSelected(string key)
    readonly property bool active: ShellState.modal === "panel"
        && ShellState.focusedScreen === targetScreen
    readonly property bool fullscreen: FullscreenService.fullscreenFor(targetScreen)
    // Still retracting — the host keeps its click-outside catch region
    // alive until the retract settles.
    readonly property bool revealed: rollout.visible
    readonly property bool animating: rollout.animating
    readonly property real bodyWidth: Math.max(0, Math.min(Theme.panelWidth,
        Math.floor(2 * Math.min(root.scene.panelCenterX - root.host.leftEdge,
            root.width - Theme.frameThickness - root.scene.panelCenterX) - Theme.space4 * 2)))
    readonly property real bodyHeight: Math.max(0, Math.min(Theme.panelHeight,
        Math.floor(root.height - Theme.frameThickness * 2 - Theme.space4
            - Theme.panelHandleHeight / 2 - Theme.handleProud)))
    readonly property bool staticContent: ShellState.panelTab !== "notifications"
        && ShellState.panelTab !== "workspaces"
    readonly property bool detailedSampling: root.loadContent && root.active
        && !root.fullscreen && !root.scene.focusMode
        && (ShellState.panelTab === "dashboard" || ShellState.panelTab === "performance")

    function syncSampling(): void {
        PerformanceService.watchDetails(root, root.detailedSampling);
    }
    onDetailedSamplingChanged: syncSampling()
    Component.onCompleted: syncSampling()
    Component.onDestruction: PerformanceService.watchDetails(root, false)

    // Handle-ride source of truth (06-top-panel amended 2026-08-18): the
    // rollout's top edge is pinned at the wall (source expansion,
    // 02-rollouts) while height grows downward, so y + height IS the
    // panel's current bottom (leading) edge — already offsetScale-driven,
    // no second animation needed for the dot handle.
    readonly property real leadingEdgeY: rollout.y + rollout.height

    readonly property var tabs: [
        { key: "dashboard", label: "Dashboard", icon: "layers" },
        { key: "media", label: "Media", icon: "music" },
        { key: "performance", label: "Performance", icon: "gauge" },
        { key: "workspaces", label: "Workspaces", icon: "workspace" },
        { key: "notifications", label: "Notifications", icon: "bell" }
    ]

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
        bodyWidth: root.bodyWidth
        bodyHeight: root.bodyHeight
        animateBodySize: false
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

                QsmShellComponents.ScrollArea {
                    id: navigation
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.panelTabBarHeight
                    orientation: Qt.Horizontal
                    fadeColor: Theme.band

                    function revealTab(): void {
                        const left = tabBar.currentIndex * tabBar.width / root.tabs.length;
                        const right = left + tabBar.width / root.tabs.length;
                        const view = navigation.viewport;
                        view.contentX = Math.max(0, Math.min(view.contentWidth - view.width,
                            left < view.contentX ? left
                            : right > view.contentX + view.width ? right - view.width : view.contentX));
                    }
                    onWidthChanged: Qt.callLater(navigation.revealTab)

                    QsmShellComponents.Segmented {
                        id: tabBar
                        objectName: "panelNavigation"
                        width: Math.max(navigation.width, Theme.panelNavigationWidth)
                        barHeight: Theme.panelTabBarHeight
                        options: root.tabs
                        currentIndex: Math.max(0, root.tabs.findIndex(tab => tab.key === ShellState.panelTab))
                        tabNavigation: true
                        wrapNavigation: false
                        Accessible.name: "Panel sections"
                        onCurrentIndexChanged: navigation.revealTab()
                        onSelected: index => {
                            ShellState.claimKeyboardSelection();
                            ShellState.panelTab = root.tabs[index].key;
                            root.tabSelected(root.tabs[index].key);
                        }
                        Keys.onDownPressed: {
                            const content = contentLoader.item as Item;
                            if (content) content.forceActiveFocus();
                        }
                    }
                }

                Item {
                    id: contentFrame
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Flickable {
                        id: contentView
                        objectName: "panelContentViewport"
                        anchors.fill: parent
                        clip: true
                        interactive: root.staticContent
                        boundsBehavior: Flickable.StopAtBounds
                        flickableDirection: Flickable.AutoFlickDirection
                        contentWidth: root.staticContent
                            ? Math.max(width, contentLoader.item?.implicitWidth ?? 0) : width
                        contentHeight: root.staticContent
                            ? Math.max(height, contentLoader.item?.implicitHeight ?? 0) : height

                        Loader {
                            id: contentLoader
                            width: contentView.contentWidth
                            height: root.staticContent
                                ? Math.max(0, item?.implicitHeight ?? 0) : contentView.height
                            y: root.staticContent ? Math.max(0, Math.round((contentView.height - height) / 2)) : 0
                            // Keep content through the retract, not its demand.
                            active: root.loadContent && (root.active || rollout.visible)
                            sourceComponent: {
                                switch (ShellState.panelTab) {
                                case "media": return mediaTab;
                                case "performance": return root.performanceContent;
                                case "workspaces": return workspacesTab;
                                case "notifications": return notificationsTab;
                                default: return dashboardTab;
                                }
                            }
                            onSourceComponentChanged: {
                                contentView.contentX = 0;
                                contentView.contentY = 0;
                            }
                        }
                    }
                    QsmShellComponents.ScrollCue {
                        view: contentView
                        orientation: Qt.Vertical
                        visible: root.staticContent
                        fadeColor: Theme.band
                    }
                    QsmShellComponents.ScrollCue {
                        view: contentView
                        orientation: Qt.Horizontal
                        visible: root.staticContent
                        fadeColor: Theme.band
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
    Component { id: workspacesTab; WorkspacesTab { targetScreen: root.targetScreen } }
    Component { id: notificationsTab; NotificationCenterTab {} }
}
