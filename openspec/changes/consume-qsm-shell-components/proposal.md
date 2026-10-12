## Why

`qsm-shell` now publishes and verifies the reusable QML primitives that still
exist as local copies in qsm-desktop. The desktop needs an incremental consumer
path that removes duplication without risking the running shell or making a
library rollback difficult.

## What Changes

- Add qsm-shell to the desktop through a development symlink and one
  Quickshell-native config-root projection first, with a pinned Git revision
  required before release or deployment.
- Inventory every local component, consumer, and desktop-only dependency before
  changing imports.
- Migrate one low-coupling primitive cohort at a time to
  `qs.QsmShell.Components` and `qs.QsmShell.Style`.
- Require library validation, desktop static validation, isolated smoke,
  gallery/QML comparison, and live owner acceptance for each cohort.
- Keep each local component until every consumer has migrated and rollback to
  the local implementation has been demonstrated.
- Preserve desktop-owned services, persistence, per-monitor composition,
  application-icon resolution, and rollout scene backends.

## Capabilities

### New Capabilities

- `qsm-shell-consumption`: Connects a pinned or development qsm-shell checkout
  to qsm-desktop and governs incremental component migration and rollback.

### Modified Capabilities

None. qsm-desktop has no durable component-consumption capability yet.

## Impact

- QML import resolution differs by engine: Quickshell resolves the leading
  `qs` namespace at the config root, while plain Qt tools use the vendored QML
  import root. Component imports, preview/smoke scripts, and the desktop's
  local `shell/components` tree are affected.
- Development setup gains a sibling-library path; release setup must use a
  pinned revision rather than an ambient sibling checkout.
- No desktop service or visual behavior is intentionally changed by the
  migration itself.

## Critiques

### Devil's Advocate

- **A symlink can make builds depend on an uncommitted sibling tree.** Addressed:
  symlinks are development-only; the first task records the qsm-shell revision,
  and release/deployment requires a pinned Git revision.
- **Shared primitives can hide desktop-specific assumptions.** Addressed: the
  inventory classifies each dependency before migration, and service/state/scene
  ownership remains behind explicit consumer contracts.

### Future Archaeologist

- **Deleting local files destroys the easiest rollback.** Addressed: deletion is
  a separate final task after all consumers, smoke evidence, visual evidence,
  and a tested import rollback exist.
- **A broad import rewrite would obscure which component regressed.** Addressed:
  cohorts are dependency ordered and independently accepted.

### Scope Sniper

- **Migrating all 23 components is too large for one implementation step.**
  Addressed: the change establishes the connection and migrates small cohorts;
  stateful or scene-bound components may remain local until their backend
  contract is proven.
- **Redesigning components during migration would mix concerns.** Addressed:
  visual or behavioral redesign is explicitly out of scope; parity failures
  roll back the cohort instead of being tuned inside this change.
