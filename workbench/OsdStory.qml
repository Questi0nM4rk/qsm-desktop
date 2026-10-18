import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.modules.osd as Osd
import qs.services as WorkbenchServices
import qs.state as WorkbenchState
import qs.theme

Item {
    id: root

    property var previewEnvironment: null
    property int viewportWidth: 980
    property int viewportHeight: 680
    property var inputDriver: null
    property bool interactive: false
    property int resetGeneration: 0
    property int resetEpoch: 0
    property bool observing: true
    property int eventSequence: 0

    readonly property bool fullscreen: root.previewEnvironment?.fullscreen === true
    readonly property rect screenRect: root.previewEnvironment?.screenRect
        ?? Qt.rect(0, 0, root.viewportWidth, root.viewportHeight)
    readonly property real contentExtentWidth: width
    readonly property real contentExtentHeight: height
    readonly property var targetScreen: screenFacts
    readonly property var outputTarget: osdSurface.outputTarget
    readonly property var microphoneTarget: osdSurface.microphoneTarget
    readonly property var brightnessTarget: osdSurface.brightnessTarget
    readonly property var sceneTarget: root

    readonly property var controls: [{
        label: "Microphone availability",
        options: [
            { label: "Available" },
            { label: "Unavailable" }
        ]
    }, {
        label: "Brightness availability",
        options: [
            { label: "Available" },
            { label: "Unavailable" }
        ]
    }, {
        label: "Presentation",
        options: [
            { label: "Show output" },
            { label: "Show microphone" },
            { label: "Show brightness" },
            { label: "Hide" }
        ]
    }]

    readonly property var actions: [
        { label: "Present output", trigger: "present-output" },
        { label: "Present microphone", trigger: "present-microphone" },
        { label: "Present brightness", trigger: "present-brightness" },
        { label: "Increase output", trigger: "increase-output" },
        { label: "Decrease output", trigger: "decrease-output" },
        { label: "Increase microphone", trigger: "increase-microphone" },
        { label: "Decrease microphone", trigger: "decrease-microphone" },
        { label: "Increase brightness", trigger: "increase-brightness" },
        { label: "Decrease brightness", trigger: "decrease-brightness" },
        { label: "Toggle output mute", trigger: "toggle-output-mute" },
        { label: "Toggle microphone mute", trigger: "toggle-microphone-mute" },
        { label: "Hide presentation", trigger: "hide" }
    ]

    readonly property var integration: ({
        events: ["moved", "mute-toggled", "operated", "applied", "presented", "dismissed"],
        actions: Object.keys(root.actionHandlers),
        runAction: name => root.runAction(name),
        observables: {
            "fullscreen": () => root.fullscreen,
            "screen-rect": () => root.screenRect,
            "presentation": () => root.fullscreen ? "capsule" : "rollout",
            "reveal-progress": () => osdSurface.rolloutPresentation.revealProgress,
            "settled-body-rect": () => osdSurface.rolloutPresentation.settledBodyRect,
            "border-paint-rect": () => root.registeredPaintRect(),
            "osd-visible": () => WorkbenchState.OsdState.visible,
            "osd-kind": () => WorkbenchState.OsdState.kind,
            "osd-target": () => WorkbenchState.OsdState.targetScreen === root.targetScreen,
            "osd-hovered": () => WorkbenchState.OsdState.hovered,
            "retention-held": () => WorkbenchState.OsdState.targetScreen === root.targetScreen
                && WorkbenchState.OsdState.hovered,
            "retention-screen": () => WorkbenchState.OsdState.hovered
                && WorkbenchState.OsdState.targetScreen === root.targetScreen
                    ? screenFacts.name : "",
            "output-value": () => WorkbenchServices.AudioService.outputValue,
            "output-muted": () => WorkbenchServices.AudioService.outputMuted,
            "output-available": () => WorkbenchServices.AudioService.outputAvailable,
            "can-toggle-output-mute": () => root.canToggleMute("output"),
            "microphone-value": () => WorkbenchServices.AudioService.microphoneValue,
            "microphone-muted": () => WorkbenchServices.AudioService.microphoneMuted,
            "microphone-available": () => WorkbenchServices.AudioService.microphoneAvailable,
            "can-toggle-microphone-mute": () => root.canToggleMute("microphone"),
            "brightness-value": () => WorkbenchServices.BrightnessService.value,
            "brightness-available": () => WorkbenchServices.BrightnessService.available,
            "input-simulated": () => root.inputDriver?.simulated === true,
            "input-error": () => root.inputDriver?.error ?? ""
        },
        targets: {
            "scene": () => root.sceneTarget,
            "osd-handle": () => sceneFacts.handlesArmed && osdHandle.glyphItem.visible
                ? osdHandle.glyphItem : null,
            "output": () => root.channelTarget("output"),
            "microphone": () => root.channelTarget("microphone"),
            "brightness": () => root.channelTarget("brightness"),
            "osd-capsule": () => root.fullscreen && WorkbenchState.OsdState.visible
                ? osdSurface.fullscreenCapsule : null
        },
        idle: () => true
    })

    signal eventRecorded(var record)
    signal inspectionReady(var inspection)

    width: screenRect.width
    height: screenRect.height

    function record(origin: string, kind: string, name: string, payload: var): void {
        if (!root.observing)
            return;
        root.eventSequence += 1;
        root.eventRecorded({
            origin: origin,
            kind: kind,
            name: name,
            sequence: root.eventSequence,
            payload: payload
        });
    }

    function channelTarget(name: string): var {
        if (!WorkbenchState.OsdState.visible)
            return null;
        if (name === "output" && WorkbenchServices.AudioService.outputAvailable)
            return root.outputTarget;
        if (name === "microphone" && (WorkbenchServices.AudioService.microphoneAvailable
                || WorkbenchState.OsdState.kind === "microphone"))
            return root.microphoneTarget;
        if (name === "brightness" && WorkbenchServices.BrightnessService.available)
            return root.brightnessTarget;
        return null;
    }

    // Mute is the channel's one route (05-osd 2026-10-16): the thumb's
    // double-click, Space, and this story action all call toggleMute().
    function canToggleMute(name: string): bool {
        const channel = root.channelTarget(name);
        return channel !== null && channel.visible && channel.enabled && channel.mutable;
    }

    function toggleMute(name: string): bool {
        const channel = root.channelTarget(name);
        if (!root.canToggleMute(name))
            return false;
        if (!channel.toggleMute())
            return false;
        root.record("action", "osd-channel", "toggle-" + name + "-mute", {
            channel: name
        });
        return true;
    }

    function registeredPaintRect(): rect {
        const entry = border.bulgeRegions["osd"] ?? null;
        return entry ? entry.rect : Qt.rect(0, 0, 0, 0);
    }

    function reportInteraction(name: string, action: string, target: string, value: var): void {
        const payload = { action: action, target: target };
        if (value !== undefined)
            payload.value = value;
        root.record("component", "osd-channel", name, payload);
    }

    function reportService(operation: string, phase: string, value: var): void {
        root.record("service", operation, "operated", {
            operation: operation,
            phase: phase,
            value: value
        });
    }

    function reportControl(groupIndex: int, optionIndex: int): void {
        const group = root.controls[groupIndex]?.label ?? "";
        const option = root.controls[groupIndex]?.options[optionIndex]?.label ?? "";
        root.record("scenario", "control", "applied", { group: group, option: option });
    }

    function applyControl(groupIndex: int, optionIndex: int): bool {
        if (groupIndex === 0 && optionIndex >= 0 && optionIndex <= 1) {
            WorkbenchServices.AudioService.microphoneAvailable = optionIndex === 0;
            root.reportControl(groupIndex, optionIndex);
            return true;
        }
        if (groupIndex === 1 && optionIndex >= 0 && optionIndex <= 1) {
            WorkbenchServices.BrightnessService.available = optionIndex === 0;
            root.reportControl(groupIndex, optionIndex);
            return true;
        }
        if (groupIndex === 2 && optionIndex >= 0 && optionIndex <= 3) {
            if (optionIndex === 3)
                WorkbenchState.OsdState.reset();
            else
                WorkbenchState.OsdState.show(["output", "microphone", "brightness"][optionIndex],
                    root.targetScreen);
            root.reportControl(groupIndex, optionIndex);
            return true;
        }
        return false;
    }

    function stepChannel(channelName: string, delta: int): bool {
        const channel = root.channelTarget(channelName);
        if (!channel || !channel.enabled || typeof channel.stepBy !== "function")
            return false;
        const changed = channel.stepBy(delta);
        if (changed)
            root.record("action", "osd-channel",
                (delta > 0 ? "increase-" : "decrease-") + channelName,
                { channel: channelName });
        return changed;
    }

    function presentChannel(channel: string): bool {
        if ((channel === "output" && !WorkbenchServices.AudioService.outputAvailable)
                || (channel === "brightness" && !WorkbenchServices.BrightnessService.available))
            return false;
        const shown = WorkbenchState.OsdState.show(channel, root.targetScreen);
        if (shown)
            root.record("action", "osd", "present-" + channel, { channel: channel });
        return shown;
    }

    function hidePresentation(): bool {
        WorkbenchState.OsdState.reset();
        root.record("action", "osd", "hide", {});
        return true;
    }

    readonly property var actionHandlers: ({
        "present-output": () => root.presentChannel("output"),
        "present-microphone": () => root.presentChannel("microphone"),
        "present-brightness": () => root.presentChannel("brightness"),
        "increase-output": () => root.stepChannel("output", 1),
        "decrease-output": () => root.stepChannel("output", -1),
        "increase-microphone": () => root.stepChannel("microphone", 1),
        "decrease-microphone": () => root.stepChannel("microphone", -1),
        "increase-brightness": () => root.stepChannel("brightness", 1),
        "decrease-brightness": () => root.stepChannel("brightness", -1),
        "toggle-output-mute": () => root.toggleMute("output"),
        "toggle-microphone-mute": () => root.toggleMute("microphone"),
        hide: () => root.hidePresentation()
    })

    function runAction(name: string): bool {
        return Object.prototype.hasOwnProperty.call(root.actionHandlers, name)
            ? root.actionHandlers[name]() : false;
    }

    function triggerAction(index: int): bool {
        return root.runAction(root.actions[index]?.trigger ?? "");
    }

    function key(targetName: string, name: string): bool {
        const resolver = root.integration.targets[targetName];
        if (typeof resolver !== "function" || !root.inputDriver
                || typeof root.inputDriver.key !== "function")
            return false;
        const target = resolver();
        if (!target)
            return false;
        return root.inputDriver.key(target, name) === true;
    }

    function resetStory(): void {
        root.resetEpoch += 1;
        const epoch = root.resetEpoch;
        root.observing = false;
        if (root.inputDriver && typeof root.inputDriver.cancel === "function")
            root.inputDriver.cancel();
        WorkbenchState.OsdState.observing = false;
        WorkbenchState.OsdState.reset();
        WorkbenchServices.AudioService.reset();
        WorkbenchServices.BrightnessService.reset();
        root.eventSequence = 0;
        Qt.callLater(function() {
            if (epoch !== root.resetEpoch)
                return;
            WorkbenchState.OsdState.observing = true;
            root.observing = true;
        });
    }

    function dumpTree(): void {
        root.inspectionReady({
            story: "osd-layer",
            fullscreen: root.fullscreen,
            targetScreen: screenFacts.name,
            screenRect: root.screenRect,
            osdKind: WorkbenchState.OsdState.kind,
            osdVisible: WorkbenchState.OsdState.visible,
            bulges: Object.keys(border.bulgeRegions),
            maskRects: border.maskRects.length,
            rollout: {
                host: "ShellBorder",
                silhouetteRect: osdSurface.rolloutPresentation.silhouetteRect,
                viewportRect: osdSurface.rolloutPresentation.viewportRect,
                paintRect: root.registeredPaintRect()
            },
            renderFacts: Object.assign(osdSurface.renderFacts(root), {
                handle: osdHandle.renderFacts(root)
            })
        });
    }

    onResetGenerationChanged: resetStory()
    Component.onCompleted: {
        WorkbenchState.OsdState.screen = root.targetScreen;
        resetStory();
    }

    Component.onDestruction: {
        root.observing = false;
        WorkbenchState.OsdState.observing = false;
        WorkbenchState.OsdState.reset();
        WorkbenchState.OsdState.screen = null;
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

        Text {
            anchors.centerIn: parent
            text: "Application preview"
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textMd
        }
    }

    QsmShellComponents.ScenePointer {
        id: scenePointer
    }

    QsmShellComponents.ShellBorder {
        id: border
        anchors.fill: parent
        pointer: scenePointer
        fullscreen: root.fullscreen
        leftEdge: Theme.frameThickness
        entryFilter: id => id === "osd"
        handle0: osdHandle.shaderHandle
    }

    QtObject {
        id: screenFacts
        objectName: "osd-preview-screen"
        readonly property string name: "osd-preview-screen"
        readonly property rect screenRect: root.screenRect
    }

    QtObject {
        id: sceneFacts
        readonly property bool fullscreen: root.fullscreen
        readonly property bool handlesArmed: !root.fullscreen
        readonly property bool focusMode: false
    }

    Osd.OsdSurface {
        id: osdSurface
        targetScreen: root.targetScreen
        scene: sceneFacts
        host: border
    }

    Osd.OsdHandle {
        id: osdHandle
        anchors.fill: parent
        surface: osdSurface
        scene: sceneFacts
    }

    Connections {
        target: root.outputTarget
        function onMoved(): void {
            root.reportInteraction("moved", "output-level", "output", root.outputTarget.value);
        }
        function onMuteToggled(): void {
            root.reportInteraction("mute-toggled", "output-mute", "output", undefined);
        }
    }

    Connections {
        target: root.microphoneTarget
        function onMoved(): void {
            root.reportInteraction("moved", "microphone-level", "microphone", root.microphoneTarget.value);
        }
        function onMuteToggled(): void {
            root.reportInteraction("mute-toggled", "microphone-mute", "microphone", undefined);
        }
    }

    Connections {
        target: root.brightnessTarget
        function onMoved(): void {
            root.reportInteraction("moved", "brightness-level", "brightness", root.brightnessTarget.value);
        }
    }

    Connections {
        target: WorkbenchServices.AudioService
        function onOperated(operation: string, phase: string, value: var): void {
            root.reportService(operation, phase, value);
        }
    }

    Connections {
        target: WorkbenchServices.BrightnessService
        function onOperated(operation: string, phase: string, value: var): void {
            root.reportService(operation, phase, value);
        }
    }

    Connections {
        target: WorkbenchState.OsdState
        function onKindChanged(): void {
            root.record("component", "osd-presentation", "presented", {
                kind: WorkbenchState.OsdState.kind,
                target: screenFacts.name
            });
        }
        function onVisibleChanged(): void {
            if (!WorkbenchState.OsdState.visible)
                root.record("component", "osd-presentation", "dismissed", {
                    target: screenFacts.name
                });
        }
    }
}
