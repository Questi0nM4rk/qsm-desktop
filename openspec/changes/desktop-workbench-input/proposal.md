## Why

The owner needs the desktop's real rail interactions to work and be reproducible from workbench without borrowing the system mouse. Current flows bypass controls, duplicate dismissal policy, and mix fake services with persistent user state.

## What Changes

- Share the production rail rollout pair and lifecycle between EdgeScene and the provider.
- Route simulated input through real controls, with an explicit live/simulated mode and observable pointer.
- Isolate provider state and offer controlled fullscreen, keyboard ownership, reduced motion and reset.
- Keep a few user-outcome flows for nested travel, night-light adjustment, colour picking and dismissal, including interrupted transitions.
- Preserve existing production styling and user-owned dirty changes. No catalog expansion or redesign in this change.

## Capabilities

### New Capabilities
- `desktop-workbench-input`: faithful, isolated rail integration with real control input.

### Modified Capabilities
None.

## Impact

Desktop bar modules, EdgeScene, workbench adapter/state/services and three rail flows. Requires sibling workbench change `native-flow-input`. No qsm-shell API changes are planned. One local user; no plugin framework, coverage target, pixel assertions or new service architecture.

## Critiques

- Devil's advocate: native hover must reach ScenePointer as well as controls; addressed by one Qt-local input source and retention assertions. Fresh events alone are not causal proof; flows also assert resulting state and settle prior work.
- Future archaeologist: focus starts by real click, keys stay within declared scene scope; transition observations use bounded await, not fake resumable checkpoints. Both contracts are explicit.
- Scope sniper: preflight checks declared target names, execution checks lazy-loaded Items; reset cancels an outstanding press before scene reset. Kept three user flows, no broader automation platform.
