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

    // Every layout number of this desktop, read from layout.json and blocking,
    // so the first frame has them. A key the file lacks is an error here, never
    // a default. A string is the name of the library token the desktop chose: a
    // Style property ("space2"), or "<Type>.<size>" for a size-table entry
    // ("Control.lg"). "a + b" is the sum of two.
    property FileView layoutFile: FileView {
        path: Quickshell.shellPath("theme/layout.json")
        blockLoading: true
        onLoadFailed: error => console.error("Theme: cannot read", path, error)
    }
    readonly property var layout: JSON.parse(layoutFile.text())

    function layoutKey(key: string): var {
        if (!(key in layout))
            throw new Error("Theme: layout.json has no key " + key);
        return layout[key];
    }

    function resolveToken(entry: var): var {
        if (typeof entry !== "string")
            return Array.isArray(entry) ? entry.map(resolveToken) : entry;
        if (entry.includes("+"))
            return entry.split("+").reduce((sum, part) => sum + resolveToken(part.trim()), 0);
        const dot = entry.indexOf(".");
        if (dot > 0)
            return QsmShellStyle.Style.size(entry.slice(0, dot), entry.slice(dot + 1));
        if (QsmShellStyle.Style[entry] === undefined)
            throw new Error("Theme: layout.json names no library token " + entry);
        return QsmShellStyle.Style[entry];
    }

    function layoutValue(key: string): var {
        return resolveToken(layoutKey(key));
    }

    // A string that is a name of its own (a font family, a size preset), never a token.
    function layoutName(key: string): string {
        return layoutKey(key);
    }

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
    // The one load colour for every ring and meter: the text role until 70
    // percent, warning to 90, danger above (the rail's readout thresholds). A
    // reading at rest is neutral; a colour appears only when the state is true.
    function loadTone(value: real): color {
        return value >= layoutValue("loadDanger") ? danger : value >= layoutValue("loadWarning") ? warning : text;
    }

    // Theme-swap choreography: the library has no theme swap, so the fade is
    // this desktop's own.
    readonly property int themeSwapDuration: layoutValue("themeSwapDuration")

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
    readonly property string fontFamily: layoutName("fontFamily")
    readonly property string technicalFontFamily: layoutName("technicalFontFamily")
    // Presets this desktop adds to a library table by name. An entry that
    // restates one the library already has is a copy, and the contract check
    // refuses it.
    readonly property var sizes: layoutValue("sizes")

    // ── Policy ─────────────────────────────────────────────────────────
    // Battery charge below which a reading turns danger: the popout and the
    // Performance tab share it, and the rail's low badge warns earlier so a
    // person has time to plug in.
    readonly property real lowBatteryFraction: layoutValue("lowBatteryFraction")
    readonly property real railLowBatteryFraction: layoutValue("railLowBatteryFraction")
    // How long the OSD slider thumb keeps showing its value after the last
    // change.
    readonly property int osdValueHoldMs: layoutValue("osdValueHoldMs")
    // A peeked rail band clears this long after the pointer leaves it.
    readonly property int railPeekGraceMs: layoutValue("railPeekGraceMs")
    // What the rest of the shell dims to while the session surface is open: a
    // modal backdrop that is not a disabled control, held at a disabled
    // control's strength.
    readonly property real opacitySessionDim: layoutValue("opacitySessionDim")
    // A dragged item stays readable over what it passes across.
    readonly property real opacityDrag: layoutValue("opacityDrag")

    // ── Launcher, clipboard, cheat sheet ───────────────────────────────
    readonly property int launcherWidth: layoutValue("launcherWidth")
    readonly property int launcherMaxRows: layoutValue("launcherMaxRows")
    // A wallpaper thumbnail's width over its height; the picture box is as
    // tall as the leading box of a row.
    readonly property real wallpaperThumbAspect: layoutValue("wallpaperThumbAspect")
    readonly property string launcherRowSize: layoutName("launcherRowSize")
    readonly property real launcherRowHeight: QsmShellStyle.Style.size("ListRow", launcherRowSize)
    // The clipboard is its own surface, narrower than the launcher because an
    // entry is one line of text: seven rows of the small size, the most any
    // list shows at once, and the older entries scroll behind an edge fade.
    readonly property int clipboardWidth: layoutValue("clipboardWidth")
    readonly property int clipboardMaxRows: layoutValue("clipboardMaxRows")
    readonly property int clipboardMaxResults: layoutValue("clipboardMaxResults")
    readonly property string clipboardRowSize: layoutName("clipboardRowSize")
    readonly property real clipboardRowHeight: QsmShellStyle.Style.size("ListRow", clipboardRowSize)
    // Wider than the clipboard because a row is a key combo plus a sentence.
    // The combo column is fixed so the keys form a scannable spine.
    readonly property int cheatSheetWidth: layoutValue("cheatSheetWidth")
    readonly property real cheatSheetRowHeight: layoutValue("cheatSheetRowHeight")
    readonly property int cheatSheetComboWidth: layoutValue("cheatSheetComboWidth")
    // The floor for a colour menu that normally takes the height of the column
    // it hangs off; the host hands the real span down.
    readonly property int colorMenuMinHeight: layoutValue("colorMenuMinHeight")
    // The theme carousel's card, sized so two neighbours peek beside the
    // centred one at launcherWidth.
    readonly property int launcherThemeCardWidth: layoutValue("launcherThemeCardWidth")
    readonly property int launcherThemeCardHeight: layoutValue("launcherThemeCardHeight")

    // ── Top panel ──────────────────────────────────────────────────────
    // One outer footprint; tab content owns overflow, never the shell body. The
    // panel is a compact rollout like the rail's: half of the shell's padding all
    // round, cards and tab bar one gap (8) apart, and the corner radius that keeps
    // every card concentric. The width is a multiple of 8, so the body is centred
    // between the rail band and the monitor's right edge with both edges on whole
    // device pixels at 1.25, and its content splits into three card columns of
    // 272; the height leaves two card rows of 228.
    readonly property int panelPadding: railPopoutPadding
    readonly property int panelRadius: railPopoutRadius
    readonly property int panelWidth: layoutValue("panelWidth")
    readonly property int panelHeight: layoutValue("panelHeight")
    readonly property int panelNavigationWidth: layoutValue("panelNavigationWidth")
    readonly property string panelTabBarSize: layoutName("panelTabBarSize")
    readonly property real panelTabBarHeight: QsmShellStyle.Style.size("Segmented", panelTabBarSize)
    // Cards of a tab, and the tab bar above them, sit this far apart, in both
    // directions.
    readonly property int panelGap: layoutValue("panelGap")
    // The box every tab fills: the same left and right edge as the tab bar and
    // one gap under it, so choosing a tab never moves where content starts.
    readonly property int panelContentWidth: panelWidth - panelPadding * 2
    readonly property int panelContentHeight: panelHeight - panelPadding * 2
        - panelTabBarHeight - panelGap
    // Dashboard tab: three columns. The middle one is the month calendar's own
    // width plus its card padding; the user card is the first and the media card
    // fills what is left.
    readonly property int dashboardUserCardWidth: layoutValue("dashboardUserCardWidth")
    readonly property int dashboardAvatarSize: layoutValue("dashboardAvatarSize")
    readonly property int dashboardBadgeSize: layoutValue("dashboardBadgeSize")
    readonly property int dashboardRingDiameter: layoutValue("dashboardRingDiameter")
    readonly property int dashboardMediaArtSize: layoutValue("dashboardMediaArtSize")
    // The progress ring around album art. The library's own is a share of the
    // picture, which is too heavy around a large cover.
    readonly property int artworkRingStroke: layoutValue("artworkRingStroke")
    // Performance tab.
    readonly property int performanceThermalAlertC: layoutValue("performanceThermalAlertC") // icon and bar flip to danger above this
    readonly property real performanceThermalScaleC: layoutValue("performanceThermalScaleC") // bar fraction = temp / this
    // The sparkline's floor; the network card lets it grow into whatever
    // height its row sets.
    readonly property int performanceSparklineHeight: layoutValue("performanceSparklineHeight")

    // ── Frame, rail, notifications ─────────────────────────────────────
    // The left band is wider than the others: the rail lives inside it. Its
    // width and the capsule's leave a multiple of 8 over, so everything
    // centred on the band's axis lands on whole device pixels at 1.25.
    readonly property int reservedLeft: layoutValue("reservedLeft")
    // THE width of the band: every item (a glyph, the battery reading, the
    // clock, an app row, a tray icon) is this wide and answers on one hit
    // area, the capsule plus the band's left gutter. Height is the item's own:
    // a cell, an app row and the clock each take what their content needs.
    readonly property int railWidth: layoutValue("railWidth")
    // The capsule sits one space2 in from the screen edge, which leaves the rest
    // of the band between it and the rollout's wall. Both gaps are whole device
    // pixels at 1.25, 1.5 and 2 (multiples of 4), which a centred 6 and 6 is
    // not: the hit area crosses the first to the true edge, and a selected
    // pill reaches the wall across the second.
    readonly property int railGutter: layoutValue("railGutter")
    readonly property int railReach: reservedLeft - railGutter - railWidth
    // One gap inside a group; groups are told apart by space, and by a line
    // where the groups either side look alike.
    readonly property int railItemGap: layoutValue("railItemGap")
    // The height of a glyph cell, a tray icon and an app row.
    readonly property int railCellHeight: layoutValue("railCellHeight")
    // The logo and an app's icon take the mark step in a cell; plain glyphs
    // stay at the small icon step.
    readonly property int railMark: layoutValue("railMark")
    // A tray icon is recoloured to textMuted and lifted by this much, so a
    // coloured third-party glyph sits in the same tone as the rail's outline
    // glyphs.
    readonly property real trayGlyphBrightness: layoutValue("trayGlyphBrightness")
    // The rail clock: time above a smaller numeric date.
    readonly property int railClockDigitSize: layoutValue("railClockDigitSize")
    readonly property int railClockDateSize: layoutValue("railClockDateSize")
    // A rail separator: half the capsule long, two device pixels thick.
    readonly property int railSeparatorWidth: railWidth / 2
    // A tray menu's separators are short lines.
    readonly property int menuSeparatorWidth: layoutValue("menuSeparatorWidth")
    // How many connected devices the one BLE cell splits into before it stops
    // subdividing.
    readonly property int railDeviceMax: layoutValue("railDeviceMax")
    // The workspace strip: a drum of all ten workspaces as plain dots around
    // one fixed lens. The lens (the accent chip with the number, and the window
    // rollout hanging from it) never moves; the dots scroll past it as a ring.
    // The marks scale with the rail's Control size from the md they were drawn
    // at and round UP to a multiple of 8, so a mark centred in the 48 capsule
    // never sits half a device pixel off the axis at 1.25.
    readonly property real railScale: QsmShellStyle.Style.size("Control", "lg")
        / QsmShellStyle.Style.size("Control", "md")
    function railMarkSize(px: real): int {
        return Math.ceil(px * railScale / QsmShellStyle.Style.space2) * QsmShellStyle.Style.space2;
    }
    readonly property int railWorkspaceSlot: railCellHeight
    readonly property int railWorkspaceSlots: layoutValue("railWorkspaceSlots")
    readonly property int railWorkspaceChipWidth: railMarkSize(layoutValue("railWorkspaceChipWidth"))
    readonly property int railWorkspaceChipHeight: railMarkSize(layoutValue("railWorkspaceChipHeight"))
    // A dot's pointer target: one step over the 24 floor, centred on the dot.
    // The ring's pitch is the strip's own, from the room its host gives it.
    readonly property int railDrumHit: layoutValue("railDrumHit")
    // The drum by distance from the lens, in dots (0 the lens, 5 the far side
    // of the ring): how big a dot is, how opaque and how hazy. The rollout
    // hangs over the dots below the lens and never moves them.
    readonly property var railDrumSize: layoutValue("railDrumSize")
    readonly property var railDrumOpacity: layoutValue("railDrumOpacity")
    readonly property var railDrumHaze: layoutValue("railDrumHaze")
    // Beyond this distance a dot is too faint to be a target.
    readonly property real railDrumReachable: layoutValue("railDrumReachable")
    // The hover growth of a dot: its few pixels would grow by under one.
    readonly property real railWorkspaceDotHoverScale: QsmShellStyle.Style.reducedMotion ? 1 : layoutValue("railWorkspaceDotHoverScale")
    // The bell corner: a bulge that retracts when everything is read, the glyph
    // resting on the band's corner; its menu is a top-right modal.
    readonly property int notificationBellWidth: layoutValue("notificationBellWidth")
    readonly property int notificationBellHeight: layoutValue("notificationBellHeight")
    // With unread the bulge carries the count beside the glyph: a pad, the 16
    // glyph, a step, the library's count chip and a pad, so the chip clears
    // the glyph and keeps a pad from the screen edge.
    readonly property int notificationBellPad: layoutValue("notificationBellPad")
    readonly property int notificationBellCountedWidth: notificationBellPad * 2
        + QsmShellStyle.Style.iconSm + QsmShellStyle.Style.space1 + QsmShellStyle.Style.badgeWidth
    readonly property int notificationMenuHeight: layoutValue("notificationMenuHeight")
    // The gap between what a rollout holds (a notification card, an OSD track,
    // a session tile) and the screen edge it rolls out of, and between it and
    // the silhouette's other edge: measured from the monitor, never from the
    // frame that runs along it. One gap, so content sits as far from the edges
    // as it does from its neighbours.
    readonly property int edgeGutter: layoutValue("edgeGutter")

    // ── Handles ────────────────────────────────────────────────────────
    // The OSD circle nub and the top dot pair.
    readonly property real handleRadius: layoutValue("handleRadius")
    // The dots handle straddles the band's inner edge: half of it in the band,
    // half proud of it, so its edges stay on the 4 px grid.
    readonly property real panelHandleProud: layoutValue("panelHandleProud")
    // The OSD nub sinks into the right band the same way: its centre sits two
    // pixels inside it.
    readonly property real osdHandleProud: handleRadius + layoutValue("osdHandleSink")
    // A dot is three device pixels at 1.25 and the gap four: a grip that stays
    // quiet. The handle snaps both to whole device pixels on any scale.
    readonly property real dotGlyphSize: layoutValue("dotGlyphSize")
    readonly property real dotSpacing: layoutValue("dotSpacing")
    readonly property int panelHandleHeight: layoutValue("panelHandleHeight")

    // ── Popouts and OSD ────────────────────────────────────────────────
    // A rail rollout is a compact card: it leaves half of the shell's rollout
    // padding around its content, and its corner radius is the body radius
    // plus that padding, so every body inside it stays concentric.
    readonly property int railPopoutPadding: layoutValue("railPopoutPadding")
    readonly property int railPopoutRadius: QsmShellStyle.Style.radiusBody + railPopoutPadding
    // What a popout's content is given: the calendar's seven cells and six gaps.
    readonly property int popoutContentWidth: layoutValue("popoutContentWidth")
    readonly property int popoutWidth: popoutContentWidth + railPopoutPadding * 2
    // A rollout body grows in this step. A body is centred on its rail cell,
    // whose centre is a multiple of 4, so half the body must be one too for
    // both of its edges to land on whole device pixels at 1.25.
    readonly property int popoutBodyStep: layoutValue("popoutBodyStep")
    // The Bluetooth popout caps its device rows, connected first.
    readonly property int popoutDeviceListMax: layoutValue("popoutDeviceListMax")
    // The OSD is a narrow surface with a fat track: the value rides a circle
    // that travels the track, so the thumb has to contain the reading and the
    // track has to contain the thumb. Its body runs to the monitor's right
    // edge, so the track keeps one gutter from the monitor and one from the
    // silhouette's other edge.
    readonly property int osdWidth: osdTrackWidth + edgeGutter * 2
    readonly property int osdTrackWidth: layoutValue("osdTrackWidth")
    readonly property int osdTrackHeight: layoutValue("osdTrackHeight")
    readonly property int osdThumbSize: layoutValue("osdThumbSize")
    // Wheel nudge per notch, the one source for every output and brightness
    // control a wheel moves: the OSD channels, the sound popout and the rail's
    // scroll zones.
    readonly property real osdWheelStep: layoutValue("osdWheelStep")

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
