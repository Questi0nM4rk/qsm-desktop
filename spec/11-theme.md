# 11 — Theme

## Theme system

- **RATIFIED (2026-10-16, owner)**: a theme = a wallpaper; the palette is derived from it by
  rules, never copied from it. Swapped live via the launcher's theme picker (07-launcher).
  N-theme-capable; ships with exactly two — **Deep Night** and **Mountain Dusk**. Adding a
  theme = adding one wallpaper, zero code. Mountain Dusk's values come from its wallpaper by the
  same rules and are not computed yet.
- Theme choice persists across restarts; per-theme wallpaper applies with the palette.
- **RATIFIED (2026-10-16, owner)**: the wallpaper gives three things — polarity (median OKLCH L
  below 0.5 = dark), the hue of the trace on the neutrals (chroma-weighted circular mean hue of
  pixels with C > 0.02; under 10 percent qualifying pixels -> plain grey), and the accent (the
  pastel nearest the most chromatic 30 deg hue bin; grey wallpaper -> lavender). Everything else
  is a rule: change the wallpaper, rerun the rules, touch no component. The light ladder is not
  built yet: a light wallpaper gets the dark ladder with its own trace.
- **RATIFIED (2026-10-16, owner)**: components read roles only (`Theme.accent`), never a palette
  name.

## LIVE-TUNE

- **RATIFIED (2026-10-16, owner)**: the frame is one step LIGHTER than the wallpaper's median
  lightness, never darker (a darker frame reads as a hole). Deep Night: wallpaper median OKLCH
  L 0.20, band L 0.255 (owner tune 2026-10-16 night, up from the brand book's 0.24).
- **RATIFIED (2026-10-16, owner)**: lightness separates. Containers step up a three-step neutral
  ladder: `band` (rollout fill) -> `surface` (a card, row group, 1.45:1 on the band since the
  owner's 2026-10-17 tune, so a card reads as a thing, not a traced rectangle) -> `overlay`
  (1.30:1 on the card). Formerly 1.30:1 per step: `band` -> `surface` (a card, row group,
  field inside a rollout) -> `overlay` (a popout, menu, hover container over a card). No
  hairline, no 1px card border, no rim, no shadow does that job; a line in the shell is content
  (slider track, meter), never an edge. A fourth container level is a design error, not a step.
  Frame and every rollout are one silhouette painted as `band`; nothing draws its own frame,
  stroke, rim or shadow.
- **RATIFIED (2026-10-16, owner)**: neutrals carry structure, pastels carry meaning. The ladder
  is near grey with a trace (OKLCH C 0.035, owner tune 2026-10-16 night, up from the brand
  book's 0.02) of the wallpaper's hue. Eight pastels share one
  lightness and one chroma (OKLCH L 0.82, C 0.085): rose 10 deg, peach 50, yellow 90, green 145,
  teal 185, sky 230, lavender 275, mauve 315. A pastel never fills a container.
- **Deep Night, derived** (sRGB hex):
  - palette: see shell/themes/deep-night.json for the generated values (band L 0.255, trace C 0.035) ·
    ink #F0ECF5 (L 0.95) · ink-muted #B5AEBC (L 0.76) · rose #F5AEB7 · peach #F2B493 ·
    yellow #D9C284 · green #A2D3A2 · teal #81D6CB · sky #89CFF1 · lavender #B4C0FC ·
    mauve #D9B4EA
  - roles: band=ground-0 · surface=ground-1 · overlay=ground-2 · text=ink · textMuted=ink-muted ·
    primary=mauve (the one action per surface) · textOnPrimary=ground-0 (the design
    system's on-primary; QML reads on<Capital> as a signal handler and a Behavior on it crashes the
    shell) · accent=mauve (what is
    current) · focus=mauve (2 px ring outside the control, 2 px offset) · info=sky ·
    success=green · warning=yellow · danger=rose. Status hues stay semantic.
  - roles that do not exist: `secondary`, `background`, `backgroundMid`, `backgroundEnd`,
    `bandFill` (band is the fill), `outline`, rim colour/strength/width. The edge glow of the
    silhouette (01-frame, role `edgeGlow`) and the rail's divider line (03-rail) stay.
- **Pairs** (WCAG, 8-bit): text on band/surface/overlay 14.2/10.9/8.4 · textMuted 7.6/5.9/4.5 ·
  every pastel on band >= 9.1, on surface >= 7.0, on overlay >= 5.4 · textOnPrimary on any pastel
  >= 9.1. Floors: 4.5 text, 3 glyphs/controls/focus ring, 1.3 between ladder steps, 1.2 between
  adjacent states of one control.
- Scales: text **10/12/14/18/22/28/44** (CaskaydiaCove Nerd Font, Mono cut for tabular values) ·
  spacing 2 (tight)/4/8/12/16/24/32 · radii **4/8/12/16/20 (melt)/28 (silhouette)**/pill ·
  icons 12/16/20/26/34/44 · targets 24 min, 32 frequent · motion as 10-motion (press 80, micro
  130, fast 180, normal 260, reveal small 250 / large 500, theme swap 200, reduced <= 120).
  Nested corner = outer radius minus inset (card inset 16 in a 28 corner -> 12).
- **RATIFIED (2026-08-19)**: EVERY radius in the shell is one of the ladder's names. The 8px
  text step is gone: it sat below anything a person reads.
- Hover is never a tint (09-input-and-states); rounded notification rows are a `surface` on the `band`,
  without borders or shadows. Urgency shows on the app glyph (critical `danger`, normal `info`,
  low `textMuted`), not on a tick bar.
- Swap choreography: **200ms cross-fade** (DEFAULT).
