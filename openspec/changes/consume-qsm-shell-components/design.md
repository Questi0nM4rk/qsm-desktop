## Context

qsm-desktop currently resolves local components from `shell/components`, while
qsm-shell publishes equivalent or generalized components through
`qs.QsmShell.Components` and `qs.QsmShell.Style`. The desktop is live,
multi-monitor, supervised, and already has unrelated uncommitted work, so the
migration must remain additive and reversible at every step.

## Goals / Non-Goals

**Goals:**

- Make qsm-shell importable without changing desktop services or composition.
- Inventory consumers and classify desktop-only dependencies before migration.
- Migrate dependency-ordered component cohorts with automated and live parity
  evidence.
- Preserve a tested rollback to local components until each cohort is accepted.
- Pin the library revision before a release or deployment uses it.

**Non-Goals:**

- Redesigning qsm UI or changing interaction contracts during migration.
- Moving Hyprland, notification, audio, network, persistence, focus, or scene
  ownership into qsm-shell.
- Deleting all local components in one pass.
- Treating the React gallery as desktop runtime.

## Decisions

### Import through one desktop-owned library root

The desktop SHALL expose qsm-shell through one path under `vendor/qsm-shell` and
one `shell/QsmShell` projection into Quickshell's config-root namespace. During
development, `vendor/qsm-shell` may be a symlink to the sibling checkout. Before
release it MUST become a pinned submodule or equivalent pinned checkout.

Quickshell 0.3.1 maps the leading `qs` segment in
`import qs.QsmShell.Components` directly to the config root, so it resolves the
module at `shell/QsmShell/Components`. Plain Qt 6 tools do not apply that
Quickshell mapping; lint and the isolated fixture SHALL instead include
`vendor/qsm-shell/qml` as an import root and use qsm-shell's own portable
`qml/qs/QsmShell` projection. This split was measured after
`shell/qs/QsmShell` passed the plain Qt fixture but real `qs --path shell`
startup failed with `module "qs.QsmShell.Style" is not installed`.

This is preferred to per-component or per-tool symlinks because one runtime
library identity is auditable and atomically replaceable. Copying qsm-shell
back into the desktop is rejected because it recreates the duplication this
change removes.

### Inventory before import changes

The first implementation artifact maps every local component to all consumers,
the matching public library API, and any desktop-only state/service/scene
dependency. Components without a complete mapping do not enter a migration
cohort.

### Migrate in dependency order

Cohorts proceed from leaf presentation primitives, through interaction and list
controls, to scene-bound components. Each cohort changes imports for a small
set, runs qsm-shell validation and qsm-desktop validation/smoke, captures the
matching gallery/QML evidence, and receives owner acceptance before the next
cohort starts.

The initial candidate order is:

1. Leaf presentation: icons, cards, labels, dividers, empty/readout elements.
2. Interaction primitives: state layer, icon button, capsule, and level bar.
   App icon remains local until desktop-entry resolution has an explicit
   consumer adapter.
3. Lists and controls: popout/search/result/calendar/action/session/tab/stat/OSD/notification elements.
4. Scene-bound hosts: Rollout and ModalHost after their backend adapters are proven.

The inventory may remove a component from a cohort but MUST NOT silently move a
scene/service-bound component earlier.

### Desktop adapters stay at the consumer boundary

Application icon lookup, `ShellState`, services, persistence, focused-monitor
selection, and scene registries remain desktop-owned. The desktop passes plain
properties, callbacks, resolved assets, style backend data, and rollout-scene
capabilities into library components.

### Rollback is an import reversal

Each cohort retains local source and a documented import-reversal patch until
live acceptance. A failed smoke or visual comparison restores local imports;
the migration does not tune around regressions while both implementations are
mixed.

## Risks / Trade-offs

- [Sibling symlink is not reproducible] -> Record the resolved revision and
  require a pinned source before release.
- [Two component implementations drift during migration] -> Keep cohorts short,
  prohibit redesign, and complete or roll back each cohort before starting the
  next.
- [Public API is more generic than the desktop copy] -> Add a desktop adapter at
  the consumer boundary; do not reintroduce desktop singleton imports into the
  library.
- [Qt and Quickshell resolve `qs.*` differently] -> Keep the sole desktop
  projection at `shell/QsmShell`; point plain Qt tools at the vendor QML root.
- [Hot reload observes a half-migrated import graph] -> Apply one cohort in one
  coherent edit and verify in an isolated shell before live reload.
- [Scene registration regresses] -> Migrate Rollout/ModalHost last with focused
  registration and cleanup smoke coverage.

## Migration Plan

1. Add the development library root and Quickshell-native projection; prove it
   with both the plain Qt fixture and real `qs --path shell` startup.
2. Produce the component/consumer/backend inventory and lock cohort membership.
3. Migrate one cohort, run static and isolated smoke gates, compare visuals, and
   obtain owner acceptance.
4. Repeat for accepted cohorts; roll back any failed cohort immediately.
5. Replace the development symlink with a pinned revision.
6. Delete a local component only when no local consumer remains and the import
   reversal has been retained in history.

## Open Questions

- Which commit should become the first pinned qsm-shell revision? The library
  repository currently needs its initial commit before this can be answered.
- Should the first apply stop after the leaf cohort for owner review, or include
  interaction primitives when the leaf smoke is clean?
