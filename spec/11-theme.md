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
  background #0D1017/#202833 · backgroundMid #121A26/#2B3948 · backgroundEnd #1B2432/#34495A ·
  surface #171B25/#2A3542 · surfaceRaised #222838/#344252 · surfaceHover #2A3244/#405065 ·
  text #EDF1FA/#E6EDF4 · textMuted #A7B0C0/#AEBBC7 · accent #AFC6FF/#A8C7D8 ·
  secondary #C8B6FF/#C1B6D8 · success #91D6C2/#9FCBC3 · warning #E8C58A/#D8B9A5 ·
  danger #FF8B94/#D99098 · outline #394153/#536476. Urgency ticks: critical=danger,
  normal=accent, low=textMuted (DEFAULT).
- BASELINE rim tokens (01-frame edge-readability rim): rim color = outline, strength 0.8,
  width 6px (12 filled the whole 16px band and split it visually from the dark bulge
  interiors) — LIVE-TUNE all three.
- BASELINE scales (AMENDED 2026-08-19 — owner: follow caelestia's graphics, one ladder):
  text **11/12/14/18/22/28/44** · spacing 4/8/12/16/24/32 · radii **4/8/12/16/20/28/32/48**/pill ·
  icons 12/16/20/26/34/44 · band fill = bandFill (see Theme). Font: CaskaydiaCove Nerd Font
  (mono variant for technical values).
- **RATIFIED (2026-08-19)**: EVERY radius in the shell is one of the ladder's names. The old
  10/14/18/26 "scale" plus the ad-hoc 16, 25, 28, 42 and 56 that surfaces reached for is what
  made corners read as assembled rather than designed. The 8px text step is gone with it: it
  sat below anything a person reads.
- **RATIFIED (2026-08-19)**: surfaces are FLAT fills. No outline, no sheen gradient. A card
  inside a panel that already owns a silhouette does not need a second frame, and separation
  is by value — the same way everything else in this shell separates.
- Swap choreography: **200ms cross-fade** (DEFAULT).
