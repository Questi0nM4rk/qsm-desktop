import QtQuick
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.modules.bar as Bar
import qs.services
import qs.state
import qs.theme

Item {
    id: root

    property string mode: "story"
    property var story: ({})
    property var composition: null
    property string component: ""
    property string variant: ""
    property string storyKey: ""
    property int viewportWidth: 980
    property int viewportHeight: 680
    property int resetGeneration: 0
    property bool interactive: false
    property var previewEnvironment: null

    // What each level's popout was LAST reported as, so a settled-state diff
    // can tell "still the same one" from "a different one replaced it".
    // `anchor` is the cell that opened it: kind is the component's identity and
    // a component can be on screen many times (every app row, every tray icon),
    // so kind alone cannot identify an entry.
    // The title is kept for a dismissal to name the entry that just closed.
    property var popoutState: ({})
    // The window-local native input driver the workbench injects. The same
    // object drives live preview and flow steps; a step never falls back to a
    // semantic action when it is absent.
    property var inputDriver: null

    // Whether a service change is something a person did. Off across a reset,
    // which writes the defaults back, and back on once those writes are done:
    // a story that claims "keep awake is now on" because the story started
    // that way is worse than silence.
    property bool observing: true

    // Scenario-owned state. Deliberately separate from the input path: these
    // are the environment facts the production scene reads, set as setup.
    property bool focusSuppressed: false
    readonly property bool suppressed: FullscreenService.fullscreen || focusSuppressed

    readonly property bool _isDelegatedStory: component === "osd-layer"
        || component === "notification-layer" || component === "action-menu"
        || component === "panel-tabs" || component === "notification-center" || component === "network-popout"
    readonly property var _loadedStory: _isDelegatedStory && storyLoader.status === Loader.Ready
        ? storyLoader.item : null
    readonly property var _storyControls: _isDelegatedStory
        ? _loadedStory ? _loadedStory.controls : [] : railControls
    readonly property var _storyActions: _isDelegatedStory
        ? _loadedStory ? _loadedStory.actions : [] : railActions
    readonly property var _storyIntegration: _isDelegatedStory
        ? _loadedStory ? _loadedStory.integration : null : railIntegration
    readonly property string storyStatus: _isDelegatedStory
        ? storyLoader.status === Loader.Ready && !!storyLoader.item ? "ready"
            : storyLoader.status === Loader.Error ? "error" : "loading"
        : component === "rail-popouts" ? "ready" : "failed"
    readonly property string storySource: _isDelegatedStory
        ? _loadedStory ? story.source : ""
        : component === "rail-popouts" ? "shell/modules/bar/BarPopouts.qml" : ""
    readonly property string storyError: _isDelegatedStory
        ? storyLoader.status === Loader.Error ? "could not load " + component + " story" : ""
        : component === "rail-popouts" ? "" : "unknown desktop story"
    readonly property real contentExtentWidth: _loadedStory
        ? _loadedStory.contentExtentWidth
        : _isDelegatedStory ? root.previewEnvironment?.screenRect?.width ?? root.viewportWidth : width
    readonly property real contentExtentHeight: _loadedStory
        ? _loadedStory.contentExtentHeight
        : _isDelegatedStory ? root.previewEnvironment?.screenRect?.height ?? root.viewportHeight : height

    Binding {
        target: QsmShellStyle.Style
        property: "backend"
        value: Theme
    }

    Binding {
        target: QsmShellStyle.Interaction
        property: "pointerSelects"
        value: !ShellState.keyboardOwnsSelection
    }

    readonly property rect railRect: Qt.rect(0, 0, Theme.reservedLeft, height)

    property alias parentController: popoutStack.parentController
    property alias childController: popoutStack.childController
    property alias parentPopout: popoutStack.parentPopout
    property alias childPopout: popoutStack.childPopout
    readonly property rect parentRect: popoutStack.parentRect
    readonly property rect childRect: popoutStack.childRect
    readonly property string parentKind: popoutStack.parentKind
    readonly property string childKind: popoutStack.childKind
    readonly property bool parentHeld: popoutStack.parentHeld
    readonly property bool childHeld: popoutStack.childHeld

    // Live input, through the same driver the flows use. Each option names a
    // real target and a real move; nothing here calls a controller or a
    // service, so the owner's pointer really travels the scene. Setup controls
    // stay in their own groups below.
    readonly property var controls: _storyControls
    readonly property var actions: _storyActions
    readonly property var integration: _storyIntegration

    readonly property var railControls: [{
        "label": "Pointer",
        "options": [
            { "label": "Rail", "target": "rail-actions", "event": "move" },
            { "label": "Body", "target": "parent-body", "event": "move" },
            { "label": "Colours", "target": "colours", "event": "move" },
            { "label": "Night light", "target": "night-light", "event": "move" },
            { "label": "Clean caches", "target": "clearcache", "event": "move" },
            { "label": "Child", "target": "child-body", "event": "move" },
            { "label": "Outside", "target": "outside", "event": "move" },
            { "label": "Main keyboard", "target": "main-keyboard", "event": "move" }
        ]
    }, {
        "label": "Suppression",
        "options": [
            { "label": "Interactive" },
            { "label": "Fullscreen" },
            { "label": "Focus mode" }
        ]
    }, {
        "label": "Motion",
        "options": [
            { "label": "Full motion" },
            { "label": "Reduced motion" }
        ]
    }, {
        "label": "Keyboard",
        "options": [
            { "label": "Released" },
            { "label": "Retained" }
        ]
    }]

    readonly property var railActions: [
        { "label": "Toggle awake", "trigger": "toggle-awake" },
        { "label": "Toggle night light", "trigger": "toggle-night-light" },
        { "label": "Warm night light", "trigger": "warm-night-light" },
        // ONE click, exactly as one click on the cell does: this arms the
        // sweep rather than firing it.
        { "label": "Clean caches", "trigger": "clean-cache" },
        { "label": "Pick color", "trigger": "pick-color" },
        { "label": "Close rollouts", "trigger": "close" }
    ]

    readonly property var railIntegration: ({
        events: ["opened", "dismissed", "interacted", "operated"],
        observables: {
            "parent-kind": () => root.parentKind,
            "child-kind": () => root.childKind,
            "parent-held": () => root.parentHeld,
            "child-held": () => root.childHeld,
            "parent-hovered": () => root.parentPopout.hovered,
            "child-hovered": () => root.childPopout.hovered,
            "parent-opening": () => root.parentPopout.animating
                && root.parentPopout.shouldBeActive,
            "parent-closing": () => root.parentPopout.animating
                && !root.parentPopout.shouldBeActive,
            "child-opening": () => root.childPopout.animating
                && root.childPopout.shouldBeActive,
            "child-closing": () => root.childPopout.animating
                && !root.childPopout.shouldBeActive,
            "parent-settled": () => !root.parentPopout.animating,
            "child-settled": () => !root.childPopout.animating,
            "parent-visible": () => root.parentPopout.visible,
            "child-visible": () => root.childPopout.visible,
            "awake": () => AwakeService.awake,
            "main-keyboard-disabled": () => MainKeyboardService.disabled,
            "main-keyboard-busy": () => MainKeyboardService.busy,
            "night-light-active": () => NightLightService.active,
            "night-light-strength": () => NightLightService.strength,
            "night-light-temperature": () => NightLightService.temperature,
            "night-light-readout": () => root.parentPopout.readout("warmth")
                ?? root.childPopout.readout("warmth"),
            "warmth-value": () => root.warmthControl()?.value ?? -1,
            "cache-busy": () => CacheService.busy,
            "cache-result": () => CacheService.lastResult,
            "color-busy": () => ColorPickService.busy,
            "color": () => ColorPickService.lastColor,
            "copied": () => ColorPickService.copied,
            "color-busy-line": () => root.pickHost().readout("busy-line"),
            "color-busy-visible": () => root.pickHost().readout("busy-visible"),
            "color-copy-feedback": () => root.pickHost().readout("copy-feedback"),
            "suppressed": () => root.suppressed,
            "keyboard-retained": () => ShellState.keyboardGrab.length > 0,
            "reduced-motion": () => ShellState.reducedMotion,
            "input-simulated": () => root.inputDriver?.simulated === true,
            "input-error": () => root.inputDriver?.error ?? ""
        },
        targets: {
            "scene": () => root,
            "rail-actions": () => railEntry,
            "awake": () => root.quickAction("awake"),
            "main-keyboard": () => root.quickAction("main-keyboard"),
            "night-light": () => root.quickAction("night-light"),
            "colours": () => root.quickAction("colours"),
            "clearcache": () => root.quickAction("clearcache"),
            "warmth": () => root.warmthControl(),
            "pick-colour": () => root.pickControl(),
            "parent-body": () => root.parentPopout.visible ? root.parentPopout.bodyItem : null,
            "child-body": () => root.childPopout.visible ? root.childPopout.bodyItem : null,
            "outside": () => outsideArea
        },
        idle: () => !ColorPickService.busy && !CacheService.busy && !MainKeyboardService.busy
            && [root.parentPopout, root.childPopout].every(item => !item.animating
                && !(item.keepOpen && !item.hovered))
    })

    signal eventRecorded(var record)
    signal inspectionReady(var inspection)

    width: viewportWidth
    height: viewportHeight

    function quickAction(name: string): var {
        return root.parentPopout.control(name);
    }

    function warmthControl(): var {
        return root.childPopout.control("warmth") ?? root.parentPopout.control("warmth");
    }

    function pickHost(): var {
        return root.childPopout.control("pick-colour") !== null ? root.childPopout
            : root.parentPopout;
    }

    function pickControl(): var {
        return root.childPopout.control("pick-colour")
            ?? root.parentPopout.control("pick-colour");
    }

    // The item a level actually loaded, and null while a different kind is up,
    // so an observer never attaches to a tier that does not exist.
    function tier(level: string, kind: string): var {
        const host = level === "child" ? root.childPopout : root.parentPopout;
        return host.controller.kind === kind ? host.currentBody : null;
    }

    // The controller's own text, which is the same text a dismissal names.
    function levelTitle(level: string): string {
        const host = level === "child" ? root.childPopout : root.parentPopout;
        return host.controller.title;
    }

    // A thing a person did to a real control. `kind` is the component's own
    // identity and `action` what it did, so no two kinds are told apart by a
    // shared label.
    function reportInteraction(kind: string, action: string, title: string,
            value: var, target: var): void {
        if (root._isDelegatedStory || !root.observing)
            return;
        const payload = { "kind": kind, "action": action, "title": title };
        if (typeof target === "string" && target.length > 0)
            payload["target"] = target;
        if (value !== undefined)
            payload["value"] = value;
        eventRecorded({ "origin": "component", "kind": kind,
            "name": "interacted", "payload": payload });
    }

    // What an in-memory stand-in then did about it. A different origin, so the
    // intent and its outcome never read as the same fact twice.
    function reportService(operation: string, phase: string, value: var): void {
        if (root._isDelegatedStory || !root.observing)
            return;
        eventRecorded({ "origin": "service", "kind": operation, "name": "operated",
            "payload": { "operation": operation, "phase": phase, "value": value } });
    }

    function entryVisible(id: string): bool {
        return !root.suppressed;
    }

    function queuePopoutReport(level: string, controller: var): void {
        if (root._isDelegatedStory)
            return;
        Qt.callLater(function() {
            root.reportPopout(level, controller);
        });
    }

    function reportPopout(level: string, controller: var): void {
        if (root._isDelegatedStory)
            return;
        const open = controller.kind.length > 0;
        const prior = root.popoutState[level] !== undefined ? root.popoutState[level]
            : { "kind": "", "anchor": null, "title": "" };
        const anchor = open ? controller.anchor : null;
        if (prior.kind === (open ? controller.kind : "") && prior.anchor === anchor)
            return;
        const title = open ? controller.title : prior.title;
        root.popoutState[level] = {
            "kind": open ? controller.kind : "",
            "anchor": anchor,
            "title": title
        };
        eventRecorded({ "origin": "component",
            "kind": open ? controller.kind : prior.kind,
            "name": open ? "opened" : "dismissed",
            "payload": { "level": level, "kind": controller.kind, "title": title } });
    }

    function resetStory(): void {
        if (root._isDelegatedStory)
            return;
        observing = false;
        if (inputDriver && typeof inputDriver.cancel === "function")
            inputDriver.cancel();
        focusSuppressed = false;
        popoutStack.childController.dismiss();
        popoutStack.parentController.dismiss();
        root.popoutState = ({});
        ShellState.reset();
        FullscreenService.reset();
        AwakeService.reset();
        MainKeyboardService.reset();
        NightLightService.reset();
        CacheService.reset();
        ColorPickService.reset();
        Qt.callLater(function() { root.observing = true; });
    }

    // The scenario groups set up state rather than driving a control, and they
    // are recorded as such: an `expectEvent` reading one of these can never be
    // satisfied by something a person did to the shell.
    function reportControl(group: string, option: string): void {
        eventRecorded({ "origin": "scenario", "kind": "control", "name": "applied",
            "payload": { "group": group, "option": option } });
    }

    function applyControl(groupIndex: int, optionIndex: int): bool {
        if (root._isDelegatedStory)
            return root._loadedStory ? root._loadedStory.applyControl(groupIndex, optionIndex) : false;
        const group = root.controls[groupIndex]?.label ?? "";
        const option = root.controls[groupIndex]?.options[optionIndex]?.label ?? "";
        if (groupIndex === 1 && optionIndex >= 0 && optionIndex <= 2) {
            FullscreenService.fullscreen = optionIndex === 1;
            root.focusSuppressed = optionIndex === 2;
            root.reportControl(group, option);
            return true;
        }
        if (groupIndex === 2 && optionIndex >= 0 && optionIndex <= 1) {
            ShellState.reducedMotion = optionIndex === 1;
            root.reportControl(group, option);
            return true;
        }
        if (groupIndex === 3 && optionIndex >= 0 && optionIndex <= 1) {
            ShellState.keyboardGrab = optionIndex === 1 ? "rail-popouts" : "";
            root.reportControl(group, option);
            return true;
        }
        return false;
    }

    function triggerAction(index: int): bool {
        if (root._isDelegatedStory)
            return root._loadedStory ? root._loadedStory.triggerAction(index) : false;
        const trigger = root.actions[index]?.trigger ?? "";
        let applied = false;
        if (trigger === "toggle-awake")
            applied = root.inputDriver?.click(root.quickAction("awake")) === true;
        else if (trigger === "toggle-night-light")
            applied = root.inputDriver?.click(root.quickAction("night-light")) === true;
        else if (trigger === "warm-night-light")
            applied = root.inputDriver?.wheel(root.warmthControl(), 0, 120) === true;
        else if (trigger === "clean-cache")
            applied = root.inputDriver?.click(root.quickAction("clearcache")) === true;
        else if (trigger === "pick-color")
            applied = root.inputDriver?.click(root.pickControl()) === true;
        else if (trigger === "close") {
            popoutStack.childController.dismiss();
            popoutStack.parentController.dismiss();
            applied = true;
        } else
            return false;
        if (!applied)
            return false;
        // What was ASKED for, from the toolbar that asked. The control answers
        // for itself, so this never claims the work happened.
        eventRecorded({ "origin": "action", "name": trigger, "payload": {} });
        return true;
    }

    function dumpTree(): void {
        if (root._isDelegatedStory) {
            if (root._loadedStory)
                root._loadedStory.dumpTree();
            return;
        }
        inspectionReady({
            "story": storyKey,
            "popout": root.parentKind,
            "subPopout": root.childKind,
            "bulges": Object.keys(border.bulgeRegions),
            "maskRects": border.maskRects.length
        });
    }

    onResetGenerationChanged: resetStory()
    onComponentChanged: {
        if (!root._isDelegatedStory)
            return;
        Qt.callLater(function() {
            if (!root._isDelegatedStory)
                return;
            popoutStack.childController.dismiss();
            popoutStack.parentController.dismiss();
            root.popoutState = ({});
        });
    }

    Connections {
        enabled: !root._isDelegatedStory
        target: popoutStack.parentController
        function onAnchorChanged(): void {
            root.queuePopoutReport("parent", popoutStack.parentController);
        }
        function onKindChanged(): void {
            root.queuePopoutReport("parent", popoutStack.parentController);
        }
    }

    Connections {
        enabled: !root._isDelegatedStory
        target: popoutStack.childController
        function onAnchorChanged(): void {
            root.queuePopoutReport("child", popoutStack.childController);
        }
        function onKindChanged(): void {
            root.queuePopoutReport("child", popoutStack.childController);
        }
    }

    // The quick-action cells, named by the column that owns them. One click on
    // a live cell and one simulated click on that same cell produce these same
    // records, because both go through the cell's own handlers.
    Connections {
        enabled: !root._isDelegatedStory
        target: root.tier("parent", "actions")

        function onInteracted(kind: string, action: string, title: string): void {
            root.reportInteraction(kind, action, title);
        }
    }

    Connections {
        enabled: !root._isDelegatedStory
        target: root.tier("child", "colorpick")

        function onInteracted(action: string, detail: var): void {
            root.reportInteraction("colorpick", action, root.levelTitle("child"),
                detail.value, detail.target);
        }
    }

    // The warmth slider's own gesture end: one record for a drag, for a wheel
    // notch and for a key that moved it, because the control does not claim
    // which of the three it was.
    Connections {
        enabled: !root._isDelegatedStory
        target: root.warmthControl()

        function onCommitted(): void {
            root.reportInteraction("nightlight", "warmth", root.levelTitle("child"),
                Math.round(NightLightService.strength * 100));
        }
    }

    Connections {
        enabled: !root._isDelegatedStory
        target: AwakeService
        function onAwakeChanged(): void {
            root.reportService("keepawake", "state", AwakeService.awake);
        }
    }

    Connections {
        enabled: !root._isDelegatedStory
        target: MainKeyboardService
        function onOperated(operation: string, phase: string, value: var): void {
            root.reportService(operation, phase, value);
        }
    }

    Connections {
        enabled: !root._isDelegatedStory
        target: NightLightService
        function onActiveChanged(): void {
            root.reportService("nightlight", "state", NightLightService.active);
        }
        function onTemperatureChanged(): void {
            root.reportService("nightlight", "warmth",
                Math.round(NightLightService.strength * 100));
        }
    }

    Connections {
        enabled: !root._isDelegatedStory
        target: CacheService
        function onOperated(operation: string, phase: string, value: string): void {
            root.reportService(operation, phase, value);
        }
    }

    Connections {
        enabled: !root._isDelegatedStory
        target: ColorPickService
        function onOperated(operation: string, phase: string, value: string): void {
            root.reportService(operation, phase, value);
        }
    }

    Component.onCompleted: {
        if (!root._isDelegatedStory)
            resetStory();
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.band
    }

    QsmShellComponents.ScenePointer {
        id: scenePointer
        enabled: !root._isDelegatedStory
        onPointChanged: ShellState.keyboardOwnsSelection = false
    }

    QsmShellComponents.ShellBorder {
        id: border

        anchors.fill: parent
        visible: !root._isDelegatedStory
        enabled: !root._isDelegatedStory
        leftEdge: Theme.reservedLeft
        pointer: scenePointer
        fullscreen: FullscreenService.fullscreen
        entryFilter: root.entryVisible
    }

    Column {
        visible: !root._isDelegatedStory
        enabled: !root._isDelegatedStory
        x: (Theme.reservedLeft - Theme.railWidth) / 2
        y: Theme.space6 * 2
        width: Theme.railWidth
        spacing: Theme.space1

        Bar.RailEntry {
            id: railEntry

            width: parent.width
            icon: "zap"
            compact: true
            interactive: true
            popouts: popoutStack.parentController
            popoutKind: "actions"
            popoutTitle: "Quick actions"
            onInteraction: action => root.reportInteraction(popoutKind, action, popoutTitle)
        }
    }

    // An inert patch of scene far from the rail and every rollout: the place a
    // pointer goes when a scenario means "left everything".
    Item {
        id: outsideArea

        enabled: !root._isDelegatedStory
        x: root.width * 0.72
        y: root.height * 0.78
        width: Theme.space6 * 4
        height: Theme.space6 * 4
    }

    Bar.RailPopoutStack {
        id: popoutStack

        anchors.fill: parent
        visible: !root._isDelegatedStory
        enabled: !root._isDelegatedStory
        host: border
        hostBandArea: root.railRect
        keyboardRetained: ShellState.keyboardGrab.length > 0
        suppressed: root._isDelegatedStory || root.suppressed
        onInteracted: (kind, action, payload) => {
            if (root.observing && !root._isDelegatedStory)
                root.eventRecorded({ origin: "component", kind: kind, name: "interacted",
                    payload: Object.assign({ action: action }, payload) });
        }
    }

    Loader {
        id: storyLoader
        active: root._isDelegatedStory
        source: root.component === "notification-layer" ? "NotificationStory.qml"
            : root.component === "network-popout" ? "NetworkPopoutStory.qml"
            : root.component === "notification-center" ? "NotificationCenterStory.qml"
            : root.component === "action-menu" ? "ActionMenuStory.qml"
            : root.component === "panel-tabs" ? "PanelTabsStory.qml" : "OsdStory.qml"
        width: root.previewEnvironment?.screenRect?.width ?? root.viewportWidth
        height: root.previewEnvironment?.screenRect?.height ?? root.viewportHeight
        onLoaded: {
            // `item` is typed as the loader's common base, so every hand-off
            // goes through an untyped reference: a direct write resolves
            // against that base instead of against the story that loaded.
            var story = storyLoader.item
            story.previewEnvironment = Qt.binding(() => root.previewEnvironment)
            story.inputDriver = Qt.binding(() => root.inputDriver)
            story.interactive = Qt.binding(() => root.interactive)
            story.resetGeneration = Qt.binding(() => root.resetGeneration)
            story.viewportWidth = Qt.binding(() => root.viewportWidth)
            story.viewportHeight = Qt.binding(() => root.viewportHeight)
            // The catalog calls it `variant`; that is a QML type name, so the
            // story receives it under a name it can declare.
            if (root._isDelegatedStory && story.menuVariant !== undefined)
                story.menuVariant = Qt.binding(() => root.variant)
        }
    }

    Connections {
        target: storyLoader.item
        function onEventRecorded(record) { root.eventRecorded(record) }
        function onInspectionReady(inspection) { root.inspectionReady(inspection) }
    }
}
