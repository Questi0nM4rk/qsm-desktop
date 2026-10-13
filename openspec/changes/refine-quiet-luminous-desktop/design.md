## Context

This is a coordinated touchup of the owner's existing two-monitor desktop, not
a new shell. The owner supplied empty/application screenshots and Caelestia
references, retained vertical application captions and menus, and authorized
batch implementation after the plan. Image attachments are visible in chat but
their original file paths are unavailable, so no pixel measurements are claimed.

The shared library is a symlinked dependency at `../qsm-shell`. Desktop policy
stays here. Production is not restarted or operated by the agent. A source
commit is not evidence of live behavior or owner visual acceptance.

## Goals / Non-Goals

Goals: coherent violet material, visible control states, stable panel geometry,
readable time above a numeric date, a purposeful resource handle, compact notification
containment and correct ownership of the affected surface lifetimes.

Non-goals are listed in the proposal. In particular, preserve the accepted
rollout reveal/deformation, five panel tabs, keyboard vocabulary, application
identities, notification protocol ownership and hardware services.

## Decisions

### One palette and one surface ladder

Deep Night starts at background `#1B1027`, surface `#2E203C`, text `#F6F1FB`,
muted text `#BCAECA`, accent `#C7A8EB` and band `#160D20`. Mountain Dusk keeps a
cooler violet-slate ground: background `#202332`, surface `#2D3141`, text
`#EDEAF7`, muted text `#B3AEC8`, accent `#BDAFE5` and band `#171322`.

These are proposed source colors, not pixel acceptance. WCAG sRGB calculations
give resting surface/background 1.20696 and 1.20725 respectively. Body/muted
content pairs are recalculated in the source review before handoff.

Theme's raised, hover and outline roles use the same `Style.lift` derivation as
library controls: base contrast plus 0.2, 0.4 and 0.8. Do not keep raw JSON rungs
as an alternate paint path. Animate the base palette, not a second competing
animation of the derived rungs. Fallback colors match the actual default theme.

Keep primary, focus and danger roles semantic. The resource handle's neutral
violet-gray fill is not the selection accent. Static gradients are permitted
there as a specific material/level cue; reduced motion does not remove a static
gradient. No new glow, shadow stack, per-card gradient flags or icon-pack swap.

### Frame geometry without narrowing the rail

`reservedLeft` remains 60 logical px and `railWidth` remains 40. Ordinary top,
right and bottom frame thickness becomes 12 logical px. This is a chosen first
design value, not a measurement from Caelestia.

Trace the change through Theme, FrameExclusions, EdgeScene's masks/center,
ShellBorder input, rollout origins/insets and handles. Search remaining 16px
geometry before replacing it; a content inset is not automatically a frame
thickness. Preserve exact normative shader formulas and do not rebuild QSB.

### Clock composition

Show HH above mm, then a smaller single-line `DD.MM` beneath the time. Day and
numeric month sit side by side. The technical time digits use the 18px step and
fixed bold `00` metrics; the date uses the 12px step and medium weight. The numeric
date does not need the month name's HorizontalFit shrinking. Separate it from
the time by one token gap. No year row or clock icon.
Keep the existing calendar popout route. Digit motion remains local and is
settled immediately under reduced motion; a value change never moves the column.

### Stable responsive panel

Use a preferred outer width of 854 and height of 520 logical px. Clamp them to
the scene viewport between the 60px left band and the ordinary right/bottom
frame, retaining tokenized outer breathing room and room for the moving handle.
The chosen dimensions remain constant for a given viewport regardless of tab,
empty data, missing sensors, player metadata or history length.

Keep all five tabs. The navigation strip fills its fixed region and retains
Segmented's existing keyboard/action route. Dashboard, Media and Performance
are static compositions in a bounded content viewport; their natural content
can scroll on short screens rather than change the panel body. Workspaces and
Notifications retain their own model/scrolling semantics. Do not wrap an
existing model-backed list in another competing vertical scroller.

Reset the outer viewport offset on tab change. Center short media/empty content
within its viewport. Preserve Down into content and visible keyboard focus.
Review horizontal overflow on narrow outputs instead of truncating controls or
silently squeezing a three-column composition into unreadable values.

Use `layers` for the Dashboard tab and `gauge` for Performance as existing,
source-verified icon alternatives. Other system/app/tray glyphs are retained
unless their actual use exposes a mismatch. No decorative media asset is added.

### Resource capsule-like handle

Prepare a 224x36 logical px handle, one panel button with a fixed footprint.
Its lighter violet-gray capsule face lies within its registered body; the same
body supplies the input region and rides the panel's leading edge. No second
window, independent travel animation or passive status accent is introduced.

CPU occupies the left half and RAM the right half. Their thin neutral level
fills grow from the center toward the outside. Clamp finite samples to 0..1;
missing readings remain an em dash with no fabricated zero fill. Labels and
values use readable fixed columns, and unknown/100% changes never change width.
The service's existing CPU averaging remains the reading source.

