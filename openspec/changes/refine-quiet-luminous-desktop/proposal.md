## Why

The owner wants the current desktop to feel deliberately finished while retaining
its useful rail, vertical application captions and menus. The upper panel changes
size with its tab, the resource handle resembles diagnostic text, and surface,
clock and notification treatments do not yet form one readable Quiet Luminous
composition over the owner's wallpapers and applications.

## What Changes

- Give both themes a coherent violet undertone, one derived surface ladder and
  readable foreground pairs. Use restrained static gradients for the resource
  handle, not blanket glow or colored passive status blocks.
- Preserve the 60px left band and 40px rail. Reduce the other frame edges from
  16px to a proposed 12 logical px, with matching rollout origins, input masks and
  exclusion zones. Preserve vertical application labels and window identity.
- Show larger metric-locked HH/mm above a smaller single-line `DD.MM` date.
  Keep day and numeric month side by side and preserve calendar invocation.
- Give all five upper-panel tabs one responsive outer footprint and stable
  navigation. Scroll or adapt content inside it instead of resizing the body.
- Replace the metadata-only CPU/RAM handle with one compact dark capsule button.
  Its full-height half-meters grow away from center beneath one row of stable
  names at the inner side and percentages at the outer side.
- Add quiet rounded notification row surfaces, readable source/time/message
  hierarchy and appropriate padding. Preserve expiry, gestures, expansion,
  current default-action behavior and the named-action route through the center.
- Correct related ownership gaps: local handle suppression, owner/screen-qualified
  Wi-Fi keyboard retention, launcher retirement/secret disposal and aggregate
  detailed-sampling demand. Do not rewrite services or add hardware operations.
- Prepare existing isolated Workbench stories for the changed supported states.

## Capabilities

### New Capabilities

- `desktop-visual-coherence`: Theme, frame, readable numeric-date clock, purposeful resource
  presentation, icon selection and reference-informed notification containment.
- `stable-upper-panel`: Fixed responsive outer size, stable tab navigation and
  bounded overflow for every tab and data-availability state.
- `owned-surface-lifetimes`: Monitor-local suppression, owned keyboard claims,
  retired editor work and shared sampling demand.

### Modified Capabilities

No durable OpenSpec capability specs exist in this repository. The existing
`spec/01`, `03`, `04`, `06`, `07`, `09` and `11` records will be updated in place
for the changed owner decisions.

## Impact

Desktop theme, frame, rail clock, upper panel, resource handle, notification host,
launcher and network prompt wiring change. The sibling qsm-shell library needs
only opt-in notification surface styling propagated by its existing stack, not a
new component, service, shader formula or global workspace policy. Its default
boxless card behavior remains available to other consumers.

The owner authorized batch implementation after this written plan. Work lands
in logical commits on each repository's main branch, without push or archive.
Runtime acceptance remains owner-led. No automatic tests, validation, captures,
desktop input, production restart or hardware writes are authorized by this ask.

Non-goals: light mode, a font or icon-pack replacement, a dashboard rewrite,
decorative media assets, Bluetooth pairing, external Qt/GTK theme parity,
publishing third-party wallpapers, changing notification action policy, or
conditional Rollout host-transfer and unrelated library ownership repairs.

## Critiques

- Devil's advocate: gradients can disguise poor contrast and new row surfaces can
  duplicate chrome. Resolved by one checked ladder, neutral data colors, an opt-in
  card body without borders/shadows and no new rollout paint mechanism.
- Future archaeologist: panel resizing and small dates are intentional in older
  records. Resolved by replacing those decisions in their existing sections before
  implementation, not appending contradictory history.
- Scope sniper: broad polish invites service rewrites. Resolved by preserving
  action routes and restricting lifecycle work to source-confirmed ownership gaps.
  Runtime evidence is a separate open review step, never an implementation claim.
- Validation exception: the generic workflow requests automatic checks, but the
  project forbids them without a separate explicit request. They are not run and
  their absence is recorded; neither the spec nor the epic is closed as verified.
