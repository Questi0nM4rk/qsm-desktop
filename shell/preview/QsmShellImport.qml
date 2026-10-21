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
        property color primary: "#aa5500"
        property color textOnPrimary: "#110a05"
        property color focus: "#aa5500"
        property color success: "#00aa55"
        property color warning: "#ddaa00"
        property color info: "#3388dd"
        property color band: "#110a05"
        property color surface: "#22140a"
        property color overlay: "#442a14"
        property color text: "#fff4e8"
        property color textMuted: "#d8b899"
        property color danger: "#dd3344"
        property string fontFamily: "Sans"
        property string technicalFontFamily: "Monospace"
        property real opacityDisabled: 0.35
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
