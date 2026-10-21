import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
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
    // Untyped on purpose: each tab type offers its own optional focusFirst.
    readonly property var tabContent: contentLoader.item
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
        Math.floor(2 * Math.min(root.scene.panelCenterX - root.scene.panelViewportLeft,
            root.width - root.scene.panelCenterX) - QsmShellStyle.Style.rolloutPadding * 2)))
    readonly property real bodyHeight: Math.max(0, Math.min(Theme.panelHeight,
        Math.floor(root.height - QsmShellStyle.Style.frameThickness * 2 - QsmShellStyle.Style.space4
            - Theme.panelHandleHeight / 2 - Theme.panelHandleProud)))
    readonly property bool staticContent: ShellState.panelTab !== "workspaces"
    readonly property bool detailedSampling: root.loadContent && root.active
        && !root.fullscreen && !root.scene.focusMode
        && (ShellState.panelTab === "dashboard" || ShellState.panelTab === "performance")

    function syncSampling(): void {
        PerformanceService.watchDetails(root, root.detailedSampling);
    }
    onDetailedSamplingChanged: syncSampling()
    Component.onCompleted: syncSampling()
    Component.onDestruction: PerformanceService.watchDetails(root, false)

    // Handle-ride source of truth (06-top-panel): the
    // rollout's top edge is pinned at the wall (source expansion,
    // 02-rollouts) while height grows downward, so y + height IS the
    // panel's current bottom (leading) edge — already offsetScale-driven,
    // no second animation needed for the dot handle.
    readonly property real leadingEdgeY: rollout.y + rollout.height

    readonly property var tabs: [
        { key: "dashboard", label: "Dashboard" },
        { key: "media", label: "Media" },
        { key: "performance", label: "Performance" },
        { key: "workspaces", label: "Workspaces" }
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
        // A key, the IPC and a launcher command show the panel in one frame; the
        // pointer on its handle makes it roll out.
        instantReveal: !ShellState.modalByPointer
        instantRetract: !ShellState.modalByPointer
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
            Keys.onEscapePressed: ShellState.closeModalByKey()
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
                anchors.margins: QsmShellStyle.Style.rolloutPadding
                spacing: QsmShellStyle.Style.space3

                QsmShellComponents.ScrollArea {
                    id: navigation
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.panelTabBarHeight
                    orientation: Qt.Horizontal
                    fadeColor: Theme.band
                    indicator: false

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
                        size: Theme.panelTabBarSize
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
                            // The tab names its first operable control; a tab with none
                            // leaves focus on the bar, where its ring is.
                            const content = root.tabContent;
                            if (content && content.focusFirst) content.focusFirst();
                        }
                    }
                }

                Item {
                    id: contentFrame
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    // A model-backed tab clips itself and keeps room for a hovered
                    // tile's growth beyond the frame.
                    clip: root.staticContent

                    Flickable {
                        id: contentView
                        objectName: "panelContentViewport"
                        anchors.fill: parent
                        clip: root.staticContent
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
                            // Keep content through the retract, not its demand.
                            active: root.loadContent && (root.active || rollout.visible)
                            sourceComponent: {
                                switch (ShellState.panelTab) {
                                case "media": return mediaTab;
                                case "performance": return root.performanceContent;
                                case "workspaces": return workspacesTab;
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
                        indicator: false
                    }
                    QsmShellComponents.ScrollCue {
                        view: contentView
                        orientation: Qt.Horizontal
                        visible: root.staticContent
                        fadeColor: Theme.band
                        indicator: false
                    }
                }
            }
        }

        HoverHandler {
            id: panelHover
        }
    }

    // The panel stays open while the pointer is inside the union of its
    // trigger zone and its own body, and closes Motion.hoverGrace after it has
    // left both. Passing from the dots zone down into the panel never leaves
    // the union.
    readonly property bool pointerHeld: panelHover.hovered || root.scene.panelHandleHovered
        || root.scene.panelGripHovered
    onPointerHeldChanged: {
        if (pointerHeld)
            leaveTimer.stop();
        else if (root.active)
            leaveTimer.restart();
    }

    Timer {
        id: leaveTimer
        interval: QsmShellStyle.Motion.hoverGrace
        onTriggered: {
            if (root.active && !root.pointerHeld)
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
}
