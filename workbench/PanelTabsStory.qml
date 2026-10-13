import QtQuick
import Quickshell.Services.UPower
import qs.QsmShell.Components as QsmShellComponents
import qs.components
import qs.modules.panel as Panel
import qs.services
import qs.state
import qs.theme

// Navigation-only stories retain their scope. The Performance variant loads
// that production composition against isolated service readings, never probes.
Item {
    id: root

    property var previewEnvironment: null
    property int viewportWidth: 980
    property int viewportHeight: 760
    property var inputDriver: null
    property bool interactive: false
    property int resetGeneration: 0
    property bool observing: false
    property string menuVariant: "tabs"
    // Environment the panel reads instead of a real fullscreen or focus-mode
    // screen. This is scenario setup, never an input route.
    property bool focusSuppressed: false
    property real cpuUsage: 0.23
    property real memoryUsed: 0.46
    readonly property real contentExtentWidth: width
    readonly property real contentExtentHeight: height
    readonly property var controls: [{
        label: "Motion",
        options: [{ label: "Full" }, { label: "Reduced" }]
    }, {
        label: "Suppress",
        options: [{ label: "Interactive" }, { label: "Focus mode" }]
    }, {
        label: "Resources",
        options: [{ label: "Everyday" }, { label: "Busy" }, { label: "Unavailable" },
            { label: "Zero" }, { label: "Full" }]
    }]
    readonly property var actions: [
        { label: "Open panel", trigger: "open-panel" },
        { label: "Close panel", trigger: "close-panel" }
    ]
    readonly property var integration: ({
        events: ["tab-selected", "applied"],
        actions: root.actions.map(action => action.trigger),
        runAction: name => root.runAction(name),
        observables: {
            "panel-open": () => ShellState.modal === "panel",
            "panel-tab": () => ShellState.panelTab,
            "tab-count": () => panel.tabs.length,
            "reduced-motion": () => ShellState.reducedMotion,
            "focus-suppressed": () => root.focusSuppressed,
            "handle-visible": () => handle.visible,
            "cpu-reading": () => handle.reading(root.cpuUsage),
            "memory-reading": () => handle.reading(root.memoryUsed),
            "panel-width": () => panel.bodyWidth,
            "panel-height": () => panel.bodyHeight,
            "detailed-sampling": () => PerformanceService.polling
        },
        targets: {
            "scene": () => root,
            "tabs": () => panel.tabsTarget,
            "handle": () => handle
        },
        idle: () => !panel.animating
    })

    signal eventRecorded(var record)
    signal inspectionReady(var inspection)

    width: root.previewEnvironment?.screenRect?.width ?? root.viewportWidth
    height: root.previewEnvironment?.screenRect?.height ?? root.viewportHeight

    function record(origin: string, name: string, payload: var): void {
        if (root.observing)
            root.eventRecorded({ origin: origin, kind: "panel", name: name, payload: payload });
    }

    readonly property var controlHandlers: ({
        "Motion": option => { ShellState.reducedMotion = option === 1; return true; },
        "Suppress": option => { root.focusSuppressed = option === 1; return true; },
        "Resources": option => {
            root.cpuUsage = [0.23, 0.87, -1, 0, 1][option];
            root.memoryUsed = [0.46, 0.92, -1, 0, 1][option];
            PerformanceService.cpuUsage = root.cpuUsage;
            PerformanceService.memUsed = root.memoryUsed;
            PerformanceService.cpuTemp = option === 2 ? -1 : 52;
            PerformanceService.gpuUsage = option === 2 ? -1 : 0.18;
            PerformanceService.gpuTemp = option === 2 ? -1 : 45;
            PerformanceService.storageUsed = option === 2 ? -1 : 0.38;
            return true;
        }
    })

    function applyControl(group: int, option: int): bool {
        const handler = root.controlHandlers[root.controls[group]?.label];
        if (!handler || !handler(option)) return false;
        root.record("scenario", "applied", {
            group: root.controls[group].label, option: root.controls[group].options[option].label
        });
        return true;
    }

    function resetStory(): void {
        root.observing = false;
        PerformanceService.reset();
        ShellState.reset();
        FullscreenService.reset();
        ShellState.focusedScreen = screenFacts;
        root.focusSuppressed = false;
        root.cpuUsage = 0.23;
        root.memoryUsed = 0.46;
        if (root.menuVariant === "performance") ShellState.panelTab = "performance";
        restoreObservation.restart();
    }

    readonly property var actionHandlers: ({
        "open-panel": () => { ShellState.modal = "panel"; return true; },
        "close-panel": () => { ShellState.closeModal(); return true; }
    })

    function runAction(name: string): bool {
        const handler = root.actionHandlers[name];
        if (!handler || !handler()) return false;
        root.record("action", name, {});
        return true;
    }

    function triggerAction(index: int): bool {
        return root.runAction(root.actions[index]?.trigger ?? "");
    }

    function dumpTree(): void {
        root.inspectionReady({ story: "panel-tabs", tab: ShellState.panelTab });
    }

    onResetGenerationChanged: root.resetStory()
    onMenuVariantChanged: root.resetStory()
    Component.onCompleted: root.resetStory()
    Component.onDestruction: {
        root.observing = false;
        ShellState.closeModal();
        ShellState.focusedScreen = null;
    }

    Timer { id: restoreObservation; interval: 0; onTriggered: root.observing = true }
    Rectangle { anchors.fill: parent; color: Theme.background }
    QsmShellComponents.ScenePointer {
        id: pointer
        onPointChanged: ShellState.keyboardOwnsSelection = false
    }
    QsmShellComponents.ShellBorder {
        id: border
        anchors.fill: parent
        leftEdge: Theme.reservedLeft
        pointer: pointer
        entryFilter: id => id === "panel" || id === "panel-catch" || id === "panel-handle"
    }
    Panel.PanelHandle {
        id: handle
        host: border
        sampleResources: false
        cpuUsage: root.cpuUsage
        memoryUsed: root.memoryUsed
        width: implicitWidth
        height: implicitHeight
        x: sceneFacts.panelCenterX - width / 2
        y: panel.leadingEdgeY - height / 2 + Theme.handleProud
        visible: !root.focusSuppressed && root.previewEnvironment?.fullscreen !== true
        onActivated: {
            ShellState.modal = ShellState.modal === "panel" ? "" : "panel";
            root.record("component", "tab-selected", { tab: ShellState.panelTab, source: "handle" });
        }
    }
    QtObject { id: screenFacts; readonly property string name: "panel-preview" }
    QtObject {
        id: sceneFacts
        readonly property var modelData: screenFacts
        readonly property bool focusMode: root.focusSuppressed
        readonly property real panelCenterX: (Theme.reservedLeft + root.width - Theme.frameThickness) / 2
        readonly property real width: root.width
    }

    Panel.PanelSurface {
        id: panel
        anchors.fill: parent
        targetScreen: screenFacts
        scene: sceneFacts
        host: border
        loadContent: root.menuVariant === "performance" && ShellState.panelTab === "performance"
        performanceContent: Component {
            Panel.PerformanceTab {
                batteryDevice: ({ isLaptopBattery: true, percentage: 0.62,
                    state: UPowerDeviceState.Discharging, timeToEmpty: 12600, timeToFull: 0 })
            }
        }
        onTabSelected: key => root.record("component", "tab-selected", { key: key })
    }
}
