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

// Clipboard history, its own surface.
//
// Clipboard history is reached constantly and by one key, so it earns a
// surface instead of a launcher prefix (09 one-path law: one route to one
// feature).
//
// Reachable ONLY by its keybind. There is no handle, no hover zone, nothing on
// the band, which makes the keybind cheat sheet load-bearing rather than
// decorative: a surface with no visible affordance has to be discoverable
// somewhere.
//
// The search field sits at the TOP because this surface attaches to the TOP
// band. The rule across the shell is that the field goes nearest the attached
// edge — the launcher rises from the bottom and puts its field at the bottom
// (07), the notification centre reads down from the top and puts it at the top
// (04) — so the thing you type into is always closest to where the surface
// came from, and results flow away from it.
Item {
    id: root

    property string query

    // The one owner of the body height: the visible rows, the search field and
    // the gap between them. The host reads it and computes nothing.
    readonly property real preferredBodyHeight: Theme.clipboardMaxRows * Theme.clipboardRowHeight
        + (Theme.clipboardMaxRows - 1) * QsmShellStyle.Style.space1
        + search.implicitHeight + QsmShellStyle.Style.space2 + QsmShellStyle.Style.rolloutPadding * 2

    // Why a read or a copy did not happen, shown where the list is. A failed
    // read is not an empty history, and a failed copy must not close the
    // surface as if it had worked.
    property string readFailed: ""
    property string copyFailed: ""

    // Deterministic thumbnail path: cache dir plus the cliphist id, so nothing
    // has to be parsed back out of the decoder. The only unknown is whether
    // the file has landed yet, which is exactly what the generation counter
    // below reports.
    property var clipLines: []
    property int clipThumbGeneration: 0
    readonly property string clipCacheDir:
        (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/qsm/clip"

    // cliphist describes an image entry only by its own placeholder text —
    // "3823\t[[ binary data 8 KiB png 124x109 ]]". This is the one place that
    // reads it, for both the row's label and the decoded file's name.
    //
    // The cache file keeps the REAL extension: Qt picks an image reader by
    // suffix first, and a decoded png saved as ".img" loaded as nothing at all
    // — a visible empty frame where the picture should be.
    function clipImageOf(line: string): var {
        const match = line.match(/binary data\s+(\S+\s+\S+)\s+(\w+)\s+(\S+)/i);
        if (!match)
            return null;

        const id = line.split("\t")[0];
        const ext = match[2].toLowerCase();
        return { id: id, size: match[1], ext: ext, dims: match[3], file: `${id}.${ext}` };
    }

    // Ties break on the ORIGINAL position, which is cliphist's own
    // newest-first order. Without that tiebreaker an empty filter scores every
    // line 0 and the sort is free to scramble them — QML's engine does not
    // promise a stable sort — so the list showed an arbitrary handful rather
    // than the last things copied.
    // A clipboard entry can be a whole file, and a plain subsequence match will
    // find any four letters somewhere inside one in order -- "zzqq" matched two
    // real entries and "No match" was practically unreachable. The
    // span cap says the match has to be LOCAL: a query of N characters that only
    // matches by wandering across more than ~8N of a payload is not the entry
    // anyone meant. The floor keeps one- and two-character queries usable.
    readonly property int matchSpan: Math.max(24, root.query.length * 8)

    readonly property var results: clipLines
        .map((line, index) => ({ line: line, index: index,
            score: QsmShellComponents.Fuzzy.score(root.query, line, root.matchSpan) }))
        .filter(item => item.score >= 0)
        .sort((left, right) => right.score - left.score || left.index - right.index)
        .slice(0, Theme.clipboardMaxResults)
        .map(item => {
            const image = root.clipImageOf(item.line);
            return {
                kind: "clip",
                icon: "",
                label: image
                    ? `${image.ext.toUpperCase()} · ${image.dims} · ${image.size}`
                    : item.line.split("\t").slice(1).join(" "),
                sub: "",
                thumb: (image && root.clipThumbGeneration > 0)
                    ? `file://${root.clipCacheDir}/${image.file}` : "",
                data: item.line
            };
        })

    function open(): void {
        query = "";
        copyFailed = "";
        search.clear();
        rows.currentIndex = 0;
        clipProbe.running = true;
        Qt.callLater(() => search.forceActiveFocus());
    }

    function close(): void {
        ShellState.closeModal();
    }

    // The pipeline fails as a whole: without pipefail a failed decode hands
    // wl-copy an empty stream and the clipboard is cleared with exit 0.
    function activate(index: int): void {
        const item = results[index];
        if (!item)
            return;

        runner.command = ["bash", "-c", 'set -o pipefail; printf "%s" "$1" | cliphist decode | wl-copy', "_", item.data];
        runner.running = true;
    }

    function remove(index: int): void {
        const item = results[index];
        if (!item)
            return;

        clipRemover.command = ["bash", "-c", 'printf "%s" "$1" | cliphist delete', "_", item.data];
        clipRemover.running = true;
    }

    // Decode image entries to files so the rows can SHOW them. cliphist hands
    // over only the placeholder text, so the picture has to be pulled out of
    // the store; the cache means a second visit costs nothing, and it is pruned
    // so a clipboard full of screenshots cannot grow without bound.
    function decodeClipImages(): void {
        const images = clipLines
            .map(line => root.clipImageOf(line))
            .filter(Boolean)
            .slice(0, 20);
        if (images.length === 0)
            return;

        clipThumbProbe.command = ["bash", "-c", `dir="\${XDG_CACHE_HOME:-$HOME/.cache}/qsm/clip"
mkdir -p "$dir" || exit 0
for name in "$@"; do
  file="$dir/$name"
  # cliphist reads the entry from STDIN. Given the id as an argument it exits
  # silently with nothing, so every row would fall back to the glyph.
  [ -s "$file" ] || printf '%s' "\${name%%.*}" | cliphist decode > "$file" 2>/dev/null || true
  [ -s "$file" ] || rm -f "$file"
done
ls -1t "$dir" 2>/dev/null | tail -n +41 | while read -r stale; do rm -f "$dir/$stale"; done
exit 0`, "_", ...images.map(image => image.file)];
        clipThumbProbe.running = true;
    }

    Process {
        id: clipProbe
        command: Delegate.argv("clipboard", ["list"])
        stdout: StdioCollector {
            onStreamFinished: {
                root.clipLines = text.split("\n").filter(line => line.length > 0);
                root.decodeClipImages();
            }
        }
        onExited: exitCode => root.readFailed = exitCode === 0 ? "" : `cliphist exited with code ${exitCode}`
    }

    Process {
        id: clipThumbProbe
        onExited: root.clipThumbGeneration++
    }

    Process {
        id: clipRemover
        onExited: clipProbe.running = true
    }

    Process {
        id: runner
        onExited: exitCode => {
            if (exitCode === 0)
                root.close();
            else
                root.copyFailed = `wl-copy exited with code ${exitCode}`;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: QsmShellStyle.Style.rolloutPadding
        spacing: QsmShellStyle.Style.space2

        SearchField {
            id: search

            Layout.fillWidth: true
            placeholder: "Clipboard history"

            // Ctrl+Delete removes the highlighted entry; a plain Delete is
            // still the key that edits the query.
            onKeyPressed: event => {
                if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ControlModifier)) {
                    root.remove(rows.currentIndex);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    rows.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    rows.decrementCurrentIndex();
                    event.accepted = true;
                }
                if (event.accepted) {
                    root.copyFailed = "";
                    ShellState.claimKeyboardSelection();
                }
            }

            onAccepted: root.activate(rows.currentIndex)
            onEscaped: root.close()
            onTextChanged: {
                root.query = text;
                root.copyFailed = "";
                rows.currentIndex = 0;
            }
        }

        // Reading DOWN from the field, unlike the launcher's bottom-up list:
        // this surface descends from the top band, so newest-first flows away
        // from the input rather than back toward it.
        // Host, because the cue must be a SIBLING of the view: a Flickable's
        // declared children go into its contentItem, where they scroll with
        // the content and feed childrenRect. Inside a Layout a sibling would
        // claim a cell of its own, so the Layout sizing moves up here.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: rows

                anchors.fill: parent
                visible: root.copyFailed.length === 0
                clip: true
                spacing: QsmShellStyle.Style.space1
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds
                model: root.results

                delegate: ResultRow {
                    id: clipRow

                    required property var modelData
                    required property int index

                    width: rows.width
                    item: modelData
                    size: Theme.clipboardRowSize
                    selected: ListView.isCurrentItem
                    onActivated: root.activate(index)
                    // Pointer and keyboard share ONE cursor (09 one-path).
                    onHoveredEntered: rows.currentIndex = index

                    // The pointer's way to remove an entry, on the row that
                    // Enter would copy and nowhere else.
                    QsmShellComponents.IconButton {
                        visible: clipRow.selected
                        icon: "trash-2"
                        size: "xs"
                        color: QsmShellStyle.Style.textMuted
                        accessibleName: "Remove from history"
                        onClicked: root.remove(clipRow.index)
                    }
                }
            }

            // On the HOST, not in the list. As a declared child of the
            // Flickable its `centerIn: parent` meant the scrolling contentItem
            // rather than the viewport; it never showed because the only time
            // it is visible is when there is nothing to scroll.
            QsmShellComponents.EmptyState {
                anchors.centerIn: parent
                visible: rows.count === 0 || root.copyFailed.length > 0
                icon: root.copyFailed.length > 0 || root.readFailed.length > 0 ? "alert-triangle" : ""
                title: root.copyFailed.length > 0 ? "Could not copy the entry (wl-copy)"
                    : root.readFailed.length > 0 ? "Could not read clipboard history (cliphist)"
                    : root.clipLines.length === 0 ? "Clipboard history is empty"
                    : "No match"
                detail: root.copyFailed.length > 0 ? root.copyFailed : root.readFailed
            }

            // The fade says there is more past an edge; a mark beside it said
            // so a second time.
            QsmShellComponents.ScrollCue {
                view: rows
                fadeColor: Theme.band
                indicator: false
                // Shallower than a row: the list is seven rows tall, and the
                // default depth would take the seventh.
                fadeDepth: QsmShellStyle.Style.space5
            }
        }
    }
}
