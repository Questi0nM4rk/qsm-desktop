## Why

The owner ordered a strict UIX review of every surface, with the reusable library first and the
desktop after it, and full redesign allowed including the shared silhouette. The desktop is where
the surfaces are composed, so a desktop pass over the old project rules would produce findings
the owner has already overruled.

## What Changes

- Every desktop surface gets a record: purpose, states, controls, real input routes, input
  geometry with hitbox and pointer-path mathematics, motion, and measured visual, UX and
  accessibility findings.
- The desktop's own surfaces are covered: frame and rail, top panel and its tabs, notification
  popup and notification centre, OSD channels and their handle, launcher, session column, and
  every popout and hover surface.
- Open findings are linked from `docs/BACKLOG.md`; the repair order is chosen with the owner.
- Repairs happen one surface at a time with owner acceptance, each in its own scoped change.
- The library half stays in `../qsm-shell` and blocks this work.

## Capabilities

### New Capabilities

- `desktop-uix-audit`: the desktop's own per-surface design, input and evidence contracts.

### Modified Capabilities

None. The existing desktop specs stay the authority on current truth; this change adds the
audit's own record set and does not restate them.

## Impact

`docs/BACKLOG.md`, `AGENTS.md`, the new audit records, and the tracker. No production service,
compositor integration, mask, theme or token changes in this change. No production restart, no
service mutation and no desktop input without the owner's explicit go.

## Critiques

- Devil's advocate: the desktop's own spec is already the authority, so a second record set can
  drift from it. Resolved by recording the audit's findings and proposed changes, and by editing
  the existing specs in place when the owner decides, in the same move.
- Future archaeologist: a reader cannot tell which surfaces were audited and which were not.
  Resolved by one coverage row per surface, naming the state, the evidence and the gaps.
- Scope sniper: the audit could absorb the launcher, calendar and wallpaper defects. Resolved by
  naming them out of this change; they keep their own tasks.
