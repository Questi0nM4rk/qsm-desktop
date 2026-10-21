import QtQuick
import QtQuick.Window

import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle

Window {
    id: root
    visible: false
    // Only what the check reads: a backend answers the names it declares and
    // the library answers the rest.
    QtObject {
        id: fakeBackend
        property color surface: "#22140a"
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
