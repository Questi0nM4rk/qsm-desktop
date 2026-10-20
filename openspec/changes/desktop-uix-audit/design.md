## Context

The library audit and its owner-led repairs live in `../qsm-shell` (`docs/UIX-AUDIT.md`, plan
`openspec/changes/uix-component-audit/`, tracker `qss-9zk`). The desktop's own spec files stay
the authority on how the desktop looks and behaves; this change adds the audit's own records.

## Goals / Non-Goals

**Goals:** one record per desktop surface with measured findings, real input routes, input
geometry and pointer-path mathematics, and an explicit evidence state.

**Non-Goals:** repairing the surfaces, changing the library, restarting production, mutating a
service, injecting desktop input without the owner's go, and the launcher, calendar and wallpaper
defects that have their own tasks.

## Decisions

1. **One record per surface, in this repository.** The desktop's surfaces are composed here, so
   the composition, the role ownership and the compositor contract belong in this repository's
   records, not in the library's. The library's per-type records stay the reference for the
   reusable parts.
2. **Evidence channels first, judgement second.** Every record names the channels it used: the
   isolated Workbench story, the native tree, the session capture, a real window on workspace 10,
   or the accessibility tree. A channel that is unavailable is named, and the claims that depend
   on it are not made.
3. **Pointer mathematics follows the library method.** Input shape apart from painted size,
   representative origins, distance D, the width W along the approach direction, difficulty
   ID = log2(1 + D/W) in bits, landing tolerance, neighbouring interference, and for every
   hover surface the trigger-to-panel corridor and its timing. Origins and weights are model
   assumptions; no human average is claimed.
4. **The off-screen limit is named, not worked around.** `SvgIcon` glyphs do not rasterise
   off-screen, so a glyph-bearing surface photographs empty. That is a pipeline limit, recorded
   in the library's `AGENTS.md`, and the record says "needs a real window" instead of filing a
   false defect. A real window on workspace 10 needs the owner's go.
5. **The existing specs stay current truth.** A finding is a finding until the owner decides.
   When a decision changes the spec, the spec is edited in the same change, citing the owner.

## Risks / Trade-offs

- A second record set can drift from the spec → the coverage row names the spec section it
  audits, and every accepted change edits the spec in place.
- The desktop has a live shell and real services → no restart, no service mutation and no
  injected input without the owner's explicit request, and the agent cleans up only the windows
  it opened.
- Many surfaces multiply the work → the coverage is per surface, not per widget; a surface with
  one widget is one row.
