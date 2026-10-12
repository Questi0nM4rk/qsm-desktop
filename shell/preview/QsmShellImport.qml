import QtQuick
import QtQuick.Window

import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle

Window {
    id: root
    visible: false
    QtObject {
        id: fakeBackend
        property bool reducedMotion: false
        property color accent: "#aa5500"
        property color secondary: "#bb6600"
        property color success: "#00aa55"
        property color outline: "#553300"
        property color background: "#110a05"
        property color surface: "#22140a"
        property color surfaceHover: "#33200f"
        property color surfaceRaised: "#442a14"
        property color text: "#fff4e8"
        property color textMuted: "#d8b899"
        property color danger: "#dd3344"
        property string fontFamily: "Sans"
        property string technicalFontFamily: "Monospace"
        property real surfaceOpacity: 0.73
        property real opacityDisabled: 0.35
        property int sliderThumbSize: 12
        property int sliderTrackThickness: 4
        property int controlHeight: 40
        property int controlHeightSm: 26
    }

    Binding {
        target: QsmShellStyle.Style
        property: "backend"
        value: fakeBackend
    }

    QsmShellComponents.Card {
        id: card
    }

    Timer {
        id: verifyUpdate
        interval: 0
        onTriggered: {
            if (!root.require(card.surfaceColor === fakeBackend.surface, "Card did not update after backend mutation"))
                return;
            if (!root.require(card.surfaceOpacity === fakeBackend.surfaceOpacity, "Card opacity did not resolve from backend"))
                return;
            console.log("QSM_SHELL_IMPORT_OK");
            Qt.exit(0);
        }
    }

    function require(condition, message) {
        if (condition)
            return true;

        console.error(`QSM_SHELL_IMPORT_FAIL: ${message}`);
        Qt.exit(1);
        return false;
    }

    Component.onCompleted: {
        if (!require(card, "Card did not instantiate"))
            return;
        if (!require(card.surfaceColor === fakeBackend.surface, "Card did not resolve backend surface"))
            return;
        fakeBackend.surface = "#553311";
        verifyUpdate.start();
    }
}
