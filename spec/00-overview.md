# qsm Desktop Spec — Overview

The authority on how this desktop looks, moves, and behaves. Where code and spec disagree,
the spec wins. Current owner decisions are edited in place, not kept as history.

## How to read this spec

- **RATIFIED** — the owner explicitly chose this. Implement exactly; change only by asking
  the owner and editing the spec first.
- **OPEN** — undecided; ask the owner before coding it.
- **LIVE-TUNE** — implemented at the stated baseline, adjusted only with the owner watching.
- **DEFAULT** marks an auditor-derived default the owner may veto; it is implemented
  exactly like RATIFIED until vetoed.
- Numbers are LOGICAL pixels unless stated (fractional monitor scale is handled by the
  shader's derivative AA, never by hand-scaling constants).
- Reference captures are cited by filename only; the images are not distributed (see `spec/references/README.md`).

## Working loop

Work on one item at a time: think, design, build and prepare it, then report readiness with
its purpose and supported states. The owner reviews and directs revisions to that same item
until acceptance. Do not self-approve or move on automatically. The owner tests and judges;
do not run automated tests, validation, captures, skill evaluations or desktop input unless
explicitly asked.

Design from task to consequence: choose semantic iconography and concise copy that match the
consequence, define supported states, then resolve spacing, typography, tokens and motion.
Aim for cosy, minimal dusk/night: calm dark bases and diffuse lilac light informed by
`shell/assets/wallpapers/deep-night.png` and
`shell/assets/wallpapers/mountain-dusk.png`. Take inspiration without tracing the
art or adding floating marketing chrome. Ask the owner when a product decision is unresolved.

## Prime law

**RATIFIED**: EVERY surface this desktop shows is a fluid rollout of the band —
one system, one silhouette language. Nothing floats; nothing is a detached window.

## The picture

One full-screen scene window per monitor draws EVERYTHING at the edges: a frame (band) around
the desktop viewport, a rail of icons living inside the band's left side, and rollouts —
surfaces that bulge out of the band as one continuous shape. One SDF shader paints the whole
silhouette; nothing else may draw frame- or rollout-chrome. Windows (compositor-owned) show
through the transparent viewport.

## Files

| File | Owns |
| --- | --- |
| 01-frame.md | band geometry, edge style, corners, colors |
| 02-rollouts.md | source-silhouette expansion: joining, full-size content, input and lifetime |
| 03-rail.md | left band: entries, pin/collapse/peek, popouts |
| 04-notifications.md | popup rollout + notification center |
| 05-osd.md | volume/brightness/mic bulge + handle |
| 06-top-panel.md | top rollout: dashboard/media/performance/workspaces/notification center |
| 07-launcher.md | launcher + '>' command modes + theme picker |
| 08-session.md | power/session surface |
| 09-input-and-states.md | click-through, focus, fullscreen, multi-monitor |
| 10-motion.md | duration/curve/spring vocabulary |
| 11-theme.md | palettes, typography, radii, spacing |
| 12-mechanism.md | pointer: the normative reference code moved to the library with the shader |
| 13-implementation.md | current implementation boundaries and working rules |