The whole body forwards rest/hover/press/focus/disabled state. Static gradients
use named Theme roles. Click, Return/Enter/Space and `activate()` preserve the
existing panel action; pointer geometry stays fixed. Fullscreen/focus suppression
withdraws paint, input and the handle's lightweight sampling subscription.

### Opt-in notification material, unchanged policy

Add generic `surfaceColor`, `surfaceRadius` and `surfacePadding` presentation
inputs to the existing library NotificationCard; default transparent/no added
padding preserves other consumers. The card paints a Surface behind its current
content, with tokenized radius and state colors, never a new protocol policy.
Vertical padding participates in natural collapsed/expanded height so text does
not paint against the rounded edge. Keep the bounded readable body preview.

NotificationStack forwards these inputs and an optional `rowSpacing` defaulting
to zero. Desktop popups choose a quiet raised color, a radius concentric with
their enclosing host and tokenized row gaps. Per-row surfaces replace separator
chrome, not urgency meaning. The center remains unchanged unless its caller
explicitly requests the same material.

Follow added spacing through eviction height, column extent, retained paint,
geometry reporting, clip boundaries and removal. A retired row still paints but
has no input. Fullscreen keeps its one DataCapsule body and input-only eligible
row holes. Do not add a background in both the desktop wrapper and the card.
Keep exact default-action lookup, named actions in the center, hover pause,
expiry, swipe/middle dismissal and service-owned lifetimes.

### Owned surface lifetimes

Replace the ownerless keyboard string with one explicit claimant and screen.
Expose `claimKeyboard(owner, screen, purpose)`, `releaseKeyboard(owner)` and
`keyboardFor(screen)`. Release succeeds only for the owning instance. A new
claim, monitor departure, modal replacement, suppression or owner destruction
retires the previous prompt and its secret. Only the owning scene gains
keyboard focus and retention; another monitor's popout must not remain open.
Production hosts and isolated fixtures pass the screen explicitly.

Define local modal occupancy once in EdgeScene and use it for handle suppression
and local popout dismissal. Do not change the intentional one-global-modal
policy or the displayed-workspace fullscreen predicate.

Launcher receives its host's activation fact and has one `retire()` path.
Retirement clears editors, secrets and focus/layout timers, cancels only its own
read-only probes, and rejects late results/focus work. Seed consumption also
belongs only to the active host. Clear the supplied Wi-Fi password before
handoff regardless of whether the backend starts the operation. Accepted
application launches and intentional clipboard-copy work are not cancelled.

PerformanceService keeps keyed lightweight handle watchers and adds keyed
detailed-demand watchers. Each permanent panel host owns its demand while its
Dashboard/Performance tab is active; loaded tab destructors no longer write one
global boolean. An outgoing monitor cannot disable the incoming panel's GPU,
storage or network sampling. Keep hardware reads and polling periods otherwise
unchanged. Update mock services to the same public shape.

### Workbench and acceptance

Extend the existing panel, resource, notification and network stories instead of
building a new harness. Expose all five panel compositions with deterministic
service snapshots, normal/short viewport, missing data, meter boundaries and
changed material. Existing story keys remain reachable.

Implementation tasks are marked source-prepared only after source review. Live
appearance, pointer/keyboard behavior, both outputs, two themes, reduced motion,
screen-reader output and real device consequences remain separate open evidence.
Do not add/run tests, validation, captures or synthetic input without a new
explicit request. This overrides automatic-check steps in generic workflows.

## Risks / Trade-offs

- A stable panel can waste space: use a designed centered composition or an
  honest empty state, not stretched rows or decorative filler.
- Thin framing can leave dead input corridors: follow the same rect from host
  geometry through paint, masks and exclusive zones.
- New notification gaps can introduce a removal jump: account for gap extent
  in the existing retirement mechanism, not an extra easing or timer.
- Theme-to-Style reuse can create a cycle: keep only base colors as inputs;
  derived rungs never feed their own base or a separate animation.
- A global keyboard claimant can collide with modal focus: qualify ownership,
  clear obsolete prompts and never derive owner from the currently focused
  output after the claim.
- Library work is a dependency: commit and review it on library main before
  the desktop caller relies on it. Do not vendor a copied component.

## Migration Plan

Record specs and the task list before code. Land foundation, stable panel,
resource/clock, related ownership and notification material in logical commits.
All delegated source work returns to main before handoff. No push or archive.
The owner reloads and judges one prepared item at a time; no self-acceptance.
If a revision is needed, fix the owning token/component rather than the fixture.

## Open Questions

No blocking product choice remains after the owner's answers. Exact colors,
first-value geometry and icon alternatives are proposed implementation baselines
for live judgement, not screenshot-measured or owner-accepted pixels. Local-only
wallpaper distribution remains the separate open task `qsd-i63`.
