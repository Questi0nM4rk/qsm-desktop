# 01 — Frame

The band around the desktop viewport. One continuous silhouette with every bulge; painted by
the SDF shader only.

## Edge style

- **RATIFIED (2026-08-16, scope clarified 2026-08-17 owner)**: NO drawn lines on the
  SILHOUETTE. The band is fill-only; its edge is the shape itself, anti-aliased
  (screen-space derivative AA, uniform weight on every axis and monitor scale). No outline
  stroke exists on any band/bulge/rollout edge, and no rim, gradient or shadow stands in
  for one. Reference: every capture in `references/`.
- **RATIFIED (2026-10-16, owner)**: inner containers (cards, row groups, fields, popouts)
  carry NO hairline, NO 1px border, NO edge rim, NO shadow. Lightness separates them: one
  three-step neutral ladder, `band` → `surface` → `overlay`, each step 1.30:1 on the one
  below (11-theme). A line in the shell is content (slider track, meter), never an edge.

## Join law

- **RATIFIED (2026-08-16)**: melt reach (smoothing radius) = **20px**. The band edge begins
  curving toward an approaching/attached shape 20px out; every join neck derives from this one
  constant. Reference: dashboard top corners in `references/dashboard-tab.png`.

## Geometry

- Band thickness left **60px** (the rail), top/right/bottom **12px**. The band runs on all
  four edges. Thin-frame paint, rollout origins/insets, masks, hover corridors and
  compositor exclusions share these values.
- **RATIFIED (2026-10-16, owner)**: the wallpaper sits in the frame like a rounded picture
  in a mat: the band is the mat, the 28px viewport corners are the picture's corners.
- **RATIFIED (2026-08-16)**: bulge/panel corner radius **28px**.
- **RATIFIED (2026-08-16, amended 2026-08-19)**: viewport corner rounding **28px** — 25 was
  the shell's last off-ladder radius; 28 is the same value the rollout corners already use
  (11-theme rounding ladder).

## Color

- **RATIFIED (2026-10-16, owner)**: the palette is derived from the wallpaper by rules, not
  copied from it. Neutrals carry structure: a near-grey ladder (OKLCH chroma 0.02) with a
  trace of the wallpaper's hue. Pastels carry meaning: eight at one lightness and one
  chroma (OKLCH L 0.82, C 0.085) — rose 10°, peach 50, yellow 90, green 145, teal 185,
  sky 230, lavender 275, mauve 315. A pastel never fills a container. The wallpaper gives
  polarity (median L below 0.5 = dark), the hue of the neutral trace, and which pastel is
  the accent; everything else is a rule. Change the wallpaper, rerun the rules, touch no
  component. A light wallpaper gets the dark ladder with its own trace until a light
  ladder exists. Token values and derivation: 11-theme.
- **RATIFIED (2026-10-16, owner)**: the frame is one step LIGHTER than the wallpaper's
  median lightness, never darker — a darker frame reads as a hole. Deep Night: wallpaper
  median OKLCH L 0.20, band L 0.24.
- Panel fill = band fill (one silhouette, one fill, the role `band`). Contrast comes from
  inner containers stepping up the ladder, never from a different bulge base color.
