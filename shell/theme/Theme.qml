pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.QsmShell.Style as QsmShellStyle
import qs.state

// The desktop's theme, and the one object the library asks (Style.backend).
//
// It answers only what a theme swap or this desktop changes: the colour roles,
// the fonts, the mode flags, the size-table entries it adds by name, and its own
// layout and policy. Every scale, role and strength the library defines is read
// from `QsmShellStyle.Style`; a name the library asks for and this object does
// not declare resolves to the library's value, which is the point.
// scripts/check-theme-contract fails when this file declares one anyway.
//
// A theme is a palette plus a wallpaper, one JSON per theme in shell/themes/,
// written by scripts/derive-theme.ts. Adding a theme is one new JSON and one
// image, no code. Colours cross-fade on a swap; the choice persists in
// ShellState's state file, so these are read-only views (writers go through
// apply() or ShellState).
QtObject {
    id: root

    readonly property bool reducedMotion: ShellState.reducedMotion
    readonly property bool reducedEffects: ShellState.reducedEffects

    // [{ id, name, wallpaper }] for every shell/themes/*.json: what the theme
    // list shows. The roles of the current theme come from `themeFile`.
    property var themes: []
    readonly property string current: ShellState.theme
    // Some IPC seams still read it.
    readonly property bool dark: current !== "mountain-dusk"

    function apply(themeId: string): void {
        if (themes.some(theme => theme.id === themeId))
            ShellState.theme = themeId;
    }

    // The current theme, read from its own file and blocking, so the first
    // frame has its colours and a swap reads the next file. A theme the state
    // names that is not installed, or a role its file lacks, is an error here,
    // never another theme's colour: a theme JSON is generated whole.
    property FileView themeFile: FileView {
        path: Quickshell.shellPath("themes/" + root.current + ".json")
        blockLoading: true
        onLoadFailed: error => console.error("Theme: cannot read", path, error)
    }
    readonly property var currentTheme: JSON.parse(themeFile.text())

    function role(name: string): color {
        return currentTheme.roles[name];
    }

    // THE roles. Components read these and nothing else: never a palette name,
    // never a derived rung. Each carries the theme-swap cross-fade.
    //
    // The neutral ladder is three steps, each the library's ladder ratio above
    // the one below (derive-theme.ts computes them with the library's own
    // function). Lightness is the only separation between containers: band is
    // the silhouette the shader paints (frame and every rollout), surface a
    // card inside it, overlay a popout over a card. A fourth level is a design
    // error, not a token.
    property color band: role("band")
    // The silhouette's edge colour, read by the library's ShellBorder.
    property color edgeColor: role("edgeColor")
    property color surface: role("surface")
    property color overlay: role("overlay")
    property color text: role("text")
    property color textMuted: role("textMuted")
    // primary is the one action per surface, accent is what is current, focus
    // is the keyboard ring. A theme may give them different pastels.
    property color primary: role("primary")
    // In QML a property named on<Capital> is a signal-handler name, and a
    // Behavior on one inside a singleton segfaults Quickshell at load.
    property color textOnPrimary: role("textOnPrimary")
    property color accent: role("accent")
    property color focus: role("focus")
    property color info: role("info")
    property color success: role("success")
    property color warning: role("warning")
    property color danger: role("danger")
    // The one load colour for every ring and meter: success until 70 percent,
    // warning to 90, danger above (the rail's readout thresholds).
    function loadTone(value: real): color {
        return value >= 0.9 ? danger : value >= 0.7 ? warning : success;
    }

    // Theme-swap choreography: the library has no theme swap, so the fade is
    // this desktop's own.
    readonly property int themeSwapDuration: 200

    // Every role fades: a swap that fades some and snaps others reads as a
    // glitch in the ones that snapped.
    Behavior on band { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on edgeColor { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on surface { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on overlay { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on text { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on textMuted { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on primary { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on textOnPrimary { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on accent { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on focus { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on info { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on success { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on warning { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on danger { ColorAnimation { duration: root.themeSwapDuration } }

    readonly property string wallpaper: currentTheme.wallpaper

    // ── Style.backend: fonts and size-table additions ──────────────────
    readonly property string fontFamily: "CaskaydiaCove Nerd Font"
    readonly property string technicalFontFamily: "CaskaydiaCove Nerd Font Mono"
    // Presets this desktop adds to a library table by name. An entry that
    // restates one the library already has is a copy, and the contract check
    // refuses it.
    readonly property var sizes: ({
        IconButton: { xl: 64 }
    })

    // ── Policy ─────────────────────────────────────────────────────────
    // Battery charge below which a reading turns danger: the popout and the
    // Performance tab share it, and the rail's low badge warns earlier so a
    // person has time to plug in.
    readonly property real lowBatteryFraction: 0.15
    readonly property real railLowBatteryFraction: 0.2
    // How long the OSD slider thumb keeps showing its value after the last
    // change.
    readonly property int osdValueHoldMs: 1000
    // A peeked rail band clears this long after the pointer leaves it.
    readonly property int railPeekGraceMs: 150
    // What the rest of the shell dims to while the session surface is open: a
    // modal backdrop that is not a disabled control, held at a disabled
    // control's strength.
    readonly property real opacitySessionDim: QsmShellStyle.Style.opacityDisabled
    // A dragged item stays readable over what it passes across.
    readonly property real opacityDrag: 0.85

    // ── Launcher, clipboard, cheat sheet ───────────────────────────────
    readonly property int launcherWidth: 600
    readonly property int launcherMaxRows: 7
    // A wallpaper thumbnail's width over its height; the picture box is as
    // tall as the leading box of a row.
    readonly property real wallpaperThumbAspect: 7 / 4
    readonly property string launcherRowSize: "lg"
    readonly property real launcherRowHeight: QsmShellStyle.Style.size("ListRow", launcherRowSize)
    // The clipboard is its own surface, narrower than the launcher because an
    // entry is one line of text, and taller in rows because scanning history
    // is the whole task.
    readonly property int clipboardWidth: 520
    readonly property int clipboardMaxRows: 10
    readonly property string clipboardRowSize: "md"
    readonly property real clipboardRowHeight: QsmShellStyle.Style.size("ListRow", clipboardRowSize)
    // Wider than the clipboard because a row is a key combo plus a sentence.
    // The combo column is fixed so the keys form a scannable spine.
    readonly property int cheatSheetWidth: 640
    readonly property real cheatSheetRowHeight: QsmShellStyle.Style.size("ListRow", "sm")
    readonly property int cheatSheetComboWidth: 190
    // The floor for a colour menu that normally takes the height of the column
    // it hangs off; the host hands the real span down.
    readonly property int colorMenuMinHeight: 240
    // The theme carousel's card, sized so two neighbours peek beside the
    // centred one at launcherWidth.
    readonly property int launcherThemeCardWidth: 220
    readonly property int launcherThemeCardHeight: 178

    // ── Top panel ──────────────────────────────────────────────────────
    // One outer footprint; tab content owns overflow, never the shell body.
    readonly property int panelWidth: 854
    readonly property int panelHeight: 560
    readonly property int panelNavigationWidth: 620
    readonly property string panelTabBarSize: "lg"
    readonly property real panelTabBarHeight: QsmShellStyle.Style.size("Segmented", panelTabBarSize)
    // Dashboard tab.
    readonly property int dashboardUserCardWidth: 320
    readonly property int dashboardWeatherCardWidth: 260
    readonly property int dashboardMediaCardWidth: 200
    readonly property int dashboardAvatarSize: 56
    readonly property int dashboardBadgeSize: 18
    readonly property int dashboardRingDiameter: 64
    readonly property int dashboardMediaArtSize: 72
    // The progress ring around album art. The library's own is a share of the
    // picture, which is too heavy around a large cover.
    readonly property int artworkRingStroke: 6
    // The panel's column width: the panel less the column's two margins. The
    // media tab fills it and never grows past it, so a long title or a player
    // picker cannot widen the panel.
    readonly property int mediaContentWidth: panelWidth - QsmShellStyle.Style.rolloutPadding * 2
    // Performance tab.
    readonly property int performanceThermalAlertC: 90 // icon and bar flip to danger above this
    readonly property real performanceThermalScaleC: 100 // bar fraction = temp / this
    readonly property int performanceNetworkCardWidth: 390
    // The sparkline's floor; the network card lets it grow into whatever
    // height the row's tallest card sets.
    readonly property int performanceSparklineHeight: 56
    readonly property int performanceBatteryTankWidth: 160
    readonly property int performanceBatteryTankHeight: 220

    // ── Frame, rail, notifications ─────────────────────────────────────
    // The left band is wider than the others: the rail lives inside it.
    readonly property int reservedLeft: 60
    // THE width of the band: every item (a glyph, the battery reading, the
    // clock, an app row, a tray icon) is this wide and answers on one hit
    // area, the capsule plus the band's left gutter. Height is the item's own:
    // a cell, an app row and the clock each take what their content needs.
    readonly property int railWidth: QsmShellStyle.Style.size("Control", "lg")
    // The capsule sits one space2 in from the screen edge, which leaves the rest
    // of the band between it and the rollout's wall. Both gaps are whole device
    // pixels at 1.25, 1.5 and 2 (multiples of 4), which a centred 6 and 6 is
    // not: the hit area crosses the first to the true edge, and a selected
    // pill reaches the wall across the second.
    readonly property int railGutter: QsmShellStyle.Style.space2
    readonly property int railReach: reservedLeft - railGutter - railWidth
    // One gap inside a group; groups are told apart by the divider.
    readonly property int railItemGap: QsmShellStyle.Style.space1
    // The height of a glyph cell, a tray icon and an app row.
    readonly property int railCellHeight: QsmShellStyle.Style.size("Control", "sm")
    // The logo and an app's icon take the mark step in a cell; plain glyphs
    // stay at the small icon step.
    readonly property int railMark: QsmShellStyle.Style.iconMd
    // A tray icon is recoloured to textMuted and lifted by this much, so a
    // coloured third-party glyph sits in the same tone as the rail's outline
    // glyphs.
    readonly property real trayGlyphBrightness: 0.5
    // The rail clock: time above a smaller numeric date.
    readonly property int railClockDigitSize: QsmShellStyle.Style.textLg
    readonly property int railClockDateSize: QsmShellStyle.Style.textSm
    // A group separator in the rail is the library's line at the band's
    // strength, inset from both walls.
    readonly property real railDividerInset: QsmShellStyle.Style.space2
    // A tray menu's separators are short lines.
    readonly property int menuSeparatorWidth: 96
    // How many connected devices the one BLE cell splits into before it stops
    // subdividing.
    readonly property int railDeviceMax: 4
    // Workspace slots: compact, because there is nothing to aim at beyond a
    // wheel and a click; the numbered accent chip is the one moving part and
    // overhangs its slot sideways.
    readonly property int railWorkspaceSlot: 16
    readonly property int railWorkspaceDot: 6
    // The dot is so small that the library's hover growth would be under half
    // a pixel, so it grows by half again to be seen at all.
    readonly property real railWorkspaceDotHoverScale: QsmShellStyle.Style.reducedMotion ? 1 : 1.5
    // The bell corner: a bulge that retracts when everything is read, the glyph
    // resting on the band's corner; its menu is a top-right modal the height of
    // the clipboard.
    readonly property int notificationBellWidth: QsmShellStyle.Style.size("Control", "md")
    readonly property int notificationBellHeight: QsmShellStyle.Style.size("Control", "sm")
    readonly property int notificationMenuHeight: 520

    // ── Handles ────────────────────────────────────────────────────────
    // The OSD circle nub and the top dot pair.
    readonly property real handleRadius: 7
    // The dots handle sits mostly inside the band: a negative proud pulls it
    // up, so only its lower part shows.
    readonly property real panelHandleProud: -1
    // The OSD nub sinks into the right band the same way: its centre sits two
    // pixels inside it.
    readonly property real osdHandleProud: handleRadius + 2
    readonly property real dotSpacing: 3
    readonly property real dotGlyphSize: 2.5
    readonly property int panelHandleHeight: 8

    // ── Popouts and OSD ────────────────────────────────────────────────
    readonly property int popoutWidth: 280
    // What a popout's content is given: its width less the rollout's padding.
    readonly property int popoutContentWidth: popoutWidth - QsmShellStyle.Style.rolloutPadding * 2
    // The Bluetooth popout caps its device rows, connected first.
    readonly property int popoutDeviceListMax: 5
    // The OSD is a narrow surface with a fat track: the value rides a circle
    // that travels the track, so the thumb has to contain the reading and the
    // track has to contain the thumb. A rollout is the band bulging, so its
    // content centres in body plus band and shifts half a band depth toward the
    // edge; the width is the one at which the track, the thumb's inset and
    // that shift all close without the track's last pixels drawing under the
    // frame.
    readonly property int osdWidth: 56
    readonly property int osdTrackWidth: 40
    readonly property int osdTrackHeight: 140
    readonly property int osdThumbSize: 28
    // Wheel nudge per notch, the one source for every output and brightness
    // control a wheel moves: the OSD channels, the sound popout and the rail's
    // scroll zones.
    readonly property real osdWheelStep: 0.05

    // Theme discovery: one process pass over shell/themes/*.json.
    property Process themesProbe: Process {
        command: ["bash", "-c",
            `cd "$(dirname "$0")" || exit 1
for f in themes/*.json; do printf '===%s\\n' "$f"; cat "$f"; done`,
            Quickshell.shellPath("shell.qml")]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const found = [];
                for (const chunk of text.split("===").slice(1)) {
                    const newline = chunk.indexOf("\n");
                    const file = chunk.slice(0, newline);
                    try {
                        const parsed = JSON.parse(chunk.slice(newline + 1));
                        found.push({
                            id: file.replace(/^themes\//, "").replace(/\.json$/, ""),
                            name: parsed.name,
                            wallpaper: parsed.wallpaper
                        });
                    } catch (error) {
                        console.warn("Theme: skipping unparsable", file);
                    }
                }
                root.themes = found;
            }
        }
    }

}
