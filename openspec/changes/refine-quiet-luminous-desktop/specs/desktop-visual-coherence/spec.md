## ADDED Requirements

### Requirement: Shared violet surface hierarchy
Both desktop themes SHALL use one coherent violet surface ladder for desktop
and library controls. Raised, hover and outline SHALL derive from the base.
Static gradients SHALL remain limited to the named resource-handle material
and level cue, with primary/focus/danger roles remaining distinct.

#### Scenario: Theme changes across control hosts
- **WHEN** the owner switches between the supported themes
- **THEN** equivalent desktop and library roles use the same ladder and readable
  text, while passive readings do not become selected-looking accent blocks

### Requirement: Thinner frame preserves the left rail
The desktop SHALL retain the 60px left band, 40px rail and vertical app captions.
The other frame edges SHALL use the chosen 12 logical px baseline. Paint,
rollout attachment, input masks, hover corridors and tiling exclusions MUST agree.

#### Scenario: Rail pin and rollout opening after the frame change
- **WHEN** the owner opens a rollout or peeks the collapsed rail
- **THEN** its body joins the current frame and its usable region matches the
  visible geometry without a stale reservation or click-through seam

### Requirement: Time above a readable numeric date
The clock SHALL show larger HH above mm with a smaller single-line `DD.MM`
underneath. Day and numeric month SHALL sit side by side. Time digit widths and
weights SHALL remain stable. Calendar invocation MUST remain.

#### Scenario: Date or time changes
- **WHEN** the date or time changes
- **THEN** its value updates without shrinking the date or moving the column,
  and reduced motion avoids a positional digit transition

### Requirement: One resource handle with two mirrored levels
The CPU/RAM handle SHALL be one compact dark capsule panel action with a 160x28
logical px footprint. Full-height inner half-meter fills SHALL grow away from
the center. Names SHALL remain fixed at the inner side and percentages at the
outer side, readable on one row at all levels. Missing samples SHALL remain
unavailable rather than zero. Its body SHALL follow the panel rim.

#### Scenario: Missing and boundary samples
- **WHEN** CPU or RAM changes between unavailable, zero and full usage
- **THEN** its value/fill is truthful, neither name nor percentage collides or
  elides, and the handle keeps the same footprint without a false minimum fill

#### Scenario: Handle activation and suppression
- **WHEN** the owner activates the handle or its workspace enters fullscreen
- **THEN** the shared panel action runs, or paint/input/sampling withdraws under
  suppression, without changing an unrelated monitor's presentation

### Requirement: Rounded popup rows preserve notification consequences
Desktop popup notifications SHALL opt into quiet rounded row surfaces and
readable icon/source/time/message hierarchy. Expiry, hover pause, expansion,
current-default activation, named-action routing and dismissal MUST remain intact.
The generic library card SHALL retain a transparent default for other consumers.

#### Scenario: Replacement, retirement and fullscreen presentation
- **WHEN** a popup is replaced, dismissed, expires or changes presentation host
- **THEN** row identity and retained paint remain coherent, the rounded body
  contains its text, and retiring rows have no input or stale fullscreen holes
