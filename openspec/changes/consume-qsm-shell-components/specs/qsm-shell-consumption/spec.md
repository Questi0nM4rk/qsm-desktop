## ADDED Requirements

### Requirement: Desktop resolves a controlled qsm-shell revision
qsm-desktop SHALL load qsm-shell through one documented library root. A
development symlink MAY target the sibling checkout, but release and deployment
use MUST resolve a recorded pinned revision.

#### Scenario: Developer connects the sibling library
- **WHEN** the development library root points at the sibling qsm-shell checkout
- **THEN** a plain Qt desktop import fixture MUST instantiate a documented
  `qs.QsmShell.*` component through the vendor QML import root

#### Scenario: Quickshell loads the shared module
- **WHEN** the desktop starts through `qs --path shell`
- **THEN** `qs.QsmShell.*` MUST resolve through the single
  `shell/QsmShell` config-root projection and the shell MUST reach its IPC-ready
  state

#### Scenario: Release source is prepared
- **WHEN** qsm-desktop is prepared for release or deployment
- **THEN** the qsm-shell source MUST resolve to a recorded immutable revision
  rather than an ambient sibling working tree

### Requirement: Component migration is inventoried and incremental
Every migrated component SHALL have a recorded local consumer inventory,
matching public API, desktop-owned dependency classification, and dependency-
ordered cohort. A cohort MUST be accepted or rolled back before the next cohort
starts.

#### Scenario: Component enters a cohort
- **WHEN** a local component is selected for migration
- **THEN** every consumer and desktop-only dependency MUST be recorded before
  its imports change

#### Scenario: Cohort fails verification
- **WHEN** static validation, smoke, visual comparison, or owner acceptance fails
- **THEN** the cohort MUST restore local imports without changing unrelated
  components

### Requirement: Desktop policy remains consumer-owned
qsm-desktop SHALL retain ownership of services, persistence, per-monitor and
focused-monitor policy, application-icon resolution, and scene registration.
Library components MUST receive those capabilities through documented
properties, callbacks, resolved assets, style data, or scene backends.

#### Scenario: Stateful component is migrated
- **WHEN** a component currently reads desktop singleton or service data
- **THEN** the desktop MUST adapt that data at the consumer boundary instead of
  adding the desktop dependency to qsm-shell

### Requirement: Local deletion follows complete migration
A local component file SHALL remain until all consumers use qsm-shell, desktop
smoke and visual evidence are accepted, and import rollback has been proven.

#### Scenario: Last local consumer migrates
- **WHEN** no consumer imports the local component and all acceptance gates pass
- **THEN** the local file MAY be deleted in a separate cleanup step with the
  pinned library revision recorded
