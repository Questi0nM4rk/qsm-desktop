# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Authority chain

1. `spec/` — THE authority on look and behavior. Code loses every disagreement with the spec.
   Start at `spec/00-overview.md`. Ask the owner about OPEN decisions; edit current decisions
   in place, not as history.
2. `AGENTS.md` (imported below) — the working rules for this repo.
3. `shell/` — the implementation. Reuse what matches the current spec and correct what does
   not; availability in code is not owner acceptance.

## Commands

```bash
bash scripts/check               # when requested: lint + type load + theme contract
bash scripts/validate            # when requested: adds the smoke suite + shader drift
scripts/test-quickshell          # IPC smoke suite alone (validate runs it too)
vendor/qsm-shell/scripts/build-shaders   # qsb-compile the LIBRARY's .frag → .qsb (commit both, there)
qs --no-duplicate --path shell   # run the shell (or scripts/qsm-run for the supervisor)
qs kill --path shell             # stop it (smoke suite REFUSES to run beside a live instance; wait ~2s after kill)
qs ipc --path shell call qsm status|toggle|osd|notifyTest|railToggle|themeToggle|...
```

- QML hot-reloads; shader `.qsb` rebuilds and NEW IPC functions require a shell restart.
- The owner is often at the machine with a live shell running — coordinate restarts.
  Screenshots per-screen only: `grim -o <output>`.
- Visual gates are HUMAN judgment against `spec/references/*.png` (captures are from a
  different implementation — pixel-diffing is impossible).
- Shader source and its built `.qsb` stay together in `qsm-shell`; a requested
  `validate` checks their agreement. Do not run a gate merely because a command is listed.

## Architecture (big picture)

Quickshell (0.3.x, Qt 6) desktop shell for Hyprland. Prime law: EVERY surface is a fluid
rollout of one edge band — one silhouette, painted by a single full-screen SDF fragment
shader per monitor. Nothing floats; nothing draws its own chrome.

- **Scene window** (`shell/screen/EdgeScene.qml`): one per monitor. Owns two registries keyed
  by rollout id (reassigned-not-mutated so bindings fire): silhouette rects → shader uniforms
  (8 slots max) and hit rects → input-mask Region slots. Both fed by the SAME live geometry.
  Input mask additionally always holds the band/rail strip and the invisible handle
  hover-zones. The scene is click-through everywhere else.
- **Shader** (`vendor/qsm-shell/qml/QsmShell/shaders/edgemelt.frag`, loaded through the
  `shell/QsmShell` symlink): band + all rollouts merged via circular smin blend, border sink,
  per-corner radii, fwidth AA, fill-only (no strokes anywhere). It lives in the library
  because the melt is ONE silhouette law and a second consumer writing its own would drift.
  `vendor/qsm-shell/docs/12-mechanism.md` is NORMATIVE code — use its exact formulas;
  deviating means editing that file first. Uniforms are NAMED per-slot (`rect0..rect7`, ...)
  because QML arrays bind to GLSL array uniforms as silent zeros on Qt 6.11/Quickshell 0.3.
- **Rollout component**: exactly ONE component implements reveal (`offsetScale` 0=shown
  1=hidden drives position, opacity, silhouette rect, hit rect), the 500ms/250ms motion
  tiers, and goo (velocity-driven squash/stretch spring, deform applied to content transform
  AND shader together). Consumers only provide content. Current `DrawerSurface.qml` is the
  pre-spec ancestor.
- **Surfaces** (`shell/modules/`): rail (left 60px band: workspaces, app list, tray, status
  entries, hover popouts), notifications (top-right rollout + history tab), OSD (right-edge
  sliders + persistent handle), top panel (5 tabs from top band), launcher (bottom-center,
  `>calc >clip >kill >theme`), session (right-edge power column — its blur backdrop is the
  ONE sanctioned second surface besides the scene window).
- **Services** (`shell/services/`): audio (PipeWire), brightness, notifications, fullscreen
  tracking, awake/idle-inhibit. Delegation law: shell is UI only — Hyprlock, Hypridle,
  NetworkManager, BlueZ, PipeWire stay untouched.
- **State/theme**: `shell/state/` (ShellState, OsdState), `shell/theme/` (Theme: the colour
  roles, fonts and this desktop's layout; motion is the library's). Persistence: `~/.local/state/qsm/state.json`. Themes are per-theme JSON + wallpaper
  (N-theme law: adding one = zero code).

Implementation boundaries and the owner-led workflow are in `spec/13-implementation.md`.

## Working style (owner-ratified)

- Caveman answers. Decisions needing explanation: ask in PLAIN TEXT prose — prose in a turn
  ending with AskUserQuestion is invisible to the owner.
- Work one owner-selected item through readiness and owner review; revise that same item until
  the owner accepts it. Never self-approve or move on automatically.
- Do not run tests, validation, captures or other automated checks unless the owner explicitly
  asks. The owner tests and judges.
- Operate on workspace 10 only when asked. Do not drive the pointer during owner review; clean
  up only agent-opened windows after review ends.
- Use `openai/gpt-6-luna` at medium effort for small implementation work and runners, high
  effort for complex research or mechanics. Keep agents narrowly scoped; do not delegate tests
  without an explicit owner request.

@AGENTS.md
