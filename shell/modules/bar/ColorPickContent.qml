pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.QsmShell.Components as QsmShellComponents
import qs.QsmShell.Style as QsmShellStyle
import qs.components
import qs.services
import qs.theme

// The colour MENU. This second rollout IS the whole thing: the features live in
// the surface you already opened, not one step further out.
//
// Layout, top to bottom:
//
//   [ swatch ][ hex ][ copy ]      the current colour, the LARGE row.
//                                  clicking the swatch starts a pick.
//   History                        every pick as a swatch, newest first, in a
//   [][][][][][][][][]             grid that holds all of them: nothing scrolls,
//   [][][][][][][][][]             so no edge fade ever covers a colour.
//   Accent set                     derived tokens from the current colour.
//   [][][][][]
//   [ Open colour editor ]
//
// The swatch is the ONLY way to start a pick, so the rail cell that opens this
// menu is hover-only — the same reason the `zap` cell is (03: "nothing for a
// click to do that the column does not do better"). Two doors to picking would
// be the thing 09 removes.
//
// No colour-maths helper: QML's color type carries hslHue/hslSaturation/
// hslLightness and Qt.hsla() builds one back.
Item {
    id: root

    // The height of the rollout this menu hangs off, handed down by the host.
    // The menu FILLS it rather than hugging its content, so its seam with the
    // column it hangs off is one straight line.
    property real spanHeight: 0

    // What a control here did, and which control did it. Every actionable row
    // in this menu reports itself, because a history delegate and an accent
    // square are not reachable by name from outside this component.
    signal interacted(string action, var detail)

    // The colour being worked on: an explicitly chosen history entry, else the
    // newest pick. Cleared back to the newest when a new pick lands, because
    // the thing just read off the screen is the thing to work on.
    property string chosen: ""
    // chosen -> lastColor -> history. `lastColor` is the LIVE fact, set the
    // instant a pick or an edit returns; the history is a persisted derivative
    // of it. Keying the menu off the derivative meant that if remembering ever
    // failed, the whole surface reported "no colour": empty top row, empty
    // history, and the editor row (gated on `has`) not drawn at all.
    readonly property string current: root.chosen.length > 0 ? root.chosen
        : ColorPickService.lastColor.length > 0 ? ColorPickService.lastColor
        : (ColorPickService.history[0] ?? "")
    readonly property bool has: root.current.length > 0
    readonly property color base: root.has ? root.current : Theme.surface

    // The actual swatch a user clicks to start a pick, and the lines the
    // surface renders about that pick. Both are the rendered items, so input
    // reaches the real control and the busy state is read from real text.
    readonly property Item pickControl: currentLine.swatch
    readonly property string busyReadout: busyLine.text
    readonly property bool busyVisible: busyLine.visible
    readonly property string copyReadout: currentLine.copyFeedback

    function control(name: string): var {
        return name === "pick-colour" ? root.pickControl : null;
    }
    function readout(name: string): var {
        if (name === "busy-line")
            return root.busyReadout;
        if (name === "busy-visible")
            return root.busyVisible;
        if (name === "copy-feedback")
            return root.copyReadout;
        return null;
    }

    // Greys report hue -1 (achromatic); treat them as hue zero so the ramp still
    // works. A harmony set off a grey is meaningless either way.
    readonly property real baseHue: root.base.hslHue < 0 ? 0 : root.base.hslHue

    implicitWidth: Theme.popoutContentWidth
    // NOT derived from `column`: column fills this item, so reading its
    // implicitHeight back into this one is the childrenRect binding loop the
    // PRIMER warns about. The host hands the span down; the token is the floor
    // for the frame before it does.
    implicitHeight: Math.max(Theme.colorMenuMinHeight, root.spanHeight)

    function hex(value: color): string {
        return value.toString().toUpperCase();
    }

    function rotated(delta: real): color {
        return Qt.hsla((root.baseHue + delta + 1) % 1,
            root.base.hslSaturation, root.base.hslLightness, 1);
    }

    function shade(lightness: real): color {
        return Qt.hsla(root.baseHue, root.base.hslSaturation, lightness, 1);
    }

    Connections {
        target: ColorPickService

        function onLastColorChanged(): void {
            root.chosen = "";
        }
    }

    // The current colour: [swatch][hex][copy]. The swatch starts a pick.
    component ColorLine: RowLayout {
        id: line

        required property color value
        // FALSE = there is no colour here yet, so the swatch is an empty frame
        // and there is no hex and no copy. Measured on the live menu: with
        // nothing picked the row printed #21142B -- Theme.surface, the card's
        // OWN background -- beside a working copy button, which is the same
        // defect as `>calc` offering "qalc not installed" as a result. A
        // placeholder must not be copyable.
        property bool filled: true

        readonly property string text: root.hex(line.value)
        readonly property Item swatch: swatchControl
        // What the copy button is acknowledging right now, read off the glyph
        // it is actually painting.
        readonly property string copyFeedback: copyButton.icon

        spacing: QsmShellStyle.Style.space2

        // An unfilled row is an empty SLOT, not a very dark colour, which is
        // the distinction ColorSwatch.empty exists for.
        QsmShellComponents.ColorSwatch {
            id: swatchControl
            size: QsmShellStyle.Style.space6
            sample: line.filled ? line.value : "transparent"
            empty: !line.filled
            onClicked: {
                // An empty swatch is a real button with no value to
                // report, and it must not invent one from the card's own
                // background.
                root.interacted("pick", line.filled
                    ? { "target": "swatch", "value": line.text }
                    : { "target": "swatch" });
                ColorPickService.pick();
            }
        }

        QsmShellComponents.Prose {
            // A hex string is a VALUE in the technical face — the same
            // pairing as a percentage or an address.
            role: "reading"
            Layout.fillWidth: true
            visible: line.filled
            text: line.text
            font.pixelSize: QsmShellStyle.Style.textMd
            font.weight: QsmShellStyle.Style.weightBold
        }

        // Holds the row's shape while empty, so the swatch does not slide
        // sideways the moment the first colour lands.
        Item {
            Layout.fillWidth: true
            visible: !line.filled
        }

        // Copy is its own control. It ACKNOWLEDGES: the glyph becomes a tick in
        // the success colour for a beat, because a clipboard write is
        // otherwise invisible.
        QsmShellComponents.IconButton {
            id: copyButton
            readonly property bool justCopied: ColorPickService.copied === line.text

            visible: line.filled
            icon: justCopied ? "check" : "copy"
            color: justCopied ? Theme.success : Theme.textMuted
            size: "xs"
            onClicked: {
                root.interacted("copy", { "target": "copy", "value": line.text });
                ColorPickService.copy(line.text);
            }
        }
    }

    ColumnLayout {
        id: column

        anchors.fill: parent
        spacing: QsmShellStyle.Style.space2

        // Present even with nothing picked: it is the pick button, and an empty
        // menu with no way to fill it is a dead end.
        ColorLine {
            id: currentLine
            Layout.fillWidth: true
            value: root.base
            filled: root.has
        }

        // --- history ---------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true

            QsmShellComponents.Prose {
                role: "metadata"
                Layout.fillWidth: true
                text: "History"
            }

            // Only while it matters, in the label's own row so the menu never
            // grows for it.
            QsmShellComponents.Prose {
                id: busyLine
                role: "metadata"
                visible: ColorPickService.busy
                text: "Picking…"
            }
        }

        // Every swatch the service keeps, in the rows they need, so the grid
        // has one height whatever the history holds and nothing scrolls: a
        // scroll area this short ate its own content in edge fades.
        Flow {
            id: historyGrid

            readonly property real swatch: QsmShellStyle.Style.space5
            readonly property int columns: Math.max(1, Math.floor(
                (Theme.popoutContentWidth + spacing) / (swatch + spacing)))
            readonly property int rows: Math.ceil(ColorPickService.historyLimit / columns)

            Layout.fillWidth: true
            Layout.preferredHeight: rows * swatch + (rows - 1) * spacing
            spacing: QsmShellStyle.Style.space1

            // The empty state lives INSIDE the region it describes, so the
            // region holds its shape either way.
            QsmShellComponents.Prose {
                role: "metadata"
                width: historyGrid.width
                visible: ColorPickService.history.length === 0
                wrapMode: Text.WordWrap
                text: ColorPickService.busy
                    ? "Pick a pixel, or Escape to cancel"
                    : "No colour yet — click the square to read any pixel on any monitor"
                color: QsmShellStyle.Style.recede(QsmShellStyle.Style.textMuted)
            }

            Repeater {
                model: ColorPickService.history.slice(0, ColorPickService.historyLimit)

                QsmShellComponents.ColorSwatch {
                    id: entry

                    required property string modelData
                    readonly property string text: root.hex(entry.sample)

                    size: historyGrid.swatch
                    target: historyGrid.swatch
                    sample: modelData
                    selected: entry.text === root.hex(root.base)
                    onClicked: {
                        root.chosen = entry.text;
                        root.interacted("select", { "target": "history", "value": entry.text });
                    }
                }
            }
        }

        // --- accent generation ------------------------------------------------
        // Accent generation for the picked colour. The
        // shell's own accent language: an accent, a secondary a third of the
        // wheel away, and the ramp a theme needs for its surfaces. Named for
        // what a THEME calls them, not for the maths, because that is the form
        // they get pasted into.
        QsmShellComponents.Prose {
            role: "metadata"
            Layout.fillWidth: true
            visible: root.has
            text: "Accent set"
        }

        // Squares only, no hex rows. Each one carries its OWN copy
        // acknowledgement — a tick over the swatch for a beat — rather than the
        // menu keeping one shared readout line. Deliberately not a separate copy
        // BUTTON per square: clicking the swatch is already the copy, and a
        // second control for one action is what 09 removes. The tick sits on
        // the affordance that does the copy.
        RowLayout {
            Layout.fillWidth: true
            visible: root.has
            spacing: QsmShellStyle.Style.space1

            Repeater {
                model: [root.base, root.rotated(1 / 3), root.rotated(0.5),
                    root.shade(0.28), root.shade(0.42)]

                QsmShellComponents.ColorSwatch {
                    id: token

                    required property color modelData

                    readonly property string hex: root.hex(token.modelData)
                    readonly property bool justCopied: ColorPickService.copied === token.hex

                    size: QsmShellStyle.Style.space5
                    target: QsmShellStyle.Style.space5
                    sample: token.modelData
                    onClicked: {
                        root.interacted("copy", { "target": "accent", "value": token.hex });
                        ColorPickService.copy(token.hex);
                    }

                    QsmShellComponents.SvgIcon {
                        anchors.centerIn: parent
                        visible: token.justCopied
                        name: "check"
                        size: QsmShellStyle.Style.iconXs
                        // The swatch already worked out which ink reads on its
                        // own sample, by WCAG contrast against the composited
                        // colour; `hslLightness > 0.5` is cruder and disagrees
                        // with it in the mid-tones.
                        color: token.ink
                    }
                }
            }
        }

        // --- the editor ------------------------------------------------------
        // Hands the colour at the TOP to a real editor and
        // takes back whatever comes out as a new pick. Not a second pick route:
        // picking reads a pixel off the screen, editing changes a colour you
        // already have. Different actions, one control each.
        PopoutRow {
            Layout.fillWidth: true
            visible: root.has
            icon: "application"
            label: ColorPickService.editing ? "Editor open…" : "Open colour editor"
            disabled: !ColorPickService.editorAvailable || ColorPickService.editing
            onClicked: {
                root.interacted("edit", { "target": "editor", "value": root.hex(root.base) });
                ColorPickService.edit(root.hex(root.base));
            }
        }

        // The degraded state names the package, the way the battery popout names
        // power-profiles-daemon rather than just going quiet.
        QsmShellComponents.Prose {
            role: "metadata"
            Layout.fillWidth: true
            visible: !ColorPickService.editorAvailable
            wrapMode: Text.WordWrap
            text: "No colour editor — install oklch-color-picker"
        }

        Item { Layout.fillHeight: true }
    }
}
