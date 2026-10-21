import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.components
import qs.services
import qs.state
import qs.theme

// Launcher content (07-launcher): search field at the BOTTOM, results above
// (at most Theme.launcherMaxRows rows),
// keyboard-first. '>' enters command mode: >calc (live math via qalc, Enter
// copies), >kill (windows + processes, Enter kills — deliberate, no confirm),
// >theme (a horizontal carousel instead of the row list — Left/Right
// highlight, Enter applies instantly, same as click). A bare '>' lists all
// commands. `>clip` is not a mode: clipboard history is its own
// surface, and keeping the mode too would be two routes to one feature.
// App ranking = fuzzy subsequence + frecency.
Item {
    id: root

    property string query
    property var commandNames: ["calc", "kill", "theme", "action"]
    property var actionIds: null
    property bool persistRanking: true
    property bool applicationsEnabled: true
    // Injected so the desktop reads its own services and a story can hand this
    // surface isolated fixtures instead of the real hardware.
    property var networkBackend: NetworkService
    property var bluetoothBackend: BluetoothService
    property string expandedNetworkId: ""
    property string networkPassword: ""
    readonly property Item searchTarget: search
    readonly property Item menuTarget: resultsList
    readonly property Item editorTarget: resultsList.currentItem?.valueEditor ?? null
    signal interacted(string action, var detail)

    readonly property var commandDefs: [
        { cmd: "calc", icon: "sparkle", desc: "Live math — Enter copies the result" },
        { cmd: "kill", icon: "power", desc: "Kill a window or process — no confirm" },
        { cmd: "theme", icon: "mountain", desc: "Switch theme" },
        { cmd: "action", icon: "zap", desc: "Quick controls" }
    ].filter(def => root.commandNames.includes(def.cmd))
    // The keyboard view mirrors only actions that can safely run without the
    // rail's pointer-specific confirmation or screen takeover. `group` names
    // the section the action's row sorts under (>action category headers).
    readonly property var actionDefs: [
        { id: "network", group: "hardware", icon: NetworkService.glyph, label: "Network settings", sub: "Open NetworkManager settings" },
        { id: "bluetooth", group: "hardware", icon: "bluetooth", label: "Bluetooth settings", sub: "Open Bluetooth settings" },
        { id: "sound", group: "hardware", icon: "volume", label: "Sound settings", sub: "Output, input and levels" },
        { id: "brightness", group: "quick", icon: "brightness", label: "Brightness", sub: "Adjust screen level or dim and restore" },
        { id: "power", group: "hardware", icon: "battery", label: "Power profiles", sub: PowerProfileService.available ? (PowerProfileService.profile || "Choose profile") : "Unavailable" },
        {
            id: "main-keyboard", kind: "main-keyboard", group: "quick", icon: MainKeyboardService.glyph,
            label: MainKeyboardService.actionLabel, sub: "Disable or enable the built-in keyboard"
        },
        {
            id: "awake",
            group: "quick",
            icon: AwakeService.awake ? "coffee-full" : "coffee-empty",
            label: "Keep awake",
            sub: AwakeService.awake ? "On · allow sleep" : "Off · inhibit idle and sleep"
        },
        {
            id: "nightlight",
            group: "quick",
            icon: NightLightService.active ? "moon" : "brightness",
            label: "Night light",
            sub: `${NightLightService.active ? "On" : "Off"} · ${Math.round(NightLightService.strength * 100)}% warm`
        },
        { id: "panel", group: "system", icon: "layers", label: "Panel tabs", sub: "Dashboard, notifications and more" },
        { id: "notifications", group: "system", icon: "bell", label: "Notifications", sub: "Search and manage notifications" },
        { id: "session", group: "system", icon: "power", label: "Session menu", sub: "Lock, logout and power" },
        { id: "cache", group: "tools", icon: "trash-2", label: "Clean caches", sub: `${CacheService.lastResult || "Confirmation required"}` },
        { id: "colorpick", group: "tools", icon: "pipette", label: "Pick a colour", sub: `${ColorPickService.lastColor || "Confirmation required"}` }
    ]

    // Section order for >action: quick shortcut toggles first, then hardware
    // settings, then surface navigation, destructive/takeover tools last.
    readonly property var actionGroups: [
        { id: "quick", label: "Quick actions" },
        { id: "hardware", label: "Hardware" },
        { id: "system", label: "System" },
        { id: "tools", label: "Tools" }
    ]

    readonly property var panelDefs: ShellState.panelTabs.map(tab => ({
        id: tab,
        label: tab.charAt(0).toUpperCase() + tab.slice(1),
        sub: ShellState.panelTab === tab ? "Selected panel tab" : "Open panel tab"
    }))

    // A detail path is deliberately local to this surface. The parent query
    // and cursor are snapshots, so returning never depends on a re-filtered
    // or competing modal having changed the visible list.
    property string detailId: ""
    property string parentQuery: ""
    property string parentActionId: ""
    property string restoredParentActionId: ""
    property string confirmId: ""
    property string selectedIdentity: ""
    property string expandedAudioId: ""
    readonly property bool expandedLevelAvailable: root.expandedAudioId.length > 0
        && !!root.levelControls && !!root.levelControls[root.expandedAudioId]
        && root.levelControls[root.expandedAudioId].available()
    onExpandedLevelAvailableChanged: {
        if (root.expandedAudioId && !expandedLevelAvailable) root.closeEditor();
    }
    property string inputRegion: "search"

    // Quickshell's Bluetooth objects are not declaratively typed, so the
    // adapter and its devices are reached through the service that owns them.
    function bluetoothAdapterObject(): var {
        return root.bluetoothBackend.available ? root.bluetoothBackend.adapter : null;
    }

    function bluetoothDevicesList(): var {
        return (root.bluetoothBackend.devices ?? []).slice()
            .sort((left, right) => (right.connected ? 1 : 0) - (left.connected ? 1 : 0));
    }
    readonly property bool inDetail: detailId.length > 0

    readonly property string mode: {
        if (!query.startsWith(">"))
            return "apps";

        const word = query.slice(1).split(" ")[0];
        return commandDefs.some(def => def.cmd === word) ? word : "commands";
    }
    // Text after '>cmd ' — the command's own argument/filter.
    readonly property string rest: {
        const space = query.indexOf(" ");
        return space === -1 ? "" : query.slice(space + 1);
    }

    function filterDetailRows(rows) {
        const needle = rest.trim();
        return needle.length === 0 ? rows
            : rows.filter(row => QsmShellComponents.Fuzzy.score(needle, `${row.label} ${row.sub}`) >= 0);
    }

    // --- apps (frecency-boosted fuzzy) -------------------------------------

    readonly property var indexedEntries: !root.applicationsEnabled ? [] : DesktopEntries.applications.values
        .map(entry => ({
            entry: entry,
            text: `${entry.name} ${entry.genericName} ${entry.keywords.join(" ")}`
        }))

    // qmllint disable unqualified
    function frecencyBoost(entryId: string): real {
        const record = rankingFile.item?.counts[entryId];
        if (!record)
            return 0;

        const ageDays = (Date.now() - record.last) / 86400000;
        return record.n * Math.max(0.2, 1 - ageDays / 30);
    }

    function bumpFrecency(entryId: string): void {
        if (!rankingFile.item)
            return;
        const next = Object.assign({}, rankingFile.item.counts);
        const record = next[entryId] ?? { n: 0, last: 0 };
        next[entryId] = { n: record.n + 1, last: Date.now() };
        rankingFile.item.counts = next;
    }
    // qmllint enable unqualified

    // --- mode data ----------------------------------------------------------

    property string calcResult: ""
    // Until a probe says otherwise, assume the tool is there: the alternative
    // is every fresh launcher flashing a "not installed" row for one frame.
    property bool calcAvailable: true
    property var killTargets: []

    // >theme carousel selection (07 amended: caelestia numbers + carousel).
    // Keyboard-driven from the search field's Left/Right handlers below;
    // the vertical resultsList's currentIndex is meaningless in this mode.
    property int themeIndex: 0
    readonly property int selectedIndex: mode === "theme" ? themeIndex
        : !root.selectedIdentity ? -1
            : root.results.findIndex(item => root.resultIdentity(item) === root.selectedIdentity)

    // The body keeps ONE height whatever the result count; results scroll
    // inside it, so the UI never jumps. The list gap is the standard one: a
    // kill list's wider gap scrolls, it never resizes the body.
    readonly property real preferredBodyHeight: Theme.launcherMaxRows * Theme.launcherRowHeight
        + (Theme.launcherMaxRows - 1) * QsmShellStyle.Style.space1
        + QsmShellStyle.Style.size("TextField", "lg") + QsmShellStyle.Style.space3 + QsmShellStyle.Style.rolloutPadding * 2

    onModeChanged: {
        if (mode === "kill")
            killProbe.running = true;
        else if (mode === "calc")
            calcTimer.restart();
        else if (mode === "theme") {
            const current = results.findIndex(item => item.data === Theme.current);
            themeIndex = current >= 0 ? current : 0;
        }
    }

    Connections {
        target: ShellState
        function onLauncherSeedChanged(): void {
            if (ShellState.modal === "launcher" && ShellState.launcherSeed.length > 0)
                root.open();
        }
        function onModalChanged(): void {
            if (ShellState.modal !== "launcher") {
                root.expandedAudioId = "";
                root.expandedNetworkId = "";
                root.networkPassword = "";
                root.confirmId = "";
                root.inputRegion = "search";
                selectionSync.stop();
                focusSync.stop();
                layoutSync.stop();
            }
        }
    }
    onResultsChanged: {
        if (mode === "theme")
            themeIndex = Math.min(themeIndex, Math.max(0, results.length - 1));
        if (selectionSync) selectionSync.restart();
    }
    onRestChanged: {
        if (mode === "calc")
            calcTimer.restart();
    }

    // The rows each detail view owns, keyed by the detail's id. A view that is
    // not listed here falls back to its action definition, which is what every
    // simple route (brightness, awake, panel) already is.
    readonly property var detailBuilders: ({
        "panel": () => root.panelDefs.map(tab => ({
            kind: "panel-tab", icon: tab.id === ShellState.panelTab ? "check" : "layers",
            label: tab.label, sub: tab.sub, data: tab.id
        })),
        "sound": () => [
            { kind: "audio-level", icon: "volume", label: "Output volume", sub: "Adjust output level", data: "output-volume" },
            { kind: "audio", icon: "volume-muted", label: "Mute output", sub: "Toggle output mute", data: "output-mute" },
            { kind: "audio", icon: "microphone-muted", label: "Mute microphone", sub: "Toggle microphone mute", data: "mic-mute" },
            { kind: "audio-level", icon: "microphone", label: "Microphone level", sub: "Adjust input level", data: "microphone-volume" }
        ].concat(AudioService.sinks.map(device => ({ kind: "device", icon: "volume", label: device.nickname || device.description || device.name, sub: device.id === (AudioService.sink?.id ?? -1) ? "Current output" : "Set output", data: device })))
            .concat(AudioService.sources.map(device => ({ kind: "device", icon: "microphone", label: device.nickname || device.description || device.name, sub: device.id === (AudioService.source?.id ?? -1) ? "Current input" : "Set input", data: device, input: true })))
            .concat([{ kind: "delegate", icon: "volume", label: "Sound settings", sub: "Open mixer", data: "mixer" }]),
        "network": () => [
            { kind: "network", identity: "wifi-rescan", icon: "rotate-cw", label: "Rescan Wi-Fi networks", sub: "Refresh available networks", data: "network-rescan" },
            { kind: "network", identity: "wifi-radio", icon: root.networkBackend.wifiEnabled ? "wifi" : "wifi-off", label: root.networkBackend.wifiEnabled ? "Wi-Fi radio on" : "Wi-Fi radio off", sub: root.networkBackend.wifiEnabled ? "Turn Wi-Fi off (confirmation required)" : "Turn Wi-Fi on", data: root.networkBackend.wifiEnabled ? "wifi-off" : "wifi-on", confirmId: "wifi-off" }
        ].concat((root.networkBackend.networks ?? []).map(network => ({
            kind: "wifi-network", identity: network.ssid,
            icon: "wifi",
            label: network.ssid,
            sub: network.active ? `${root.networkBackend.internetDescription ?? "Connected"} · Enter to disconnect`
                : network.enterprise ? "Enterprise · managed by NetworkManager"
                : network.secure ? "Secured · Enter to connect" : `Open · ${network.signal}% · Enter to connect`,
            data: network.ssid
        }))).concat(!root.networkBackend.wifiAvailable
            ? [{ kind: "hint", icon: "wifi-off", label: "Wi-Fi unavailable", sub: "No Wi-Fi adapter detected", data: "wifi-unavailable" }]
            : root.networkBackend.wifiEnabled && (root.networkBackend.networks ?? []).length === 0
                ? [{ kind: "hint", icon: "wifi", label: "No networks in range", sub: "Rescan to check again", data: "wifi-empty" }]
                : []).concat([
            { kind: "network", identity: "vpn", icon: "network", label: root.networkBackend.vpnAvailable ? (root.networkBackend.vpnActive ? "VPN on" : "VPN off") : "VPN unavailable", sub: root.networkBackend.vpnAvailable ? "Toggle current VPN connection" : "No VPN profile found", data: "vpn", confirmId: root.networkBackend.vpnActive ? "vpn-off" : "" },
            { kind: "delegate", icon: "network", label: "Network settings", sub: "Protected connections and passwords stay with NetworkManager", data: "network" }
        ]),
        "bluetooth": () => [
            { kind: "bluetooth", identity: "adapter-power", icon: "bluetooth", label: "Bluetooth radio", sub: "Toggle adapter power", data: "adapter" },
            { kind: "bluetooth", identity: "discovery", icon: "motion", label: "Device discovery", sub: "Toggle device discovery", data: "discover" }
        ].concat(root.bluetoothDevicesList().map(device => [
            { kind: "bluetooth-device", identity: device.address, icon: device.connected ? "bluetooth-connected" : "bluetooth", label: device.name || device.address, sub: device.connected ? "Disconnect" : device.paired ? "Connect" : "Pair in Bluetooth settings", data: device },
            ...(device.paired ? [{ kind: "bluetooth-forget", identity: `forget-${device.address}`, icon: "trash-2", label: `Forget ${device.name || device.address}`, sub: "Remove paired device", data: device, confirmId: `forget-${device.address}` }] : [])
        ]).reduce((all, rows) => all.concat(rows), []))
            .concat(!root.bluetoothBackend.available
                ? [{ kind: "hint", icon: "bluetooth", label: "Bluetooth unavailable", sub: "No adapter detected", data: "bluetooth-unavailable" }]
                : root.bluetoothDevicesList().length === 0
                    ? [{ kind: "hint", icon: "bluetooth", label: "No devices", sub: "Enable discovery to find nearby devices", data: "bluetooth-empty" }] : [])
            .concat([{ kind: "delegate", icon: "bluetooth", label: "Bluetooth settings", sub: "Pairing and protected setup stay with BlueZ manager", data: "bluetooth" }]),
        "brightness": () => [
            { kind: "audio-level", icon: "brightness", label: "Screen brightness", sub: "Adjust screen level", data: "brightness-level" },
            { kind: "action-detail", icon: "brightness", label: "Dim or restore", sub: "Toggle minimum and previous brightness", data: "brightness" }
        ],
        "nightlight": () => [
            { kind: "action-detail", icon: NightLightService.active ? "moon" : "brightness", label: NightLightService.active ? "Turn night light off" : "Turn night light on", sub: "Toggle night light", data: "toggle" },
            { kind: "level", icon: "brightness", label: `Warmth · ${Math.round(NightLightService.strength * 100)}%`, sub: "Increase warmth", data: "up" },
            { kind: "level", icon: "brightness", label: "Decrease warmth", sub: "Cool the screen", data: "down" }
        ],
        "power": () => ["power-saver", "balanced", "performance"].map(profile => ({ kind: "profile", icon: PowerProfileService.iconFor(profile), label: profile, sub: PowerProfileService.profile === profile ? "Current profile" : "Set profile", data: profile }))
    })

    function detailRows(): var {
        const build = root.detailBuilders[root.detailId];
        if (build) return root.filterDetailRows(build());
        const action = root.actionDefs.find(candidate => candidate.id === root.detailId);
        if (!action) return [];
        return root.filterDetailRows([{
            kind: "action-detail", icon: action.icon, label: action.label,
            sub: root.confirmId === action.id ? root.confirmationText(action.id) : action.sub,
            data: action.id
        }]);
    }

    readonly property var results: {
        if (root.inDetail)
            return root.detailRows();

        switch (mode) {
        case "commands": {
            const word = query.slice(1).split(" ")[0];
            return commandDefs
                .filter(def => word.length === 0 || QsmShellComponents.Fuzzy.score(word, def.cmd) >= 0)
                .map(def => ({ kind: "command", icon: def.icon, label: `>${def.cmd}`, sub: def.desc, data: def.cmd }));
        }
        case "calc":
            if (!calcAvailable)
                return [{ kind: "hint", icon: "alert-triangle", label: "qalc is not installed",
                    sub: "Install libqalculate to use >calc" }];

            return rest.trim().length === 0
                ? [{ kind: "hint", icon: "sparkle", label: "Type an expression", sub: "qalc evaluates live" }]
                : [{ kind: "calc", icon: "sparkle", label: calcResult || "…", sub: rest }];
        case "kill":
            return killTargets
                .map(target => ({ target: target, score: QsmShellComponents.Fuzzy.score(rest, target.label) }))
                .filter(item => item.score >= 0)
                .sort((left, right) => right.score - left.score)
                .slice(0, 8)
                .map(item => ({
                    kind: item.target.kind, icon: "power",
                    label: item.target.label, sub: item.target.sub, data: item.target.data
                }));
        case "theme":
            // One row per installed theme (N-theme law) with its wallpaper
            // as the thumbnail; applies instantly on Enter/click.
            return Theme.themes
                .filter(theme => QsmShellComponents.Fuzzy.score(rest, theme.name) >= 0)
                .map(theme => ({
                    kind: "theme", icon: "mountain", label: theme.name,
                    sub: Theme.current === theme.id ? "current" : "",
                    thumb: theme.wallpaper.length > 0
                        ? "file://" + Quickshell.shellPath(theme.wallpaper) : "",
                    data: theme.id
                }));
        case "action": {
            // Fuzzy-filter, then bucket by GROUP (stable section order). The
            // header is pushed AFTER its rows: the list is BottomToTop (index0
            // renders at the BOTTOM, against the search field), so a header
            // before its items would sit UNDER them — reading upward, a group
            // must read as items, THEN its label. A group with no match
            // vanishes whole, headers included.
            const scored = actionDefs
                .filter(action => root.actionIds === null || root.actionIds.includes(action.id))
                .map((action, defIndex) => ({ action: action, score: QsmShellComponents.Fuzzy.score(rest, `${action.label} ${action.sub}`), defIndex: defIndex }))
                .filter(item => item.score >= 0)
                .sort((left, right) => right.score - left.score
                    || left.action.label.length - right.action.label.length
                    || left.defIndex - right.defIndex);
            const rows = [];
            for (const group of root.actionGroups) {
                const inGroup = scored.filter(item => item.action.group === group.id);
                if (inGroup.length === 0)
                    continue;
                for (const item of inGroup)
                    rows.push({
                        kind: item.action.kind ?? "action", icon: item.action.icon, label: item.action.label,
                        sub: item.action.sub, data: item.action.id
                    });
                rows.push({ kind: "header", label: group.label, sub: "" });
            }
            return rows;
        }
        default: {
            const needle = query.trim();
            return indexedEntries
                .map((item, index) => ({
                    item: item,
                    index: index,
                    score: QsmShellComponents.Fuzzy.score(needle, item.text)
                }))
                .filter(scored => scored.score >= 0)
                .map(scored => ({
                    scored: scored,
                    rank: scored.score + frecencyBoost(scored.item.entry.id)
                }))
                // Equal ranks: the SHORTER name wins ("Foot" before "Foot
                // Server" on "foot"), then the original index — QML's sort is
                // not stable, and an unbroken tie reshuffles per keystroke.
                .sort((left, right) => right.rank - left.rank
                    || left.scored.item.entry.name.length - right.scored.item.entry.name.length
                    || left.scored.index - right.scored.index)
                .slice(0, 8)
                .map(ranked => ({
                    kind: "app",
                    appIcon: ranked.scored.item.entry.icon,
                    label: ranked.scored.item.entry.name,
                    sub: ranked.scored.item.entry.genericName || ranked.scored.item.entry.comment || "",
                    data: ranked.scored.item.entry
                }));
        }
        }
    }

    // The seed chooses the mode, not focus: opening always starts with typing.
    function open(): void {
        const seed = ShellState.launcherSeed;
        ShellState.launcherSeed = "";
        query = seed;
        detailId = "";
        parentQuery = "";
        parentActionId = "";
        restoredParentActionId = "";
        confirmId = "";
        expandedAudioId = "";
        expandedNetworkId = "";
        networkPassword = "";
        inputRegion = "search";
        search.text = seed;
        root.selectIndex(root.firstSelectable(0));
        focusSync.restart();
    }

    function close(): void {
        detailId = "";
        parentQuery = "";
        parentActionId = "";
        restoredParentActionId = "";
        confirmId = "";
        expandedAudioId = "";
        expandedNetworkId = "";
        networkPassword = "";
        selectionSync.stop();
        focusSync.stop();
        layoutSync.stop();
        ShellState.closeModal();
    }

    function enterDetail(item): void {
        parentQuery = query;
        parentActionId = item.data;
        expandedAudioId = "";
        expandedNetworkId = "";
        networkPassword = "";
        detailId = item.data;
        // The list behind a detail can be minutes old by the time it is
        // opened, so its own source is asked to refresh.
        if (item.data === "network") root.networkBackend.refresh();
        root.selectIndex(root.firstSelectable(0));
        root.focusMenu();
    }

    function leaveDetail(): void {
        if (!root.inDetail)
            return;
        const restoredQuery = parentQuery;
        const restoredActionId = parentActionId;
        restoredParentActionId = restoredActionId;
        expandedAudioId = "";
        expandedNetworkId = "";
        networkPassword = "";
        detailId = "";
        confirmId = "";
        parentActionId = "";
        query = restoredQuery;
        search.text = restoredQuery;
        root.retainSelection(restoredActionId, 0);
        root.focusMenu();
    }

    function confirmationText(id: string): string {
        if (id === "cache") return "Press Enter again to confirm cache cleanup";
        if (id === "colorpick") return "Press Enter again: screen-picker input takeover will start";
        if (id === "wifi-off") return "Press Enter again to confirm turning the Wi-Fi radio off";
        if (id === "vpn-off") return "Press Enter again to confirm disconnecting the VPN";
        if (id.startsWith("forget-")) return "Press Enter again to forget this paired device";
        return "Press Enter again to confirm";
    }

    function resultsListIndexForTest(index: int): void {
        root.selectIndex(index);
    }

    function setQueryForTest(value: string): void {
        search.text = value;
    }

    function retainSelection(data, fallbackIndex: int): void {
        const match = root.results.findIndex(row => row.data === data || row.data?.address === data);
        root.selectIndex(match >= 0 ? match : root.firstSelectable(fallbackIndex));
    }

    // The supporting line per kind. Live state is READ from the services here; the
    // structural result model stays a model, so a pending or failed operation is
    // a reading and never a new row.
    readonly property var kindSupport: ({
        "audio-level": item => {
            const level = root.levelControls[item.data];
            if (!level || !level.available()) return level?.unavailable ?? "Unavailable";
            return `${Math.round(level.value() * 100)}%${level.muted() ? " · Muted" : ""} · Enter to adjust`;
        },
        "main-keyboard": () => MainKeyboardService.description,
        "wifi-network": item => root.operationReading(root.networkBackend, item.data, item.sub),
        "network": item => {
            if (root.confirmId && root.confirmId === item.confirmId)
                return root.confirmationText(root.confirmId);
            if (item.data === "network-rescan")
                return root.networkBackend.scanning ? "Scanning…"
                    : root.networkBackend.scanError || item.sub;
            const target = ["wifi-on", "wifi-off"].includes(item.data) ? "wifi-radio" : item.data;
            return root.operationReading(root.networkBackend, target, item.sub);
        },
        "bluetooth": item => root.bluetoothSupport(item, item.identity),
        "bluetooth-device": item => root.bluetoothSupport(item, item.data.address),
        "bluetooth-forget": item => root.bluetoothSupport(item, item.data.address)
    })

    function bluetoothSupport(item, target: string): string {
        if (!root.bluetoothBackend.available) return "No Bluetooth adapter available";
        if (root.confirmId && root.confirmId === item.confirmId)
            return root.confirmationText(root.confirmId);
        const reading = root.operationReading(root.bluetoothBackend, target, "");
        if (reading) return reading;
        const adapter = root.bluetoothAdapterObject();
        if (item.data === "adapter")
            return adapter?.enabled ? "On · Enter to turn off" : "Off · Enter to turn on";
        if (!adapter?.enabled) return "Bluetooth radio is off";
        if (item.data === "discover")
            return adapter.discovering ? "Scanning · Enter to stop" : "Off · Enter to discover devices";
        return item.sub;
    }

    // Selectability per kind. Unavailable and busy are separate facts, and a
    // row that only reports is not a target at all.
    readonly property var kindSelectable: ({
        "main-keyboard": () => MainKeyboardService.available && !MainKeyboardService.busy,
        "audio": item => item.data === "mic-mute" ? AudioService.microphoneAvailable
            : AudioService.outputAvailable,
        "audio-level": item => {
            const level = root.levelControls[item.data];
            return !!level && level.available();
        },
        "action-detail": item => item.data !== "brightness" || BrightnessService.available,
        "wifi-network": () => root.networkBackend.wifiAvailable
            && root.networkBackend.wifiEnabled && !root.networkBackend.busy,
        "network": item => !root.networkBackend.busy
            && root.callHandler(root.networkSelectable, item.data, item, false),
        "bluetooth": item => root.bluetoothSelectable(item),
        "bluetooth-device": item => root.bluetoothSelectable(item),
        "bluetooth-forget": item => root.bluetoothSelectable(item)
    })

    readonly property var networkSelectable: ({
        "network-rescan": () => root.networkBackend.wifiAvailable
            && root.networkBackend.wifiEnabled && !root.networkBackend.scanning,
        "wifi-on": () => root.networkBackend.wifiAvailable,
        "wifi-off": () => root.networkBackend.wifiAvailable,
        "vpn": () => root.networkBackend.vpnAvailable && !!root.networkBackend.vpnName
    })

    readonly property var levelControls: ({
        "output-volume": {
            available: () => AudioService.outputAvailable, value: () => AudioService.outputValue,
            muted: () => AudioService.outputMuted, set: value => AudioService.setOutput(value),
            minimum: 0, name: "Output volume", unavailable: "No output available"
        },
        "microphone-volume": {
            available: () => AudioService.microphoneAvailable, value: () => AudioService.microphoneValue,
            muted: () => AudioService.microphoneMuted, set: value => AudioService.setMicrophone(value),
            minimum: 0, name: "Microphone level", unavailable: "No microphone available"
        },
        "brightness-level": {
            available: () => BrightnessService.available, value: () => BrightnessService.value,
            muted: () => false, set: value => BrightnessService.setValue(value),
            minimum: 0.01, name: "Screen brightness", unavailable: "No backlight available"
        }
    })

    readonly property var softwareToggles: ({
        "main-keyboard": () => MainKeyboardService.disabled,
        "awake": () => AwakeService.awake,
        "toggle": () => NightLightService.active
    })

    function bluetoothSelectable(item): bool {
        return root.bluetoothBackend.available && !root.bluetoothBackend.busy
            && (item.data === "adapter" || root.bluetoothAdapterObject()?.enabled === true);
    }

    function operationReading(service: var, target: string, resting: string): string {
        if (service.operationTarget !== target) return resting;
        if (service.busy) return "Updating…";
        if (service.operationState === "failed")
            return `${service.operationError} · Enter to retry`;
        return resting;
    }

    function rowSupporting(item): string {
        const read = root.kindSupport[item.kind];
        return read ? read(item) : item.sub ?? "";
    }

    function isSelectable(item): bool {
        if (!item || item.kind === "header" || item.kind === "hint")
            return false;
        const check = root.kindSelectable[item.kind];
        return check ? check(item) : true;
    }

    function resultIdentity(item): string {
        if (!item || item.kind === "header")
            return "";
        if (item.identity)
            return item.kind + ":" + item.identity;
        const data = item.data;
        const identity = data && typeof data === "object"
            ? data.id ?? data.address ?? data.name : data;
        return item.kind + ":" + (identity ?? item.label);
    }

    function selectIndex(index: int): void {
        const item = root.results[index];
        root.selectedIdentity = root.resultIdentity(item);
        if (root.expandedAudioId && item?.data !== root.expandedAudioId) {
            root.expandedAudioId = "";
            if (root.inputRegion === "editor") root.focusMenu();
        }
        if (root.expandedNetworkId && item?.data !== root.expandedNetworkId) {
            root.expandedNetworkId = "";
            root.networkPassword = "";
            if (root.inputRegion === "editor") root.focusMenu();
        }
        resultsList.currentIndex = root.selectedIndex;
        if (root.selectedIndex >= 0)
            resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function resultTarget(data: string): Item {
        const index = root.results.findIndex(row => row.data === data || row.data?.address === data);
        return index >= 0 ? resultsList.itemAtIndex(index) : null;
    }

    function resultTargetIdentity(identity: string): Item {
        const index = root.results.findIndex(row => row.identity === identity);
        return index >= 0 ? resultsList.itemAtIndex(index) : null;
    }

    // The password leaves the surface the moment it is handed over: the row
    // keeps a network name, never a secret.
    function submitNetwork(): void {
        if (!root.expandedNetworkId || root.networkBackend.busy) return;
        if (root.networkBackend.connect(root.expandedNetworkId, root.networkPassword))
            root.networkPassword = "";
    }

    Connections {
        target: root.networkBackend
        function onOperationStateChanged(): void {
            if (ShellState.modal !== "launcher" || !root.expandedNetworkId
                    || root.networkBackend.operationTarget !== root.expandedNetworkId) return;
            if (root.networkBackend.operationState === "completed") root.closeEditor();
            else if (root.networkBackend.operationState === "failed") {
                root.inputRegion = "editor";
                focusSync.restart();
            }
        }
    }

    onSelectedIdentityChanged: root.interacted("selected", { identity: root.selectedIdentity })
    onInputRegionChanged: root.interacted("focused", { region: root.inputRegion })

    Timer {
        id: selectionSync
        interval: 0
        onTriggered: {
            // JS-array replacement can reset the view's internal cursor. The
            // operation identity owns selection, not that transient index.
            if (root.selectedIndex < 0)
                root.selectIndex(root.firstSelectable(0));
            else
                resultsList.currentIndex = root.selectedIndex;
            if (root.expandedAudioId && !root.results.some(row => row.data === root.expandedAudioId))
                root.closeEditor();
            if (root.expandedNetworkId && (!root.networkBackend.wifiAvailable
                    || !root.networkBackend.wifiEnabled
                    || !root.results.some(row => row.data === root.expandedNetworkId)))
                root.closeEditor();
            root.revealSelection();
            if (root.inputRegion !== "search")
                focusSync.restart();
        }
    }

    Timer {
        id: focusSync
        interval: 0
        onTriggered: {
            if (ShellState.modal !== "launcher")
                return;
            const row = resultsList.currentItem;
            const editor = row ? row.valueEditor : null;
            if (root.inputRegion === "search") {
                search.forceActiveFocus();
            } else if (root.inputRegion === "editor"
                    && (root.expandedAudioId || root.expandedNetworkId)
                    && editor && editor.enabled) {
                editor.forceActiveFocus();
            } else {
                resultsList.forceActiveFocus();
            }
        }
    }

    function revealSelection(): void {
        if (root.selectedIndex >= 0)
            resultsList.positionViewAtIndex(root.selectedIndex,
                root.mode === "action" && !root.expandedAudioId ? ListView.Center : ListView.Contain);
    }

    function focusMenu(): void {
        root.inputRegion = "menu";
        if (ShellState.modal === "launcher") resultsList.forceActiveFocus();
    }

    function focusSearch(): void {
        root.inputRegion = "search";
        focusSync.stop();
        root.expandedAudioId = "";
        root.expandedNetworkId = "";
        root.networkPassword = "";
        if (ShellState.modal === "launcher" && !search.focused) search.forceActiveFocus();
    }

    function closeEditor(): void {
        root.expandedAudioId = "";
        root.expandedNetworkId = "";
        root.networkPassword = "";
        root.focusMenu();
    }

    function openEditor(index: int): void {
        if (!root.isSelectable(root.results[index]))
            return;
        root.selectIndex(index);
        root.expandedAudioId = root.results[index].data;
        root.inputRegion = "editor";
        root.revealSelection();
        focusSync.restart();
    }

    // BottomToTop: visual up is index+1, independently of the physical key.
    function stepSelection(delta: int): void {
        if (root.mode === "theme")
            return;
        let index = root.selectedIndex < 0 ? (delta > 0 ? 0 : root.results.length - 1)
            : root.selectedIndex + delta;
        while (index >= 0 && index < results.length && !root.isSelectable(results[index]))
            index += delta;
        if (index >= 0 && index < results.length) {
            root.selectIndex(index);
            root.revealSelection();
        }
        if (root.mode === "action") {
            root.expandedAudioId = "";
            root.expandedNetworkId = "";
            root.networkPassword = "";
            root.focusMenu();
        }
    }

    // First selectable row at or after `offset` (used to open / re-filter past
    // a header without parking the cursor on one).
    function firstSelectable(offset = 0): int {
        let index = Math.max(0, offset);
        while (index < results.length && !root.isSelectable(results[index]))
            index++;
        return index < results.length ? index : -1;
    }

    function menuKey(event, editor: bool): void {
        if (event.modifiers !== Qt.NoModifier)
            return;
        const key = event.key;
        if (key === Qt.Key_Up || key === Qt.Key_I)
            root.stepSelection(1);
        else if (key === Qt.Key_Down || key === Qt.Key_E)
            root.stepSelection(-1);
        else if (key === Qt.Key_Slash)
            root.focusSearch();
        else if (key === Qt.Key_Escape) {
            if (!event.isAutoRepeat) {
                if (root.expandedAudioId || root.expandedNetworkId) root.closeEditor();
                else if (root.inDetail) root.leaveDetail();
                else root.close();
            }
        } else if (key === Qt.Key_Enter || key === Qt.Key_Return) {
            if (!event.isAutoRepeat) {
                if (editor) root.closeEditor();
                else root.activate(root.selectedIndex);
            }
        } else if (!editor && (key === Qt.Key_Left || key === Qt.Key_N)) {
            if (root.expandedAudioId || root.expandedNetworkId) root.closeEditor();
            else if (root.inDetail) root.leaveDetail();
        } else if (!editor && (key === Qt.Key_Right || key === Qt.Key_O)) {
            const item = root.results[root.selectedIndex];
            // Right opens a route or editor, never toggles a repeatable action.
            if (!event.isAutoRepeat && item?.kind === "audio-level")
                root.openEditor(root.selectedIndex);
            else if (!event.isAutoRepeat && item && (item.kind === "command" || item.kind === "category"
                    || (item.kind === "action" && !["awake",
                        "notifications", "session"].includes(item.data))))
                root.activate(root.selectedIndex);
        } else {
            return;
        }
        ShellState.claimKeyboardSelection();
        event.accepted = true;
    }

    // One table per decision this surface makes, keyed by the row's kind: the
    // action it runs, the line it reports, whether it can be selected, the rows
    // its detail owns. A new kind adds one entry to a table; it never adds
    // another branch through this file. Handlers are called through
    // callHandler, never as `table[key]?.(item)`: this engine accepts that
    // syntax and then never calls the function.
    // A handler returns TRUE when the row it activated is still the row worth
    // staying on (a repeatable toggle), and FALSE when the surface moved on and
    // the selection must follow whatever is now there.
    readonly property var kindActions: ({
        "main-keyboard": () => { MainKeyboardService.toggle(); return true; },
        "header": () => false,
        "app": item => {
            root.bumpFrecency(item.data.id);
            item.data.execute();
            root.close();
            return false;
        },
        "command": item => {
            search.text = `>${item.data} `;
            if (item.data === "action") root.focusMenu();
            return false;
        },
        "category": () => {
            root.enterDetail(root.results[root.selectedIndex]);
            return false;
        },
        "action": item => {
            const surface = root.surfaces[item.data];
            if (surface === undefined) root.enterDetail(item);
            else surface();
            return false;
        },
        "action-detail": item => root.callHandler(root.detailActions, item.data, item, false),
        "network": item => root.callHandler(root.networkOperations, item.data, item, false),
        "wifi-network": item => {
            const network = (root.networkBackend.networks ?? []).find(entry => entry.ssid === item.data);
            if (!network) return false;
            if (network.active) root.networkBackend.disconnect(network.ssid);
            // An enterprise network needs a certificate and an identity, so a
            // password prompt would promise a connection it cannot complete.
            else if (network.enterprise) Delegate.open("network");
            else if (network.secure) {
                root.expandedNetworkId = network.ssid;
                root.networkPassword = "";
                root.inputRegion = "editor";
                focusSync.restart();
            } else root.networkBackend.connect(network.ssid, "");
            return true;
        },
        "bluetooth": item => {
            root.bluetoothBackend.operate(item.data === "adapter" ? "adapter-power" : "discovery");
            return false;
        },
        "bluetooth-device": item => {
            root.bluetoothBackend.operate(item.data.address);
            return false;
        },
        "bluetooth-forget": item => {
            root.armed(item, () => {
                root.bluetoothBackend.forget(item.data.address);
                root.confirmId = "";
            });
            return false;
        },
        "audio": (item, index) => {
            const toggle = item.data === "mic-mute" ? AudioService.toggleMicrophoneMuted : AudioService.toggleOutputMuted;
            toggle();
            root.focusMenu();
            return true;
        },
        "audio-level": (item, index) => {
            if (root.expandedAudioId === item.data) root.closeEditor();
            else root.openEditor(index);
            return true;
        },
        "device": item => {
            if (item.input) AudioService.setDefaultSource(item.data);
            else AudioService.setDefaultSink(item.data);
            return false;
        },
        "level": item => {
            const step = item.data === "up" ? 0.05 : -0.05;
            if (root.detailId === "brightness") BrightnessService.setValue(BrightnessService.value + step);
            else NightLightService.setStrength(NightLightService.strength + step);
            return true;
        },
        "profile": item => {
            PowerProfileService.setProfile(item.data);
            return false;
        },
        "delegate": item => {
            Delegate.open(item.data);
            return false;
        },
        "panel-tab": item => {
            ShellState.togglePanel(item.data);
            return false;
        },
        "calc": () => {
            if (root.calcResult.length === 0) return false;
            root.run(["wl-copy", root.calcResult], true);
            return false;
        },
        "kill-window": item => {
            root.run(["hyprctl", "dispatch", "killwindow", `address:${item.data}`], true);
            return false;
        },
        "kill-process": item => {
            root.run(["kill", String(item.data)], true);
            return false;
        },
        "theme": item => {
            Theme.apply(item.data);
            root.close();
            return false;
        }
    })

    // The surface each action row owns. Anything absent opens its detail.
    readonly property var surfaces: ({
        "notifications": () => ShellState.toggleModal("notifications"),
        "session": () => ShellState.toggleModal("session"),
        "awake": () => AwakeService.toggle()
    })

    // A detail action returns TRUE when the row stays selected: the toggle ran and
    // the person is likely to run it again.
    readonly property var detailActions: ({
        "brightness": () => { BrightnessService.toggle(); return true; },
        "awake": () => { AwakeService.toggle(); return true; },
        "nightlight": () => { NightLightService.toggle(); return true; },
        "toggle": () => {
            // Only the night light has a row called "toggle"; another detail
            // that adds one must name it after what it toggles.
            if (root.detailId !== "nightlight") return false;
            NightLightService.toggle();
            return true;
        },
        "network": () => { Delegate.open("network"); return false; },
        "bluetooth": () => { Delegate.open("bluetooth"); return false; },
        "session": () => { ShellState.toggleModal("session"); return false; },
        "cache": item => {
            root.armed(item, () => {
                CacheService.clean();
                root.confirmId = "";
            });
            return true;
        },
        "colorpick": item => {
            root.armed(item, () => {
                ColorPickService.pick();
                root.confirmId = "";
            });
            return true;
        }
    })

    readonly property var networkOperations: ({
        "network-rescan": () => root.networkBackend.rescan(),
        "wifi-on": () => root.networkBackend.setWifiEnabled(true),
        "wifi-off": item => root.armed(item, () => {
            root.networkBackend.setWifiEnabled(false);
            root.confirmId = "";
        }),
        "vpn": item => {
            if (!root.networkBackend.vpnActive) { root.networkBackend.toggleVpn(); return; }
            root.armed(item, () => {
                root.networkBackend.toggleVpn();
                root.confirmId = "";
            });
        }
    })

    // One way into a dispatch table. A missing entry is not an error: the
    // caller supplies what "nothing to do" means for that call.
    function callHandler(table: var, key: string, item: var, fallback: var): var {
        const handler = table ? table[key] : null;
        return typeof handler === "function" ? handler(item) : fallback;
    }

    // Arm, then fire on the second activation. Every destructive or
    // connectivity-changing route in the surface goes through this one.
    function armed(item, fire): void {
        if (root.confirmId !== item.confirmId) {
            root.confirmId = item.confirmId;
            return;
        }
        fire();
    }

    function run(command: var, thenClose: bool): void {
        runner.command = command;
        runner.running = true;
        if (thenClose) root.close();
    }

    function activate(index: int): void {
        const item = results[index];
        if (!root.isSelectable(item))
            return;
        const action = root.kindActions[item.kind];
        if (!action)
            return;
        root.interacted("activated", { identity: root.resultIdentity(item) });
        root.selectIndex(index);
        if (root.mode === "action") root.focusMenu();
        // The selection is kept whenever the row is still there afterwards.
        if (action(item, index) !== false)
            root.retainSelection(item.data, index);
    }


    // --- processes ------------------------------------------------------------

    Timer {
        id: calcTimer
        interval: 120
        onTriggered: {
            if (root.rest.trim().length > 0) {
                calcProbe.command = ["bash", "-c", 'qalc -t "$1"', "_", root.rest];
                calcProbe.running = true;
            } else {
                root.calcResult = "";
            }
        }
    }

    Process {
        id: calcProbe
        stdout: StdioCollector {
            onStreamFinished: root.calcResult = text.trim()
        }
        // A missing qalc is a DEGRADED SURFACE, not a result: the exit code
        // says it, the row says what to do about it, and Enter has nothing to
        // copy.
        onExited: exitCode => {
            root.calcAvailable = exitCode !== 127;
            if (!root.calcAvailable)
                root.calcResult = "";
        }
    }

    Process {
        id: killProbe
        command: ["bash", "-c",
            `hyprctl clients -j | jq -r '.[] | "W|\\(.address)|\\(.class)|\\(.title)"'
ps -eo pid,pcpu,comm --no-headers --sort=-pcpu | head -25 | awk '{printf "P|%s|%s|%s%% cpu\\n", $1, $3, $2}'`]
        stdout: StdioCollector {
            onStreamFinished: {
                const targets = [];
                for (const line of text.split("\n")) {
                    const [type, id, name, extra] = line.split("|");
                    if (type === "W")
                        targets.push({ kind: "kill-window", label: name, sub: extra, data: id });
                    else if (type === "P")
                        targets.push({ kind: "kill-process", label: name, sub: `pid ${id} · ${extra}`, data: id });
                }
                root.killTargets = targets;
            }
        }
    }

    Process {
        id: runner
    }

    // Frecency persistence (07 DEFAULT ranking).
    Loader {
        id: rankingFile
        active: root.persistRanking
        sourceComponent: FileView {
            property alias counts: frecency.counts
            path: Quickshell.statePath("launcher.json")
            atomicWrites: true
            printErrors: false
            onAdapterUpdated: writeAdapter()
            onLoadFailed: {
                frecency.counts = {};
                Qt.callLater(writeAdapter);
            }

            JsonAdapter {
                id: frecency
                property var counts: ({})
            }
        }
    }

    // Swallow clicks on non-interactive launcher body so they never reach the
    // panel's full-window dismiss area — clicking padding must not close.
    MouseArea {
        anchors.fill: parent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: QsmShellStyle.Style.rolloutPadding
        spacing: QsmShellStyle.Style.space3

        // Results ABOVE the search field (07): bottom-up so the
        // first result sits adjacent to the input. Hidden (not destroyed) in
        // >theme mode, where the horizontal carousel below takes over —
        // Layouts exclude invisible children so no space is reserved twice.
        // Host, because the cue must be a SIBLING of the view: a Flickable's
        // declared children go into its contentItem, where they scroll with
        // the content and feed childrenRect. The Layout sizing AND the
        // visibility move up here — the note above is why: Layouts exclude
        // invisible children, and it is the host that has to disappear in
        // >theme mode for the carousel to get the cell.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode !== "theme"

            ListView {
                id: resultsList

                anchors.fill: parent
                clip: true
                // >kill rows separate wider (07). The
                // standard 4px gap put a mis-hover 4px from an irreversible kill;
                // space3 gives the pointer room without a confirm, which 07
                // deliberately rejects. The body height is fixed, so the taller
                // rhythm scrolls rather than resizing it.
                spacing: root.mode === "kill" ? QsmShellStyle.Style.space3 : QsmShellStyle.Style.space1
                currentIndex: 0
                verticalLayoutDirection: ListView.BottomToTop
                boundsBehavior: Flickable.StopAtBounds
                model: root.results
                onActiveFocusChanged: {
                    if (activeFocus) root.inputRegion = "menu";
                }
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => root.menuKey(event, false)

                delegate: ResultRow {
                    id: resultRow
                    required property var modelData
                    required property int index
                    width: root.menuTarget.width
                    size: Theme.launcherRowSize
                    item: modelData
                    selected: resultRow.index === root.selectedIndex
                    focused: selected && (resultsList.activeFocus || resultRow.activeFocus)
                    readonly property bool audioRow: modelData.kind === "audio"
                    readonly property bool wifiNetwork: modelData.kind === "wifi-network"
                    readonly property bool microphone: modelData.data === "mic-mute"
                    readonly property bool audioAvailable: microphone
                        ? AudioService.microphoneAvailable : AudioService.outputAvailable
                    readonly property Item valueEditor: editorLoader.item?.focusTarget ?? editorLoader.item
                    // The editor is created a tick after the reveal, so the
                    // focus grant waits for the editor to EXIST, not for the
                    // row to open.
                    onValueEditorChanged: {
                        if (valueEditor && resultRow.selected && root.inputRegion === "editor")
                            focusSync.restart();
                    }
                    readonly property Item toggleTarget: toggleControl
                    // Unavailable and not-a-target are different states: a row
                    // that cannot be taken now dims, a hint that only reports
                    // is simply not clickable.
                    disabled: root.isSelectable(modelData) ? false
                        : modelData.kind !== "hint" && modelData.kind !== "header"
                    interactive: modelData.kind !== "hint"
                    supporting: !audioRow ? root.rowSupporting(modelData)
                        : !audioAvailable ? (microphone ? "No microphone available" : "No output available")
                        : (microphone ? AudioService.microphoneMuted : AudioService.outputMuted)
                                ? "On · Enter to unmute" : "Off · Enter to mute"
                    expanded: modelData.kind === "audio-level"
                        ? root.expandedAudioId === modelData.data
                        : wifiNetwork && root.expandedNetworkId === modelData.data
                    onExpansionHeightChanged: layoutSync.restart()
                    // The editor exists as soon as the row renders, so the
                    // focus grant waits for the REVEAL, not for the load.
                    onExpandedChanged: {
                        if (expanded && root.inputRegion === "editor")
                            focusSync.restart();
                    }
                    // qmllint disable unqualified
                    onActivated: root.activate(resultRow.index)
                    // qmllint enable unqualified
                    // Pointer and keyboard share ONE cursor: hovering a row makes
                    // it the selected row, so Enter always means the row you can
                    // see marked and there is no second highlight to reconcile.
                    onHoveredEntered: root.selectIndex(resultRow.index)

                    QsmShellComponents.Switch {
                        id: toggleControl
                        readonly property bool radioSwitch: resultRow.modelData.kind === "network"
                            && ["wifi-on", "wifi-off"].includes(resultRow.modelData.data)
                        readonly property bool bluetoothSwitch: resultRow.modelData.kind === "bluetooth"
                        readonly property bool softwareToggle: ["action", "action-detail", "main-keyboard"]
                            .includes(resultRow.modelData.kind)
                            && typeof root.softwareToggles[resultRow.modelData.data] === "function"
                        visible: resultRow.modelData.kind === "audio" || radioSwitch
                            || bluetoothSwitch || softwareToggle
                        enabled: visible && root.isSelectable(resultRow.modelData)
                        size: "sm"
                        checked: resultRow.modelData.kind === "audio"
                            ? (resultRow.microphone ? AudioService.microphoneMuted : AudioService.outputMuted)
                            : radioSwitch ? root.networkBackend.wifiEnabled
                            : bluetoothSwitch
                                ? (resultRow.modelData.data === "discover"
                                    ? root.bluetoothAdapterObject()?.discovering === true
                                    : root.bluetoothAdapterObject()?.enabled === true)
                            : root.callHandler(root.softwareToggles, resultRow.modelData.data, resultRow.modelData, false)
                        Accessible.name: softwareToggle && resultRow.modelData.data === "main-keyboard"
                            ? "Disable main keyboard" : resultRow.modelData.label
                        onToggleRequested: root.activate(resultRow.index)
                        onActiveFocusChanged: {
                            if (activeFocus) {
                                root.inputRegion = "menu";
                                root.selectIndex(resultRow.index);
                            }
                        }
                        Keys.priority: Keys.BeforeItem
                        Keys.onPressed: event => root.menuKey(event, false)
                    }

        // Editors are components, not inline blocks: the Loader picks one by kind,
        // and each one is a real control a person can focus, type into and read.
        Component {
            id: volumeEditor
            QsmShellComponents.Slider {
                readonly property var level: root.levelControls[resultRow.modelData.data]
                enabled: resultRow.expanded && level.available()
                size: "md"
                from: level.minimum
                to: 1
                value: level.value()
                wheelUnits: QsmShellStyle.Style.sliderKeyboardUnits
                accessibleName: level.name
                onMoved: {
                    root.interacted("moved", { identity: root.resultIdentity(resultRow.modelData), value: value });
                    level.set(value);
                }
                onCommitted: root.interacted("committed", { identity: root.resultIdentity(resultRow.modelData), value: value })
                onActiveFocusChanged: {
                    if (activeFocus) root.inputRegion = "editor";
                }
                onKeyPressed: event => {
                    if ((event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)
                            && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                        root.stepSelection(event.key === Qt.Key_Backtab
                            || (event.modifiers & Qt.ShiftModifier) ? 1 : -1);
                        ShellState.claimKeyboardSelection();
                        event.accepted = true;
                    } else {
                        root.menuKey(event, true);
                    }
                }
            }
        }

        // The prompt belongs to the row that asked the question, and the secret
        // lives only here: nothing about it reaches identity, events or storage.
        Component {
            id: passwordEditor
            QsmShellComponents.Field {
                id: networkPasswordField
                readonly property Item focusTarget: wifiPasswordInput
                label: "Network password"
                required: true
                hint: root.networkBackend.busy ? "Connecting…" : "Enter to connect · Escape to cancel"
                error: root.networkBackend.operationTarget === root.expandedNetworkId
                    && root.networkBackend.operationState === "failed"
                    ? root.networkBackend.operationError : ""
                sizeScale: wifiPasswordInput.sizeScale
                QsmShellComponents.TextField {
                    id: wifiPasswordInput
                    width: parent.width
                    size: "sm"
                    inputType: "password"
                    text: root.networkPassword
                    readOnly: root.networkBackend.busy
                    failed: networkPasswordField.failed
                    Accessible.name: `Password for ${root.expandedNetworkId}`
                    onEdited: text => root.networkPassword = text
                    onFocusedChanged: {
                        if (focused) root.inputRegion = "editor";
                    }
                    onAccepted: root.submitNetwork()
                    onEscaped: root.closeEditor()
                    onKeyPressed: event => {
                        if (event.modifiers !== Qt.NoModifier) return;
                        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                            root.stepSelection(event.key === Qt.Key_Up ? 1 : -1);
                            ShellState.claimKeyboardSelection();
                            event.accepted = true;
                        }
                    }
                    leading: QsmShellComponents.ControlLabel {
                        icon: wifiPasswordInput.passwordVisible ? "eye-off" : "eye"
                        clickable: true
                        accessibleName: wifiPasswordInput.passwordVisible ? "Hide password" : "Reveal password"
                        onClicked: wifiPasswordInput.toggleReveal()
                    }
                    trailing: QsmShellComponents.ControlLabel {
                        icon: "check"
                        clickable: true
                        enabled: !root.networkBackend.busy
                        accessibleName: "Connect to network"
                        onClicked: wifiPasswordInput.accept()
                    }
                }
            }
        }

                    expandedContent: Loader {
                        id: editorLoader
                        Layout.fillWidth: true
                        active: resultRow.modelData.kind === "audio-level" || resultRow.wifiNetwork
                        sourceComponent: resultRow.wifiNetwork ? passwordEditor : volumeEditor
                    }
                }
            }

            // On the HOST, not in the list. As a declared child of the
            // Flickable its `centerIn: parent` meant the scrolling contentItem
            // rather than the viewport; it never showed because the only time
            // it is visible is when there is nothing to scroll.
            QsmShellComponents.EmptyState {
                anchors.centerIn: parent
                visible: root.results.length === 0
                icon: "search"
                title: root.mode === "apps" ? "No matching applications" : "No matches"
                detail: root.mode === "apps" ? "Try another name, or type > for commands" : "Try a different search"
            }

            // The results list is capped at a visible row count (07), so it
            // overflows in ordinary use and said nothing about it.
            QsmShellComponents.ScrollCue {
                view: resultsList
                fadeColor: Theme.band
            }
        }

        ThemeCarousel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.mode === "theme"
            items: root.results
            currentIndex: root.themeIndex
            onActivated: index => root.activate(index)
            // One cursor: hovering a card selects it, exactly as the
            // result rows do — the centered card is always what Enter fires.
            onHoverSelect: index => root.themeIndex = Math.max(0,
                Math.min(root.results.length - 1, index))
        }

        SearchField {
            id: search

            Layout.fillWidth: true
            size: "lg"
            placeholder: "Search apps — '>' for commands"

            // The caret owns focus; the frame reports activeFocus only while
            // forwarding a programmatic grant to its inner input.
            onFocusedChanged: if (focused) root.focusSearch()

            // Letters and slash stay text here. Only unmodified vertical
            // arrows enter menu navigation; modified caret commands stay native.
            onKeyPressed: event => {
                if (event.modifiers !== Qt.NoModifier)
                    return;
                if (root.mode === "theme" && event.key === Qt.Key_Left) {
                    root.themeIndex = Math.max(0, root.themeIndex - 1);
                    event.accepted = true;
                } else if (root.mode === "theme" && event.key === Qt.Key_Right) {
                    root.themeIndex = Math.min(root.results.length - 1, root.themeIndex + 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    // BottomToTop: visually-up is index+1.
                    root.stepSelection(1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    root.stepSelection(-1);
                    event.accepted = true;
                } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
                        && event.isAutoRepeat) {
                    event.accepted = true;
                }
                if (event.accepted)
                    ShellState.claimKeyboardSelection();
            }

            onAccepted: root.activate(root.selectedIndex)
            onEscaped: root.inDetail ? root.leaveDetail() : root.close()
            onTextChanged: {
                root.query = text;
                root.expandedAudioId = "";
                root.selectIndex(root.firstSelectable(0));
            }
        }
    }

    Timer {
        id: layoutSync
        interval: 0
        onTriggered: {
            resultsList.forceLayout();
            root.revealSelection();
        }
    }

    Component.onCompleted: root.selectIndex(root.firstSelectable(0))
}
