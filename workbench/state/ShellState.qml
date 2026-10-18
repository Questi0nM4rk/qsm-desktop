pragma Singleton

import QtQuick

QtObject {
    property string modal: "none"
    property string keyboardGrab: ""
    property bool keyboardOwnsSelection: false
    property bool reducedMotion: false
    property bool reducedEffects: false
    property string theme: "deep-night"
    property string launcherSeed: ""
    property var focusedScreen: null
    property string panelTab: "dashboard"
    readonly property var panelTabs: ["dashboard", "media", "performance", "workspaces"]
    property var collapsedRails: ({})

    onModalChanged: keyboardOwnsSelection = false

    function claimKeyboardSelection(): void {
        keyboardOwnsSelection = true;
    }

    function toggleModal(name: string): bool {
        modal = modal === name ? "none" : name;
        return true;
    }

    function closeModal(): void {
        modal = "none";
    }

    function isRailCollapsed(screenName: string): bool {
        return collapsedRails[screenName] === true;
    }

    function toggleRail(screenName: string): bool {
        return setRailCollapsed(screenName, !isRailCollapsed(screenName));
    }

    function setRailCollapsed(screenName: string, collapsed: bool): bool {
        const next = Object.assign({}, collapsedRails);
        next[screenName] = collapsed;
        collapsedRails = next;
        return collapsed;
    }

    function reset(): void {
        modal = "none";
        keyboardGrab = "";
        keyboardOwnsSelection = false;
        reducedMotion = false;
        reducedEffects = false;
        theme = "deep-night";
        launcherSeed = "";
        focusedScreen = null;
        panelTab = "dashboard";
        collapsedRails = ({});
    }
}
