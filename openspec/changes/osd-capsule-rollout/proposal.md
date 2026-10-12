## Why

The desktop OSD must use the current shell controls without changing its compact
side layout. Fullscreen applications need a genuine floating DataCapsule instead
of a detached Rollout, while normal applications retain the attached Rollout.

## What Changes

- Replace the OSD's fullscreen detached-Rollout path with real DataCapsule.
- Keep one persistent channel composition using current shell Sliders and real
  audio/microphone/brightness services, with the existing desktop footprint.
- Keep one desktop-owned visibility/expiry state through presentation switches.
- Unify OSD and rail small-surface reveal/retract through the shared Rollout:
  retain opaque outgoing rail content and geometry until retract completes, rather
  than fading and unloading the content before the shared body has closed.
- Add a desktop OSD story using the production surface and isolated fake services;
  the Workbench fullscreen preview context selects capsule versus rollout.
- Share the production OSD handle bulge and arrow with that story; its existing
  trigger corridor remains surface-owned, and fullscreen has no idle handle.
- Fix reusable component gaps in qsm-shell, with matching shell docs/specs, only
  when a concrete production integration path demonstrates that they are needed.

## Capabilities

### New Capabilities
- `desktop-osd-presentation`: compact real-service OSD with shared content and
  lifecycle in attached and fullscreen presentations, plus desktop proof story.

### Modified Capabilities
None; the durable desktop OSD contract is currently `spec/05-osd.md` rather than
an OpenSpec capability. Update that contract in place with the implementation.

## Impact

Desktop OSD channel/surface/state, scene input-region integration, Workbench
adapter/story and fake services. The library remains reusable: compositor policy
and service calls stay in desktop. Existing rail story and unrelated dirty work
must be preserved. No new provider, notification migration, persistence redesign,
production restart or automated checks are included without owner authorization.

## Critiques

- Devil's advocate: two wrappers can accidentally duplicate sliders, expiry and
  input regions. Addressed by one persistent channel object, one OsdState timer,
  mode-exclusive hit regions, and no shader registration for DataCapsule's body.
- Future archaeologist: simulation could be confused with actual window F11 or
  global fullscreen. Addressed by explicit per-screen production state and a
  readonly injected preview context; story reports presentation separately.
- Scope sniper: rebuilding services or porting all surfaces would overreach.
  Addressed by OSD-only tasks and isolated preview services; library changes are
  a separate bounded correction with docs/specs, not speculative cleanup.
