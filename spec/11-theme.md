# 11 — Theme

## Theme system

- **RATIFIED (2026-10-16, owner)**: a theme = a wallpaper; the palette is derived from it by
  rules, never copied from it. Swapped live via the launcher's theme picker (07-launcher).
  N-theme-capable; ships with exactly two — **Deep Night** and **Mountain Dusk**. Adding a
  theme = adding one wallpaper, zero code. Mountain Dusk's values come from its wallpaper by the
  same rules.
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
  L 0.20, band L 0.255.
- **RATIFIED (2026-10-16, owner; one ratio 2026-10-21)**: lightness separates. Containers step up
  a three-step neutral ladder: `band` (rollout fill) -> `surface` (a card, row group) ->
  `overlay` (a popout over a card), each 1.30:1 on the one below. The band is the one colour
  `derive-theme.ts` types; the library's `ladder()` computes the two steps above it from the
  library's `ladder.step`, so the ratio has one owner and no theme types a step. No
  hairline, no 1px card border, no rim, no shadow does that job (a card in a list of cards adds a
  slight shadow under the step, 01-frame); a line in the shell is content
  (slider track, meter), never an edge. A fourth container level is a design error, not a step.
  Frame and every rollout are one silhouette painted as `band`; nothing draws its own frame,
  stroke, rim or shadow.
- **RATIFIED (2026-10-16, owner)**: neutrals carry structure, pastels carry meaning. The ladder
  is near grey with a trace (OKLCH C 0.08) of the wallpaper's hue, tuned for the NOTEBOOK
  display, where a smaller trace reads grey; the external monitor shows it richer. Eight pastels share one
  lightness and one chroma (OKLCH L 0.82, C 0.085): rose 10 deg, peach 50, yellow 90, green 145,
  teal 185, sky 230, lavender 275, mauve 315. A pastel never fills a container.
- **Deep Night, derived** (sRGB hex):
  - palette: see shell/themes/deep-night.json for the generated values (band L 0.255, trace C 0.08) ·
    ink #F0ECF5 (L 0.95) · ink-muted #C3A8DD · edgeColor #681999 · rose #F5AEB7 · peach #F2B493 ·
    yellow #D9C284 · green #A2D3A2 · teal #81D6CB · sky #89CFF1 · lavender #B4C0FC ·
    mauve #D9B4EA
  - roles: band=ground-0 · surface=ground-1 · overlay=ground-2 · text=ink · textMuted=ink-muted ·
    primary=mauve (the one action per surface) · textOnPrimary=ground-0 (the design
    system's on-primary; QML reads on<Capital> as a signal handler and a Behavior on it crashes the
    shell) · accent=mauve (what is
    current) · focus=mauve (2 px ring outside the control, 2 px offset) · info=sky ·
    success=green · warning=yellow · danger=rose. Status hues stay semantic.
  - roles that do not exist: `secondary`, `background`, `backgroundMid`, `backgroundEnd`,
    `bandFill` (band is the fill), `outline`, rim colour/strength/width. The edge separation of the
    silhouette (01-frame, role `edgeColor`) and the rail's divider line (03-rail) stay.
- **Pairs** (WCAG, measured on the shipped 8-bit colour): `derive-theme.ts` recomputes every pair
  and stops on one under its floor, so a theme that ships has them all: the library's text floor
  for every ink and pastel on band, surface and overlay, for `textOnPrimary` on every fill and
  for receded muted text on the band; the ladder step between neighbours. Beyond the generator,
  glyphs, controls and the focus ring keep the non-text floor and adjacent states of one control
  stay distinguishable.
- Scales: the type, spacing, radius, icon and motion scales are the library's (`Style`,
  `Motion`) and are not restated here; this desktop reads them. CaskaydiaCove Nerd Font, Mono cut
  for tabular values. A nested corner is the outer radius minus the inset
  (`Style.childRadius`).
- **RATIFIED**: EVERY radius in the shell is one of the ladder's names.
- Hover is never a tint (09-input-and-states); rounded notification rows are a `surface` on the `band`,
  without borders, with the slight list-card shadow (01-frame). Urgency shows on the app glyph (critical `danger`, normal `info`,
  low `textMuted`), not on a tick bar.
- Swap choreography: **200ms cross-fade** (DEFAULT).
