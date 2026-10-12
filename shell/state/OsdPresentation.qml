import QtQuick

QtObject {
    id: root

    property bool visible: false
    property bool hovered: false
    property string kind: ""
    property var targetScreen: null

    function show(control: string, screen: var): bool {
        if (!["output", "microphone", "brightness"].includes(control))
            return false;

        if (targetScreen !== screen)
            hovered = false;

        kind = control;
        targetScreen = screen;
        visible = true;
        if (hovered)
            expiry.stop();
        else
            expiry.restart();
        return true;
    }

    function setRetention(screen: var, held: bool): void {
        if (screen !== targetScreen || hovered === held)
            return;

        hovered = held;
        if (held)
            expiry.stop();
        else if (visible)
            expiry.restart();
    }

    function setHovered(held: bool): void {
        setRetention(targetScreen, held);
    }

    function reset(): void {
        expiry.stop();
        visible = false;
        hovered = false;
        kind = "";
        targetScreen = null;
    }

    property Timer expiry: Timer {
        interval: 1500
        onTriggered: {
            if (!root.hovered)
                root.visible = false;
        }
    }
}
