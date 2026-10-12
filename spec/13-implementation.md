# 13 — Implementation boundaries

## Current boundaries

- `qsm-desktop` owns the per-monitor scene window, layer-shell integration, exclusive zone,
  fullscreen detection, pinning, and the choice and placement of surfaces.
- `qsm-shell` owns the reusable rollout, shared silhouette mechanism and its normative shader.
  `vendor/qsm-shell/docs/12-mechanism.md` governs the shader formulas; behavior changes start
  there. Attached expansion targets identity deformation and stationary full-size
   content; attached consumer source adoption is recorded in `02-rollouts.md`.
  The desktop adapts the library's input geometry to compositor regions, not another reveal.
- Desktop policy, services, persistence and compositor integration stay in this consumer.

## Working contract

Work on one owner-selected item at a time: think, design, build and prepare it, then report
readiness with its purpose and supported states. The owner tests and reviews it, then directs
revisions to the same item until acceptance. Never self-approve or advance automatically.
Do not run tests, validation, captures, skill evaluations or desktop input unless explicitly
requested. Ask the owner rather than inventing an unresolved product decision.

Design in this order: task, semantic icon and copy consistent with the consequence, supported
states, then spacing, typography, tokens and motion. The visual direction is cosy, minimal
dusk/night, with calm dark bases and diffuse lilac light informed by
`shell/assets/wallpapers/dark-rain-world.png` and
`shell/assets/wallpapers/light-forest-dark-winter.jpg`; do not trace the art or add floating
marketing chrome.

The owner often has a live shell open. Coordinate any requested production restart.
For review, reload the selected preview after QML edits and load the current `.qsb`
after shader edits; do not assume the running instance has picked them up. Shader
artifacts use `vendor/qsm-shell/scripts/build-shaders`; new IPC functions need a
restart. Work on workspace 10 only when asked to operate. Do not drive the pointer
during owner review. After review ends, clean up only windows opened by the agent.

## Interaction contract

The cross-project [Interaction Contract](../../qsm-workbench/docs/interaction-contract.md)
defines the complete path from input to copied evidence. For this consumer:

- Give each semantic component its own kind; a shared description body is not its identity.
  Keep the instance/anchor separate from the type. Rail kinds are listed in `03-rail.md`.
- Trace real control input through intent, confirmation, service result and visible state.
  Report root, child, slot and dynamic-row interactions; opening a rollout alone proves none
  of them. Programmatic calls are not evidence of native keyboard/focus or pointer delivery.
- The provider observes component signals and fake-service outcomes separately. Toolbar
  requests and scenario setup are not successful component actions. Repeated operations may
  need operation signals even when their result value is unchanged.
- Keep preview state isolated. Reset cancels delayed work, native press/hover and event
  bookkeeping without triggering actions or presenting defaults as user interaction.
- Define each event's required and optional fields at the producer/consumer boundary. Omit
  absent optionals instead of coercing them to strings; preserve component and node identity
  across forwarding. A title cannot repair a missing semantic kind.
- Resize typography and its containing geometry together; use reflow when a row no longer
  fits. Keep component size presets, workbench chrome scale and scene zoom distinct.
  Diagnostic text must support selection, copying and scrolling as a user operation.

## Defect-family review

For a discovered defect, trace the complete affected operation and search related producers,
forwarders and consumers for the same broken assumption. Record source paths, concrete user
consequence, confidence and smallest owning correction in the relevant record or backlog.
Do not report a regex match or missing test as a defect without a behavioral path.

For geometry/motion, use the shared
[`develop-component` motion workflow](../../qsm-shell/.claude/skills/develop-component/SKILL.md#motion-and-rendering-changes).
Follow the production surface through the library's registry and renderer, then
the compositor input region and lifetime owner. A correct surface rect is not proof
of a correct shader rect. Use the same production wrapper/handle in the story;
fix a shared defect in `qsm-shell`, not with desktop offsets, easing or delayed unload.
Before changing formulas, reconcile the affected current specs in place instead
of leaving old instructions under a new override. Requested closing evidence
includes the transition and settled tail; a static open scene proves neither.

When the owner requests checks, choose meaningful cases from direct/simulated input,
supported keyboard/wheel/focus routes, narrow/normal/wide layouts, empty/long content,
repeated actions, cancel/reset, and absent/empty/present optional values. A few complete
user outcomes are more useful than a matrix of implementation-shaped assertions.

State source-reviewed, runtime-exercised and owner-accepted separately. Previous passing
flows do not verify subsequent UI or event changes; visual acceptance of one rollout does
not accept its tooling or the rest of the catalog. Read-only audit findings authorize no
automatic fixes, tests or desktop operation.
