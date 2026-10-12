## 1. Library Connection

- [x] 1.1 Record the qsm-shell source path, validation result, and current Git revision or explicitly mark the development source as uncommitted. Evidence (2026-09-04): source `../qsm-shell`; repository is uncommitted (`No commits yet on master`); `npm test` passed with exit 0 (token generation, QML lint, Qt 6 offscreen smoke, gallery build, and gallery lint).
- [x] 1.2 Keep the development `vendor/qsm-shell` link and replace the invalid `shell/qs/QsmShell` projection with the measured Quickshell-native `shell/QsmShell` projection. Evidence (2026-09-04): repaired `shell/QsmShell` runtime projection passed the complete rolled-back baseline validation.
- [x] 1.3 Point plain Qt lint/fixture commands at `vendor/qsm-shell/qml`, then prove the import through both the isolated fixture and real Quickshell startup. Evidence (2026-09-04): vendor-root Qt fixture, real IPC startup, and complete rolled-back baseline validation passed.

## 2. Consumer Inventory

- [x] 2.1 Inventory every `shell/components` file and all direct/indirect consumers. Evidence: `inventory.md` records the filesystem-verified 15-entry set and cited consumers.
- [x] 2.2 Map each local component to its qsm-shell API and classify style, asset, state, service, monitor, and scene dependencies. Evidence: `inventory.md` contains the per-entry API/mismatch/dependency table and the complete 22-type public comparison.
- [x] 2.3 Lock dependency-ordered migration cohorts; exclude any component whose consumer or backend mapping is incomplete. Evidence: `inventory.md` locks five ordered cohorts and explicitly defers incompatible, scene-bound, and shared-only types.

## 3. Leaf Presentation Cohort

- [x] 3.1 Reapply the approved Card (17 direct instantiations, including Capsule composition) and SectionLabel (7 direct instantiations) migration. Evidence (2026-09-04): exact cohort reapplied after baseline repair with explicit shared-component aliases; local definitions remain for rollback.
- [x] 3.2 Run qsm-shell validation, qsm-desktop validation, isolated smoke, and matching gallery/QML comparison for the leaf cohort. Evidence (2026-09-04): qsm-shell `npm test` passed; the migrated desktop's complete `scripts/validate` passed; native Card and SectionLabel captures succeeded; gallery reference drift was corrected and its build/lint passed.
- [x] 3.3 Obtain owner live acceptance and prove the cohort can roll back by restoring local imports. Evidence (2026-09-04): local imports were restored, the complete desktop validation passed, and the same cohort was then reapplied; owner reviewed the live Dashboard/Performance cards and Sound section labels and confirmed they look unchanged.

## 3A. Icon Leaf Cohort

- [x] 3.4 Migrate every local SvgIcon consumer to the aliased public qsm-shell type while retaining the local source; preserve consumer-owned name, size, color, service, and model bindings. Evidence (2026-09-04): 42 direct instantiations migrated in four static-only Luna slices; exact searches show zero local uses, qmllint has no new findings, and the local source remains unchanged.
- [x] 3.5 Run qsm-shell validation, qsm-desktop validation, isolated icon smoke/captures, and gallery/QML comparison for the icon cohort. Evidence (2026-09-04): the complete desktop validation passed all 42 shared uses with no icon runtime errors; native selected-icon capture succeeded; the gallery reference was aligned to the native 44px scenario and its build/lint passed.
- [x] 3.6 Obtain owner live acceptance across representative rail, panel, popout, notification, OSD, and session icons, then prove local-import rollback. Evidence (2026-09-04): owner accepted the live representative icons as crisp, correctly sized/colored, and unchanged; the complete all-local icon baseline passed immediately before the import-only migration, and the unchanged local implementation remains available for exact import reversal.

## 4. Interaction Primitive Cohort

- [x] 4.1 Migrate the approved StateLayer, IconButton, Capsule, and LevelBar consumers with desktop-owned style data and callbacks. Keep AppIcon local until its desktop-entry resolution adapter is specified. Evidence (2026-09-04): 50 direct uses migrated in static-only Luna slices (15 StateLayer, 11 IconButton, 21 Capsule, 3 LevelBar), zero local uses remain, and shared Style now consumes the desktop's compact-control, level, disabled-opacity, and technical-font values.
- [ ] 4.2 Run keyboard, pointer, value-adjustment, isolated smoke, and visual comparison coverage for the interaction cohort.
- [ ] 4.3 Obtain owner live acceptance and prove local-import rollback for the interaction cohort.

## 5. Lists and Controls Cohort

- [ ] 5.1 Migrate approved popout, search, result, calendar, action, session, tab, stat, OSD, and notification consumers whose inventory is complete.
- [ ] 5.2 Run focused interaction contracts, isolated smoke, and gallery/QML visual comparison for each migrated control family.
- [ ] 5.3 Obtain owner live acceptance and roll back any family with behavior or visual drift.

## 6. Scene-Bound Cohort

- [ ] 6.1 Implement desktop-owned adapters for the documented rollout-scene and modal catch-region contracts.
- [ ] 6.2 Migrate Rollout and ModalHost consumers only after registration, identity replacement, target loss, fullscreen, and cleanup smoke coverage passes.
- [ ] 6.3 Obtain owner live acceptance and prove scene-bound rollback leaves no stale input or silhouette registrations.

## 7. Pinning and Cleanup

- [ ] 7.1 Replace the development library link with a recorded pinned qsm-shell revision before release or deployment.
- [ ] 7.2 Delete a local component only when the inventory reports zero local consumers and all cohort acceptance evidence is green.
- [ ] 7.3 Run the complete desktop validation and acceptance walkthrough, then document the final pin and remaining intentionally local components.
