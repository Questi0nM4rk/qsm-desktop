pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.state

// Theme engine (11-theme / 7b): a theme = palette + wallpaper pair, one
// JSON per theme in shell/themes/ — adding a theme is one new JSON + image,
// ZERO code (N-theme law). Colors cross-fade 200ms on swap; choice
// persists — in ShellState's ONE state file since the 09 merge; these are
// read-only views (writers go through apply() or ShellState directly).
QtObject {
    id: root

    readonly property bool reducedMotion: ShellState.reducedMotion
    readonly property bool reducedEffects: ShellState.reducedEffects

    // [{ id, name, wallpaper, roles }] parsed from shell/themes/*.json, each
    // written by scripts/derive-theme.ts from its wallpaper.
    property var themes: []
    readonly property string current: ShellState.theme
    readonly property var currentTheme: themes.find(theme => theme.id === current) ?? null
    readonly property string modeName: currentTheme?.name ?? "Deep Night"
    // Legacy flag some seams still read (IPC status/themeToggle).
    readonly property bool dark: current !== "mountain-dusk"

    function apply(themeId: string): void {
        if (themes.some(theme => theme.id === themeId))
            ShellState.theme = themeId;
    }

    // Deep Night's roles, the value every colour holds until themesProbe has
    // read shell/themes/*.json. Not a fallback for a theme missing a role: a
    // theme JSON is generated whole by scripts/derive-theme.ts, and a role it
    // lacks is reported once below.
    readonly property var preload: ({
        band: "#271E30", edgeColor: "#5E357F", surface: "#42394C", overlay: "#534A5E",
        text: "#F0ECF5", textMuted: "#C5BAD1",
        primary: "#D9B4EA", textOnPrimary: "#271E30", accent: "#D9B4EA", focus: "#D9B4EA",
        info: "#89CFF1", success: "#A2D3A2", warning: "#D9C284", danger: "#F5AEB7"
    })

    readonly property var _missingReported: ({})
    function role(name: string): color {
        if (!currentTheme)
            return preload[name];
        const value = currentTheme.roles[name];
        if (value === undefined) {
            const key = current + "." + name;
            if (!_missingReported[key]) {
                _missingReported[key] = true;
                console.error("Theme: theme", current, "has no role", name, "- regenerate it with scripts/derive-theme.ts");
            }
            return preload[name];
        }
        return value;
    }

    // THE roles (11-theme). Components read these and nothing else: never a
    // palette name, never a derived rung. Each carries the 200ms theme-swap
    // cross-fade.
    //
    // The neutral ladder, 1.30:1 per step, is the only separation the shell
    // has: no hairline, no border, no rim, no shadow. band is the one
    // silhouette the shader paints (frame and every rollout); surface is a
    // card inside it; overlay is a popout over a card. A fourth level is a
    // design error, not a token.
    property color band: role("band")
    // The silhouette's edge colour (01-frame): read by the library's
    // ShellBorder, never by a component.
    property color edgeColor: role("edgeColor")
    property color surface: role("surface")
    property color overlay: role("overlay")
    property color text: role("text")
    property color textMuted: role("textMuted")
    // primary is the one action per surface; accent is what is current; focus
    // is the keyboard ring. They share a pastel today, and the split is what
    // lets a theme give them different ones.
    property color primary: role("primary")
    // The design system calls this on-primary. In QML a property named
    // on<Capital> is a signal-handler name, and a Behavior on one inside a
    // singleton segfaults Quickshell 0.3.2 / Qt 6.12 at load (measured
    // 2026-10-16: the shell crash-looped until the rename).
    property color textOnPrimary: role("textOnPrimary")
    property color accent: role("accent")
    property color focus: role("focus")
    property color info: role("info")
    property color success: role("success")
    property color warning: role("warning")
    property color danger: role("danger")
    // Not a role: the colour under the one shadow still open in 05-osd (the
    // fullscreen capsule over a bright client). The library's floating shadow
    // reads it; nothing in the frame does.
    readonly property color shadow: "#000000"

    // Theme-swap choreography (11 DEFAULT: 200ms). Lives HERE, not in Motion:
    // Motion already reads Theme.reducedMotion, and a token both singletons
    // need would make that a cycle.
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

    readonly property string wallpaper: currentTheme?.wallpaper ?? "assets/wallpapers/dark-rain-world.png"

    readonly property real surfaceOpacity: reducedEffects ? 1 : dark ? 0.9 : 0.94
    // Disabled-affordance opacity — icon-buttons whose action is currently
    // unavailable (e.g. shuffle/repeat/seek unsupported by the active player).
    readonly property real opacityDisabled: 0.35
    readonly property real opacitySelected: 0.12

    // --- Library contract (Style.backend) -------------------------------
    // Style resolves every token as `backend?.x ?? Tokens.x`, so a name the
    // Theme does not answer silently reads the LIBRARY's deep-night default
    // and stops responding to a theme swap. scripts/check-theme-contract
    // fails if this list drifts from what Style asks for.
    readonly property real lineTight: 1.2       // headings, one line
    readonly property real lineHeading: 1.25
    readonly property real lineBody: 1.55       // wrapping prose only
    readonly property real trackingWide: 1.4    // section rules, uppercase
    readonly property real opacityRecede: 0.45  // non-current row in a pick list
    readonly property int badgeHeight: 16
    readonly property int trackThickness: 6     // slider / meter track
    readonly property int ringDiameter: 150
    readonly property int ringStroke: 8
    readonly property int tileWidth: 96         // session action tile
    readonly property int tileHeight: 72
    // The library's floating shadow, read only by the fullscreen capsule
    // (05-osd OPEN): the frame itself never draws a shadow.
    readonly property real floatingShadowOpacity: 0.28
    readonly property real floatingShadowBlur: 0.6
    readonly property real floatingShadowOffset: 8
    readonly property int floatingShadowExtent: 24
    readonly property int notificationPreviewHeight: 80
    readonly property int notificationBodyViewportHeight: 96
    readonly property var sizes: ({
        Switch: { sm: 12, md: 16, lg: 24 },
        Checkbox: { sm: 12, md: 16, lg: 24 },
        Radio: { sm: 12, md: 16, lg: 24 },
        SpinBox: { sm: 32, md: 40, lg: 52 },
        Slider: { sm: 16, md: 24, lg: 40 },
        TextField: { sm: 32, md: 40, lg: 52 },
        Segmented: { sm: 32, md: 40, lg: 52 }
    })

    readonly property string fontFamily: "CaskaydiaCove Nerd Font"
    readonly property string technicalFontFamily: "CaskaydiaCove Nerd Font Mono"
    // ONE text ladder, and every step is a real step: each is at least 1.125x
    // the one below, which is the smallest ratio the eye reads as a DIFFERENT
    // size rather than as the same size rendered slightly off.
    //
    // xs was 11 and sm is 12, a ratio of 1.09 — the two most-used steps in the
    // shell, 92 uses between them, and indistinguishable. That meant `Prose`
    // had a size channel it thought it was using and was not: metadata and
    // body differed only by colour and weight. At 10 the step is visible and
    // the whole ladder passes without touching anything above it.
    //
    // 10 is the floor, not below it. The old textXxs of 8px sat under anything
    // a person actually reads and is gone; 10 was rendered against this exact
    // font before being chosen.
    readonly property int textXs: 10
    readonly property int textSm: 12
    readonly property int textMd: 14
    readonly property int textLg: 18
    readonly property int textXl: 22
    // Big display numbers (weather temperature, ring values).
    readonly property int textDisplay: 28
    // The one step above the ladder: a number read from across the room —
    // the dashboard's clock. 28px digits sat lost in a 415x270 card.
    readonly property int textHero: 44
    readonly property int weightRegular: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightBold: Font.DemiBold

    // The half-step below the 4px grid. Glyph-tight stacks — an icon over its
    // own reading, a menu row over the next — need a gap that reads as ONE
    // thing rather than two, and 4 is already too much air for that. It was
    // being typed as a bare 2 in five places, which is how a scale quietly
    // acquires a value nobody chose.
    readonly property int spaceTight: 2
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 24
    readonly property int space6: 32

    // ONE rounding ladder, caelestia's: 4 / 8 / 12 / 16 / 20 / 28 / 32 / 48.
    // Before this the shell ran 10/14/18/26 as its "scale" and then reached
    // past it for 16, 25, 28, 42 and 56 wherever a card wanted something else
    // — five corner radii belonging to no system, which is exactly what makes
    // a UI read as assembled rather than designed.
    readonly property int radiusXs: 4
    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16
    readonly property int radiusXl: 20
    readonly property int radius2xl: 28
    readonly property int radius3xl: 32
    readonly property int radius4xl: 48
    readonly property int radiusPill: 999

    // Smallest glyph the shell draws — the quartered BLE cell, the menu-row
    // marks, and the rail's pin (deliberately a rung under its neighbours).
    readonly property int iconXs: 12
    // The rail cell glyph since 2026-08-24 (RailEntry.iconSize).
    readonly property int iconSm: 16
    readonly property int iconMd: 20
    readonly property int iconLg: 26
    readonly property int iconXl: 34
    // Dashboard weather glyph — a step above iconXl.
    readonly property int iconXxl: 44

    // Launcher (07 RATIFIED, amended 2026-08-17 — caelestia numbers): width,
    // visible row cap, and row height. bodyHeight derives from these.
    readonly property int launcherWidth: 600
    readonly property int launcherMaxRows: 7
    readonly property int launcherRowHeight: 57
    // Clipboard rollout (owner 2026-08-20): its own surface, top-left, reached
    // only by SUPER+V. Narrower than the launcher because a clipboard entry is
    // one line of text rather than a name plus a description, and taller in
    // rows because scanning history is the whole task — you arrive knowing
    // roughly how far back the thing you want is.
    readonly property int clipboardWidth: 520
    readonly property int clipboardMaxRows: 10
    // Owner live-tune 2026-08-20 ("too large, too big font; search is nice"):
    // clipboard entries are one line of history, not launch candidates — they
    // get a tighter row than the launcher's RATIFIED 57, which stays untouched.
    readonly property int clipboardRowHeight: 40
    // Keybind cheat sheet (decision-table row 9): wider than the clipboard
    // because a row is a key combo PLUS a sentence; single-line rows tighter
    // than the launcher's because there is no icon and no sub-line. The combo
    // column is fixed so the keys form a scannable spine.
    // Colour menu (03 quick actions, owner 2026-08-24): the floor for a menu
    // that normally takes the height of the column it hangs off. A standalone
    // surface size, like launcherWidth and clipboardWidth -- not a rung on the
    // spacing ladder. Only a fallback: the host hands the real span down.
    readonly property int colorMenuMinHeight: 240
    readonly property int cheatSheetWidth: 640
    readonly property int cheatSheetRowHeight: 32
    readonly property int cheatSheetComboWidth: 190

    // >theme carousel card (caelestia WallpaperList 248x200, adapted to our
    // launcherWidth so 2 neighbor cards peek beside the centered one).
    readonly property int launcherThemeCardWidth: 220
    readonly property int launcherThemeCardHeight: 178

    // One outer footprint; tab content owns overflow, never the shell body.
    readonly property int panelWidth: 854
    readonly property int panelHeight: 560
    readonly property int panelNavigationWidth: 620
    // Top panel tab bar (06 RATIFIED: 48px).
    readonly property int panelTabBarHeight: 48
    // 04 RATIFIED: collapsed notification entry is 36px.
    readonly property int notificationCollapsedHeight: 36
    // 08: session action buttons are 96x72.
    readonly property int sessionButtonWidth: 96
    readonly property int sessionButtonHeight: 72

    readonly property int controlHeight: 40
    readonly property int controlHeightSm: 26
    // The tall control: a search field is a place to LOOK, not a button,
    // and it says so by standing taller than the row of controls beside it.
    readonly property int controlHeightLg: 52

    // THE "this one" mark. A launcher result, a device row, a notification
    // in the history and a menu row all answer the same question — which of
    // these is current — and they answer it with the same pill. It was typed
    // as a bare 3 and 18 in every one of them.
    readonly property int markThickness: 3
    readonly property int markHeight: 18
    readonly property int railWidth: 40
    // 01-frame geometry: band 12 everywhere except the 60px left
    // band the rail lives inside; viewport rounding and rollout corners 28
    // (01-frame: 25 was the shell's last off-ladder radius, now gone).
    readonly property int frameThickness: 12
    readonly property int frameRadius: radius2xl
    readonly property int reservedLeft: 60
    readonly property int rolloutRadius: radius2xl
    // 04-notifications rollout width: short notices stay edge-adjacent while
    // expanded bodies wrap below the headline instead of owning the screen.
    readonly property int notificationWidth: 380
    // The bell corner (04, owner 2026-10-17): a 40x32 bulge that retracts
    // when everything is read, the glyph resting on the band's corner; its
    // menu is a top-right modal the height of the clipboard.
    readonly property int notificationBellWidth: 40
    readonly property int notificationBellHeight: 32
    readonly property int notificationMenuHeight: 520
    readonly property int controlWidth: 380
    readonly property int spinBoxWidth: 140
    readonly property int swatchTarget: 44
    readonly property real sliderStep: 0.01
    readonly property int sliderKeyboardUnits: 5
    readonly property int sliderPageUnits: 20
    readonly property int sliderLength: 260
    readonly property int sliderLengthVertical: 180
    // 04-notifications gestures: vertical drag-to-expand distance (caelestia
    // parity B5, additive to hover-expand); horizontal swipe-dismiss fraction
    // of entry width is spec-RATIFIED at 40% (04-notifications "Numbers").
    readonly property int notificationExpandDragPx: 20
    // 04-notifications: separator inset, and the invisible margin that lifts
    // a 14px action label to a 24px hit target (audit X1's hard floor).
    readonly property int notificationDividerInset: 20
    readonly property int notificationActionHitMargin: 5
    readonly property real notificationDismissFraction: 0.4
    // 01-frame melt reach: the one join constant every neck derives from.
    readonly property int meltSmoothing: 20
    // How close a silhouette has to come to the BAND before it prefers to fuse
    // with it rather than leave a sliver. Deliberately wider than the melt
    // reach: at exactly meltSmoothing the shader is only half-bridging, which
    // is what a pinched neck looks like. Measured case that set it — the
    // network rollout stopped 25.5px from the band's inner face and read as a
    // gap (owner 2026-08-19).
    readonly property int edgeSnapReach: 32
    // Handles (05/06, LIVE-TUNE): the OSD circle nub and the top dot pair.
    readonly property real handleRadius: 7
    readonly property real handleProud: 3
    // The dots handle sits mostly INSIDE the band (owner 2026-10-17): a
    // negative proud pulls it up, so only the lower 3px of the bulge shows.
    readonly property real panelHandleProud: -1
    // The OSD nub sinks into the right band the same way (owner 2026-10-17):
    // its centre sits 2px inside the band, so 5px of the circle shows.
    readonly property real osdHandleProud: handleRadius + 2
    readonly property real dotRadius: 1
    readonly property real dotSpacing: 3
    readonly property real dotGlyphSize: 2.5
    readonly property int panelHandleHeight: 8
    // Rail popouts (03).
    readonly property int popoutWidth: 280
    // Bluetooth popout (03, caelestia-parity B4): device rows cap at N,
    // sorted connected-first — matches caelestia's list depth.
    readonly property int popoutDeviceListMax: 5
    // OSD (05, redesigned 2026-08-19 — owner: thicker, per-channel, and the
    // value rides a circle that travels the track).
    //
    // The surface got NARROWER while the track got THICKER. Those are the same
    // complaint from two sides: a 72px surface protruded further than its 14px
    // hairline pills ever justified, so the rollout reached well into the
    // desktop to show three thin grey lines. 40px of track inside a 56px
    // surface spends the protrusion on the control instead of on margin.
    //
    // Material's slider baseline (6dp track, 40dp thumb — thumb 6-7x the
    // track) is for a hairline slider and is exactly wrong here: the thumb has
    // to CONTAIN the reading, so the track has to contain the thumb. This is
    // the fat-track family instead (iOS Control Center, HyperOS's brightness
    // panel), where the value is drawn inside the control rather than beside it.
    // 56, per spec/05-osd.md. It was 48 between 2026-08-22 and 2026-09-07
    // (owner: every rollout sat too far off the screen side), and that held
    // until `Rollout.contentCenterOffsetX` arrived with the library port: a
    // rollout is the band BULGING, so content centres in body plus band and
    // shifts half a band-depth toward the edge. The 40px track then wanted 20
    // to the edge side of a 48px body that has 16, and the last 4px drew under
    // the frame and were clipped. 56 is the width at which the spec's own
    // numbers close: channel 40, track 40, thumb 32 inset 4 each side.
    readonly property int osdWidth: 56
    readonly property int osdTrackWidth: 40
    readonly property int osdTrackHeight: 140
    // Inset 6px each side of the track (05-osd 2026-10-16), carrying the
    // channel glyph at rest and the value while live; no shadow under it.
    readonly property int osdThumbSize: 28
    // Wheel nudge step shared by the OSD pill's own WheelHandler and any
    // other control that drives the same output/brightness path (B3 rail
    // scroll zones) — one step, one source of truth.
    readonly property real osdWheelStep: 0.05
    // ONE rail rhythm (owner 2026-10-17): every item in the band is the same
    // 32px cell with different content, 4px apart, same hover rollout.
    readonly property int railItemGap: 4
    // Rail app list (03 RATIFIED 2026-10-16): icon-only rows, a 32px cell
    // with a 22px glyph, no caption. The title lives in the hover popout.
    readonly property int railAppSlot: 32
    readonly property int railAppIconSize: 22
    // The rail clock (03, back in the rail 2026-10-17): time above a smaller
    // numeric date.
    readonly property int railClockDigitSize: textLg
    readonly property int railClockDateSize: textSm
    // Group separators in the rail (owner 2026-10-16: the dividers stay). A
    // short textMuted line, drawn, because the band is darker than
    // everything it separates.
    readonly property color railDivider: textMuted
    readonly property real railDividerOpacity: 0.8
    readonly property int railDividerThickness: 2
    readonly property real railDividerInset: 8
    // How many connected devices the one BLE cell splits into before it stops
    // subdividing.
    readonly property int railDeviceMax: 4
    // Workspace slots (03, owner 2026-10-16 night): compact 16px slots with a
    // 4px gap and a 6px dot each, because there is nothing to aim at there
    // beyond a wheel and a click; the 20px numbered accent pill is the one
    // moving part and overhangs its slot by 2px each side.
    readonly property int railWorkspaceSlot: 16
    readonly property int railWorkspaceDot: 6
    readonly property int railWorkspacePill: 20
    // StatRing (performance tab default; dashboard resources card overrides
    // both to fit three stacked rings in one card).
    readonly property int ringDiameterDefault: 150
    readonly property int ringStrokeDefault: 8
    // 3/4-ring geometry (memory + storage cards, caelestia-parity): a gap
    // at the bottom instead of a closed circle.
    readonly property real ringQuarterStartAngle: -225
    readonly property real ringQuarterSweepAngle: 270
    // Performance tab (06 RATIFIED, caelestia-parity card grid).
    readonly property int performanceThermalAlertC: 90 // icon/bar flip to danger above this
    readonly property real performanceThermalScaleC: 100 // bar fraction = temp / this
    readonly property int performanceThermalBarHeight: 4
    readonly property int performanceNetworkCardWidth: 390
    // The sparkline's FLOOR; the network card lets it grow into whatever
    // height the row's tallest card sets.
    readonly property int performanceSparklineHeight: 56
    readonly property int performanceBatteryTankWidth: 160
    readonly property int performanceBatteryTankHeight: 220
    // Dashboard tab (06 RATIFIED composition, caelestia-parity card grid).
    readonly property int dashboardUserCardWidth: 320
    readonly property int dashboardWeatherCardWidth: 260
    readonly property int dashboardMediaCardWidth: 200
    // Dashboard cards carry NO per-card radius since 2026-08-22 (owner:
    // "unify into one, on the parent") — Card's own default rules the grid.
    readonly property int dashboardAvatarSize: 56
    readonly property int dashboardBadgeSize: 18
    readonly property int dashboardRingDiameter: 64
    readonly property int dashboardRingStroke: 6
    readonly property int dashboardMediaArtSize: 72
    // Media tab artwork circle. Sized to the panel's COLUMN width: at 220 it
    // owned more than a third of the tab and the title had nowhere to go.
    readonly property int mediaArtSize: 160
    readonly property int mediaContentWidth: 620
    // Shared Slider geometry: the media
    // tab's seek slider (06 RATIFIED transport + seek), the sound popout's
    // volume, the night-light warmth, and the battery popout's read-only
    // charge bar. Named for the control, not for the first surface that
    // needed it -- the battery bar was already borrowing `mediaSeek*`.
    readonly property int sliderTrackThickness: 4
    readonly property int sliderThumbSize: 12
    readonly property int sliderThumbLift: 2
    // How far a silhouette reaches INTO the neighbour it is flush against.
    //
    // Measured 2026-08-25: two rects that merely TOUCH leave the merged SDF at
    // zero along the shared edge, and zero is exactly what "here is the edge"
    // means to the AA (`alpha` dips to ~0.5 -> a translucent hairline). Row
    // scan across the join on HDMI-A-1 showed a spike at x=156..160 where the
    // real outer edge at x~492 showed none: the seam inventing an edge.
    // Overlapping pushes the field negative across the whole join; the
    // shallowest point is the midpoint at overlap/2, which 8 keeps well past
    // the ~1px derivative AA.
    readonly property real seamOverlap: 8
    // The edge separation (01-frame, owner 2026-10-18): a slight line of
    // edgeColor exactly at the silhouette's edge, 0.5 of the colour there,
    // easing into the band colour over 10px. Candidates for the owner to tune.
    readonly property real edgeStrength: 0.5
    readonly property int edgeFade: 10

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
                            name: parsed.name ?? file,
                            wallpaper: parsed.wallpaper ?? "",
                            roles: parsed.roles ?? {}
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
