import QtQuick

import qs.QsmShell.Style as QsmShellStyle

// What the library's Style and Motion expose, and which of the size presets
// named after `--` (a JSON list of [type, preset]) it already answers, as one
// JSON line, for scripts/check-theme-contract: the contract is what the library
// answers when asked, not what its source happens to spell.
Item {
    function namesOf(object: var): var {
        const found = [];
        for (const name in object)
            found.push(name);
        return found;
    }

    Component.onCompleted: {
        const pairs = JSON.parse(Qt.application.arguments[Qt.application.arguments.indexOf("--") + 1] ?? "[]");
        console.log("PUBLIC " + JSON.stringify({
            Style: namesOf(QsmShellStyle.Style),
            Motion: namesOf(QsmShellStyle.Motion),
            sizesAnswered: pairs.filter(pair => QsmShellStyle.Style.hasSize(pair[0], pair[1]))
        }));
        Qt.exit(0);
    }
}
