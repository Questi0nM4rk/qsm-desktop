## Context

One local desktop user needs trustworthy workbench interaction. The current provider uses real BarPopouts but duplicates their lifecycle, skips controls and imports persistent ShellState. The companion workbench change supplies native in-window input.

## Goals / Non-Goals

Goals: one production rollout pair, native input through actual controls, deterministic state, and three useful user-outcome flows. Non-goals: whole-desktop migration, new services, visual redesign, OS cursor automation, pixel or coverage assertions.

## Decisions

- Extract `RailPopoutStack.qml` under `shell/modules/bar/`: it owns both controllers, both BarPopouts, child retirement and dismissal. Inputs are `host`, `hostBandArea`, `keyboardRetained`, `suppressed`; expose controllers, rollout items, destination rectangles and kind/held facts. EdgeScene and Adapter instantiate this same component. EdgeScene retains compositor masks, rail-peek and its production rail; preserve IPC/property names by forwarding aliases.
- Provider uses production `RailEntry` and `QuickActionsColumn` via the shared stack. Add a small named-target door through BarPopouts/content where necessary to access actual interactive Items. These targets expose input surfaces, never reimplement their actions. Control requests that cannot reach a target return false.
- Adapter accepts optional `inputDriver` from workbench. `integration.targets` maps stable kebab names to zero-argument functions returning actual Items: rail-actions, awake, night-light, warmth, colours, pick-colour, parent-body, child-body, outside. Resolve loaded content dynamically; no arbitrary object-path execution.
- Pointer controls and user actions invoke that driver through these real targets. Surface controls are deliberate scenario setup and clearly separate from input. Remove `interactive` as the pointer source switch; both manual and simulated paths use real Qt input and the production ScenePointer. Simulated input selection is explicit in the harness.
- Replace the workbench state symlink with a small in-memory ShellState containing only state actually consumed by the current production story/theme. Do not port persistence, compositor or services. Reset state, service timers, and stack before each scenario. Theme stays production; backend values remain isolated.
- Expose fullscreen/focus suppression, reduced motion and keyboard retention as scenario controls. Read actual stack/controls for observables, and emit parent/child-qualified event payloads. Provide read-only opening/closing observables through the harness's bounded `await`, not arm/resume checkpoints. Interruption scenarios use ordinary motion, observe immediately before polling, and keep input within the production transition; reduced motion is checked separately for final state.
- Three flows: nested travel plus exit/re-entry/dismissal; toggle/adjust night light through real input; colour pick busy/result through real UI and reset/suppression/keyboard retention. Bounded waits observe facts, never assert CSS-like measurements.

## Risks / Trade-offs

- Offscreen Qt does not prove Wayland input regions or window activation → report native in-process integration separately; owner judges live rendering.
- Extraction touches dirty code → seed workers with current changes, integrate only their delta, preserve unrelated edits and all existing worktrees.
- Native tests can expose real production wiring defects → fix within the current rail slice; record any larger scope deviation.

## Verification and execution

Use granular workers with disjoint ownership; automatic implementation/flow checks followed by one owner review of the rail item (strategy B). User authorizes this change's integration/regression checks, not production restart or OS input. No TDD/coverage mandate; use minimal meaningful regressions. Worker contract CLI is unavailable in this installation; workers return explicit completed/blocked reports with changed paths and evidence, reviewed by the orchestrator. No Sentrux baseline exists, so skip rather than create one.
