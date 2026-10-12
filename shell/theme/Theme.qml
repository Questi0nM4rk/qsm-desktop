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

    // [{ id, name, wallpaper, tokens }] parsed from shell/themes/*.json.
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

    // The 11-theme baseline (deep dark) — the fallback for missing tokens.
    readonly property var baseline: ({
        background: "#1C0E27", backgroundMid: "#251733", backgroundEnd: "#2E203E",
        surface: "#21142B", surfaceRaised: "#2D1F3A", surfaceHover: "#382A48",
        text: "#F6F1F9", textMuted: "#B6A8C2", accent: "#C5A5E9",
        secondary: "#E1B7E1", success: "#91D6C2", warning: "#E8C58A",
        danger: "#FF8B94", outline: "#4E3F62", info: "#9FC2EA",
        bandFill: "#15081E", shadow: "#000000"
    })

    function token(name: string): color {
        return currentTheme?.tokens?.[name] ?? baseline[name];
    }

    // Colors are plain bindings over the current theme; each carries a
    // 200ms cross-fade (11 DEFAULT swap choreography).
    property color background: token("background")
    property color backgroundMid: token("backgroundMid")
    property color backgroundEnd: token("backgroundEnd")
    property color surface: token("surface")
    property color surfaceRaised: token("surfaceRaised")
    property color surfaceHover: token("surfaceHover")
    property color text: token("text")
    property color textMuted: token("textMuted")
    property color accent: token("accent")
    property color secondary: token("secondary")
    property color success: token("success")
    property color warning: token("warning")
    property color info: token("info")
    property color danger: token("danger")
    property color outline: token("outline")
    property color shadow: token("shadow")
    // The band's own fill, and the ONE colour drawn from the wallpaper rather
    // than the palette ramp (owner 2026-08-18).
    //
    // It is deliberately LIGHTER than every other surface: the band is the only
    // thing sitting ON the wallpaper, and a surface reads as raised by being
    // lighter than its ground — darker reads as a well cut into the desktop,
    // which is why the old ground-coloured band measured 1.01:1 against the
    // wallpaper and needed a lit rim just to exist.
    //
    // THE RULE (owner-chosen 2026-08-19, after eight rejected candidates):
    // match the wallpaper's darkness, carry the identity in HUE.
    //
    // A band is a FRAME AROUND the content, not a panel floating on it, so it
    // must recede: every candidate lighter than the wallpaper's ground read as
    // stealing focus, however tasteful the hue. Target ΔL within ~2 of the
    // wallpaper's dominant colour (deep-night: #110D11 at L6).
    //
    // What makes it visible instead is saturation: at L~10 a chrome colour
    // needs S≈50% or it collapses into muddy grey (color-depth: raise
    // saturation as lightness leaves 50%). #170D26 is ΔL 1.5 from the
    // wallpaper's ground yet ΔE 16 from it — same darkness, unmistakably a
    // different material. textMuted still reads at 8.6:1 on it.
    //
    // Deriving one for a new theme: take the wallpaper's dominant hue, keep its
    // lightness, push saturation to ~50%, and check textMuted clears 4.5:1.
    property color bandFill: token("bandFill")

    // Theme-swap choreography (11 DEFAULT: 200ms). Lives HERE, not in Motion:
    // Motion already reads Theme.reducedMotion, and a token both singletons
    // need would make that a cycle.
    readonly property int themeSwapDuration: 200

    Behavior on background { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on backgroundMid { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on backgroundEnd { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on surface { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on surfaceRaised { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on surfaceHover { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on text { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on textMuted { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on accent { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on secondary { ColorAnimation { duration: root.themeSwapDuration } }
    // The status four were never in this list. `info` was added this session
    // and would have joined them; a review caught it and the other three came
    // with it. 11-theme requires the 200ms crossfade on EVERY colour, and a
    // theme swap that fades eleven colours and snaps four reads as a glitch in
    // the four rather than as a choice.
    Behavior on success { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on warning { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on danger { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on info { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on outline { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on shadow { ColorAnimation { duration: root.themeSwapDuration } }
    Behavior on bandFill { ColorAnimation { duration: root.themeSwapDuration } }

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
    // Preserve the library defaults while exposing them to the theme contract.
    readonly property real floatingShadowOpacity: currentTheme?.tokens?.floatingShadowOpacity ?? 0.28
    readonly property real floatingShadowBlur: currentTheme?.tokens?.floatingShadowBlur ?? 0.6
    readonly property real floatingShadowOffset: currentTheme?.tokens?.floatingShadowOffset ?? 8
    readonly property int floatingShadowExtent: currentTheme?.tokens?.floatingShadowExtent ?? 24
    readonly property int notificationPreviewHeight: currentTheme?.tokens?.notificationPreviewHeight ?? 80
    readonly property int notificationBodyViewportHeight: currentTheme?.tokens?.notificationBodyViewportHeight ?? 96
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

    // Top panel (06): TWO widths, not five. A card grid needs three columns
    // side by side; a single-column tab (media, history, a workspace row) in
    // that same width is a strip of content against half a panel of empty
    // ground, which is what the old one-size-fits-all 854 produced. The panel
    // morphs between them, so it still reads as one surface resizing.
    readonly property int panelWidthGrid: 854
    readonly property int panelWidthColumn: 620
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
    // 01-frame RATIFIED geometry: band 16 everywhere except the 60px left
    // band the rail lives inside; viewport rounding and rollout corners 28
    // (01-frame: 25 was the shell's last off-ladder radius, now gone).
    readonly property int frameThickness: 16
    readonly property int frameRadius: radius2xl
    readonly property int reservedLeft: 60
    readonly property int rolloutRadius: radius2xl
    // 04-notifications rollout width: short notices stay edge-adjacent while
    // expanded bodies wrap below the headline instead of owning the screen.
    readonly property int notificationWidth: 380
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
    readonly property real dotRadius: 2
    readonly property real dotSpacing: 6
    readonly property real dotGlyphSize: 2.5
    readonly property int panelHandleWidth: 160
    readonly property int panelHandleHeight: 28
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
    // Inset 4px each side of the track, so it reads as sitting IN the channel
    // rather than on top of it.
    readonly property int osdThumbSize: 32
    // Solid drop, no blur: "short, vertically offset, zero blur — lift while
    // staying flat" (color-depth, depth without shadows). Grows while dragging,
    // because a dragged object rises.
    readonly property int osdThumbLift: 2
    readonly property int osdThumbLiftDragging: 4
    // Wheel nudge step shared by the OSD pill's own WheelHandler and any
    // other control that drives the same output/brightness path (B3 rail
    // scroll zones) — one step, one source of truth.
    readonly property real osdWheelStep: 0.05
    // Rail app list (03 DEFAULT): rows share the whole middle area —
    // name space per row floats between these bounds.
    readonly property int railAppIconSize: 26
    // Group separation is a LINE now, not a pill (owner 2026-08-18) — and it
    // is deliberately brighter than `outline`, which measured 1.50:1 against
    // the wallpaper and could not separate anything.
    // Drawn, not incised: the band is darker than everything it separates, so
    // a light hairline reads and a dark one disappears.
    readonly property color railDivider: textMuted
    readonly property real railDividerOpacity: 0.8
    readonly property int railDividerThickness: 2
    readonly property real railDividerInset: 8
    // How many connected devices the one BLE cell splits into before it stops
    // subdividing.
    readonly property int railDeviceMax: 4
    // Rail app-row caption run (the sideways name). The caption IS the
    // feature, so the max stays generous — a lone app gets the long run and
    // shows more of its live title; the min is the point past which the
    // list scrolls instead of shrinking further.
    readonly property int railAppNameMin: 40
    // The floor for a row's caption run: past it the list scrolls instead of
    // shrinking further. There is deliberately no ceiling — rows always divide
    // the whole middle area between them.
    // Workspace widget (03, re-amended 2026-08-17 v2 — owner design): global
    // monitor-synced dots at FIXED positions; the numbered accent pill is
    // the moving part, gliding between dot slots.
    readonly property int railWorkspaceDotSlot: 9
    readonly property int railWorkspaceActiveSlot: 18
    readonly property int railWorkspacePillWidth: 24
    // Clock entry (03, amended 2026-08-17 — caelestia anatomy): stacked
    // hour/minute digits, smaller than the dashboard's textDisplay so the
    // pair fits the 40px rail without widening it.
    readonly property int railClockDigitSize: textMd
    // The date under the digits. At textXxs/muted it was there but unreadable
    // (owner 2026-08-18); 10px at full text colour is the largest that still
    // fits "18 Aug" inside the 40px pill.
    readonly property int railClockDateSize: textSm
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
    readonly property int dashboardUserCardWidth: 340
    readonly property int dashboardWeatherCardWidth: 275
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
    // Shared Slider geometry: the media
    // tab's seek slider (06 RATIFIED transport + seek), the sound popout's
    // volume, the night-light warmth, and the battery popout's read-only
    // charge bar. Named for the control, not for the first surface that
    // needed it -- the battery bar was already borrowing `mediaSeek*`.
    readonly property int sliderTrackThickness: 4
    readonly property int sliderThumbSize: 12
    readonly property int sliderThumbLift: 2
    // 01-frame edge-readability rim: SDF-derived fill ramp toward the
    // silhouette edge. LIVE-TUNE all three.
    readonly property color bandRim: outline
    // 0 = no rim. The band separates by FILL now, not by a lit edge; the
    // shader still supports one, so this is the single switch back.
    readonly property real bandRimStrength: 0
    // Narrow enough that the 16px band keeps a dark core like the bulges —
    // at 12 the rim filled the whole band and it read as a different
    // material than the dark bulge interiors (owner-caught).
    readonly property real bandRimWidth: 6
    // Glass edge on the silhouette: a light hairline drawn on top of the flat
    // fill, hugging the merged shape. The band is very dark, so a low-alpha
    // light line reads as a lit glass edge rather than a border.
    readonly property color bandStroke: text
    // Full strength: the line is meant to read as lit glass, not as a tint of
    // the band under it (owner 2026-08-19).
    readonly property real bandStrokeStrength: 0.55
    readonly property real bandStrokeWidth: 2
    // How far a silhouette reaches INTO the neighbour it is flush against.
    //
    // Measured 2026-08-25, and it is why the ratified three-piece seam law was
    // still drawing a line: two rects that merely TOUCH leave the merged SDF at
    // zero along the shared edge, and zero is exactly what "here is the edge"
    // means to both the AA (`alpha` dips to ~0.5 -> a translucent hairline) and
    // the glass stroke (`innerDepth` ~ 0 -> a full-strength lit line). Row scan
    // across the join on HDMI-A-1: uniform fill #15081E from x=60 to x=490,
    // then a spike at x=156..160 peaking #655B6B either side of a #443E46 dip.
    // The real outer edge at x~492 shows no such spike, so it is the seam
    // inventing an edge, not normal edge treatment.
    //
    // Overlapping pushes the field negative across the whole join. The
    // shallowest point of an overlap is its MIDPOINT, at depth overlap/2, so
    // this must clear the stroke: 4x the stroke width leaves the midpoint at
    // 2x, with room for the ~1px derivative AA on top.
    readonly property real seamOverlap: bandStrokeWidth * 4

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
                            tokens: parsed.tokens ?? {}
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
