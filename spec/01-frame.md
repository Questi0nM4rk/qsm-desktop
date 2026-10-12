# 01 — Frame

The band around the desktop viewport. One continuous silhouette with every bulge; painted by
the SDF shader only.

## Edge style

- **RATIFIED (2026-08-16, scope clarified 2026-08-17 owner)**: NO drawn lines on the
  SILHOUETTE. The band is fill-only; its edge is the shape itself, anti-aliased
  (screen-space derivative AA, uniform weight on every axis and monitor scale). No outline
  stroke exists on any band/bulge/rollout edge. INNER glass cards (islands, capsules,
  fields — GlassSurface) keep their 1px hairline border: it is part of the ported caelestia
  glass language and visible in the reference captures themselves. Reference: every capture
  in `references/`.
- **RATIFIED (2026-08-17, formula amended same day — owner reported the neck gutter)**:
  edge-readability rim — the fill brightens toward the INNER edges of the silhouette
  (viewport wall and bulge outlines; the outer screen edge stays flat — owner settled on
  inside-only after trying both) as an SDF ramp over **max(melted field, exact union
  distance)**: the exact union alone leaves the melt neck DARK (a barrier gutter between a
  rollout's rim-lit corners and the band — the neck's visible edge only exists in the
  melted field), while the melted field alone deepens overlapped interiors and kills the
  rim there; the max keeps whichever field is shallower, so the rim follows every melt neck
  AND survives absorbed-tail overlaps. It is a fill gradient, NOT a stroke. Per-theme rim
  color + strength + width tokens (11-theme). LIVE-TUNE color/strength/width.

## Join law

- **RATIFIED (2026-08-16)**: melt reach (smoothing radius) = **20px**. The band edge begins
  curving toward an approaching/attached shape 20px out; every join neck derives from this one
  constant. Reference: dashboard top corners in `references/dashboard-tab.png`.

## Geometry

- **RATIFIED (2026-08-16)**: band thickness left **60px** (rail lives inside), top/right/bottom
  **16px**.
- **RATIFIED (2026-08-16)**: bulge/panel corner radius **28px**.
- **RATIFIED (2026-08-16, amended 2026-08-19)**: viewport corner rounding **28px** — 25 was
  the shell's last off-ladder radius; 28 is the same value the rollout corners already use
  (11-theme rounding ladder).

## Color

- **RATIFIED (2026-08-16)**: two palettes only — the existing **deep dark** and **mountain
  dusk** — restyled toward a creamy/pastel accent language (the captures' warmth translated
  into the dark modes; no light mode). Baseline token values are INLINED in 11-theme.md —
  LIVE-TUNE from there; "creamy/pastel" operationally = accents move toward lower chroma /
  higher warmth than the baseline, judged by the owner against the captures' warmth.
- Panel fill = band fill (one silhouette, one fill). Contrast comes from inner cards/controls,
  never from a different bulge base color.
