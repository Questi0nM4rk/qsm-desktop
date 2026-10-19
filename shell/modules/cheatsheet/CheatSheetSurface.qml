import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.QsmShell.Components as QsmShellComponents
import qs.components
import qs.state
import qs.theme
import "../../QsmShell/Components/fuzzy.js" as Fuzzy

// Keybind cheat sheet (decision-table row 9, built 2026-08-20, owner round
// 2026-08-21). The clipboard rollout is reachable ONLY by its keybind, which
// made this surface load-bearing: a surface with no visible affordance has to
// be discoverable somewhere, and this is the somewhere.
//
// The data is `hyprctl binds -j`, read live on every open so overrides and
// config edits show up without touching the shell. Every bind in the lua
// config compiles to an opaque __lua handler, so the bind's `description` opt
// is the ONLY text the compositor can report — a bind without one is filtered
// out here rather than shown as an empty row (the fix is to describe it in
// hyprland.lua, not to render the gap). Grouping rides the same channel:
// descriptions follow the "Group · Description" convention; no separator
// files the bind under "Other".
//
// Rows are a REFERENCE, not actions: no selection, no Enter, no hover cursor
// (owner 2026-08-21 — a keybind row answers by being read, not by being
// chosen). Search FILTERS, arrows scroll, and the list keeps hyprctl's own
// order inside each group, which is the lua file's curated order. The bottom
// fade and a thin position thumb are the only scroll furniture.
Item {
    id: root

    property string query
    property var binds: []
    property bool probeFailed: false

    // X11 modifier bits, the only four this config uses.
    function comboOf(bind: var): string {
        const parts = [];
        if (bind.modmask & 64)
            parts.push("SUPER");
        if (bind.modmask & 4)
            parts.push("CTRL");
        if (bind.modmask & 8)
            parts.push("ALT");
        if (bind.modmask & 1)
            parts.push("SHIFT");
        parts.push(root.keyLabel(bind.key));
        return parts.join(" + ");
    }

    function keyLabel(key: string): string {
        if (key === "mouse:272")
            return "LMB";
        if (key === "mouse:273")
            return "RMB";
        if (key.toLowerCase() === "slash")
            return "/";
        return key.length === 1 ? key.toUpperCase() : key.replace(/^XF86/, "");
    }

    // FILTERED, never re-sorted: a score sort would fragment the group runs
    // into repeated headers. The config's order IS the presentation order.
    // NO selection and NO dim (owner 2026-08-21): a reference has nothing to
    // select — a keybind row answers by being read, not by being chosen —
    // so the filter alone is the search's whole answer.
    readonly property var results: binds
        .map(bind => ({
            combo: bind.combo,
            description: bind.description,
            group: bind.group,
            score: Fuzzy.score(root.query, bind.group + " " + bind.combo + " " + bind.description)
        }))
        .filter(item => item.score >= 0)

    function open(): void {
        query = "";
        search.clear();
        rows.contentY = 0;
        probeFailed = false;
        bindProbe.running = true;
        Qt.callLater(() => search.forceActiveFocus());
    }

    function close(): void {
        ShellState.closeModal();
    }

    function scrollBy(delta: real): void {
        rows.contentY = Math.max(0, Math.min(
            rows.contentY + delta,
            Math.max(0, rows.contentHeight - rows.height)));
    }

    Process {
        id: bindProbe
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            // A failed or missing hyprctl yields no parseable JSON, so the
            // failure state derives from the output alone — no typed onExited
            // handler (its QProcess::ExitStatus parameter trips qmllint).
            onStreamFinished: {
                let parsed = null;
                try {
                    parsed = JSON.parse(text);
                } catch (error) {
                }
                root.probeFailed = !Array.isArray(parsed);
                root.binds = (Array.isArray(parsed) ? parsed : [])
                    .filter(bind => bind.description.length > 0)
                    .map(bind => {
                        const split = bind.description.indexOf(" · ");
                        return {
                            combo: root.comboOf(bind),
                            group: split > 0 ? bind.description.slice(0, split) : "Other",
                            description: split > 0
                                ? bind.description.slice(split + 3) : bind.description
                        };
                    })
                    // Keys that live INSIDE the shell's own surfaces — the
                    // compositor never sees them, so hyprctl cannot list
                    // them, and the audit found them undiscoverable (the
                    // clipboard is keyboard-only AND its keys were secret).
                    .concat([
                        { combo: "ENTER", group: "In surfaces", description: "Launcher/clipboard: run or paste the selection" },
                        { combo: "DEL", group: "In surfaces", description: "Clipboard: remove the selected entry" },
                        { combo: "UP / DOWN", group: "In surfaces", description: "Move the selection, or scroll this sheet" },
                        { combo: "ESC", group: "In surfaces", description: "Close the open surface" },
                        { combo: "MMB", group: "In surfaces", description: "Notification popup: close it" }
                    ]);
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.space4
        // Almost to the silhouette's bottom edge: the roll-away fade owns
        // that boundary and lands on the band, so the fade reads as running
        // into the ground.
        anchors.bottomMargin: Theme.space2
        spacing: Theme.space3

        // Field at the TOP: the surface descends from the top band, and the
        // shell-wide rule puts the input nearest the attached edge. Compact,
        // like the clipboard's — this is a reference card, not the launcher.
        SearchField {
            id: search

            Layout.fillWidth: true
            placeholder: "Keybinds"

            onKeyPressed: event => {
                if (event.key === Qt.Key_Down) {
                    root.scrollBy(Theme.cheatSheetRowHeight * 3);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    root.scrollBy(-Theme.cheatSheetRowHeight * 3);
                    event.accepted = true;
                }
            }
            onEscaped: root.close()
            onTextChanged: {
                root.query = text;
                rows.contentY = 0;
            }
        }

        // Host, because the cue and the empty state must be SIBLINGS of the
        // view: a Flickable's declared children go into its contentItem,
        // where they scroll with the content and feed childrenRect. The
        // Layout sizing moves up here for the same reason.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: rows

                anchors.fill: parent
                clip: true
                spacing: 0
                boundsBehavior: Flickable.StopAtBounds
                model: root.results

                // Group separators (owner 2026-08-21: "nice and visible"): the
                // group's name in the accent between two faded rules, the
                // library's header row. The group name is also part of every
                // row's search haystack, so typing "windows" keeps the whole
                // Windows section.
                section.property: "group"
                section.delegate: QsmShellComponents.ListRow {
                    required property string section

                    width: rows.width
                    header: true
                    accentHeader: true
                    primary: section
                }

                delegate: Item {
                    id: row

                    required property var modelData

                    width: rows.width
                    height: Theme.cheatSheetRowHeight

                    // No dim, no curl, no selection mark (owner 2026-08-21):
                    // there is nothing to select on a reference row, and the
                    // edge-curl compress made rows unreadable exactly where the
                    // reader was scanning toward. Every visible row reads at
                    // full strength; the bottom fade alone says "more below".

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space3
                        spacing: Theme.space3

                        // The combo is what you came to read, in its own fixed
                        // column so the keys form a scannable spine. Each key
                        // renders as its own cap (the library's `Kbd`) rather
                        // than as one run of technical-face text — a keybind is
                        // scanned against the keyboard, not read as a sentence.
                        Item {
                            Layout.preferredWidth: Theme.cheatSheetComboWidth
                            Layout.fillHeight: true
                            Accessible.role: Accessible.StaticText
                            Accessible.name: row.modelData.combo
                            QsmShellComponents.Kbd {
                                anchors.verticalCenter: parent.verticalCenter
                                combo: row.modelData.combo
                            }
                        }

                        QsmShellComponents.Prose {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: Text.AlignVCenter
                            role: "supporting"
                            text: row.modelData.description
                        }
                    }
                }
            }

            // On the HOST, not in the list. As a declared child of the
            // Flickable its `centerIn: parent` would centre on the scrolling
            // contentItem rather than the viewport; it would only ever show
            // at the one moment there is nothing to scroll.
            QsmShellComponents.EmptyState {
                anchors.centerIn: parent
                visible: rows.count === 0
                title: root.probeFailed
                    ? "Could not read keybinds (hyprctl)"
                    : (root.binds.length === 0 ? "No described keybinds" : "No match")
            }

            // Roll-away fade and position mark (owner 2026-08-21:
            // unmissable). Both are the library's now: the two rules this
            // surface learned the hard way -- read `visibleArea` rather than
            // contentY, and cap the mark's length so it stays a position and
            // not a gauge -- are what `ScrollCue` carries.
            //
            // The fade goes to the BAND's fill, not the surface's: this list
            // sits directly on the silhouette, so the last rows have to sink
            // into the band rather than into a surface colour that is not
            // there.
            QsmShellComponents.ScrollCue {
                view: rows
                fadeColor: Theme.band
            }
        }
    }
}
