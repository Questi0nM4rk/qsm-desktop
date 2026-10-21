import QtQuick

import qs.QsmShell.Style as QsmShellStyle

// The names the library's Style and Motion expose, as one JSON line, for
// scripts/check-theme-contract: the contract is what the library answers when
// asked, not what its source happens to spell.
Item {
    function namesOf(object: var): var {
        const found = [];
        for (const name in object)
            found.push(name);
        return found;
    }

    Component.onCompleted: {
        console.log("PUBLIC " + JSON.stringify({
            Style: namesOf(QsmShellStyle.Style),
            Motion: namesOf(QsmShellStyle.Motion)
        }));
        Qt.exit(0);
    }
}
