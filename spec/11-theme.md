# 11 — Theme

## Theme system

- **RATIFIED (2026-08-16)**: a theme = palette + wallpaper pair, swapped live via the
  launcher's theme picker (07-launcher). N-theme-capable; ships with exactly two — **deep
  dark** and **mountain dusk** — both restyled toward a creamy/pastel accent language
  (01-frame color law). Adding a theme = adding one definition, zero code.
- Theme choice persists across restarts; per-theme wallpaper applies with the palette.

## LIVE-TUNE

- LIVE-TUNE: restyle accents toward creamy/pastel with the owner watching. BASELINE token
  table (deep dark / mountain dusk) — the spec-inlined starting values:
  background #1B1027/#202332 · surface #2E203C/#2D3141 ·
  text #F6F1FB/#EDEAF7 · textMuted #BCAECA/#B3AEC8 · accent #C7A8EB/#BDAFE5 ·
  bandFill #160D20/#171322. Raised, hover and outline derive from the surface
  by the shared contrast ladder, never separate raw paint paths. Status hues
  remain semantic. Urgency ticks: critical=danger,
  normal=accent, low=textMuted (DEFAULT).
- Rim and glass-edge roles follow the accepted normative shader mechanism and
  Theme's current strengths/widths. Thin framing changes the geometry inputs,
  not those formulas or an independent Rectangle outline.
- BASELINE scales (AMENDED 2026-08-19 — owner: follow caelestia's graphics, one ladder):
  text **10/12/14/18/22/28/44** · spacing 4/8/12/16/24/32 · radii **4/8/12/16/20/28/32/48**/pill ·
  icons 12/16/20/26/34/44 · band fill = bandFill (see Theme). Font: CaskaydiaCove Nerd Font
  (mono variant for technical values).
- **RATIFIED (2026-08-19)**: EVERY radius in the shell is one of the ladder's names. The old
  10/14/18/26 "scale" plus the ad-hoc 16, 25, 28, 42 and 56 that surfaces reached for is what
  made corners read as assembled rather than designed. The 8px text step is gone with it: it
  sat below anything a person reads.
- Surfaces separate by the shared value ladder, without decorative outlines or
  blanket sheen/glow. The resource handle may use a restrained static material
  gradient and neutral level gradient as its named touchup; this does not alter
  the SDF rim mechanism or introduce gradients on every hover/icon/metric.
  Rounded notification rows carry quiet containment without borders or shadows.
- Swap choreography: **200ms cross-fade** (DEFAULT).
