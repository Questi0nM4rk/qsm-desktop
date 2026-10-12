> Superseded travelling/mixed-mode specification. Historical snapshot, not the active rollout target.

# 02 — Rollouts

## Full-body reveal and retract

The shared shell Rollout moves a full-size body behind the stationary origin
border. Its shader silhouette is the translated body with full-body radii;
the narrowing viewport only clips revealed content and bounds input. It must
not paint the narrowing viewport as a shrinking rounded body. Content remains
opaque and unscaled by default; capped goo and shared curves remain unchanged.
`silhouetteRect` and `viewportRect` expose the two actual host-coordinate facts.
The shell's `docs/12-mechanism.md` is normative for this distinction and for the
common translated body-centre deformation pivot. One shared travel trajectory
does not imply identical shader/input rectangles.
Attached travel ends exactly at that origin wall, with no parking overtravel.
ShellBorder registration preserves the full body's declared origin sides behind
the band; automatic screen-edge snapping applies only to non-origin contacts.
Truncating that body to screen bounds with unchanged free radii is not allowed.
As outness falls, shader fill/rim contributions restore the incoming distance
field; emergence gates only newly exposed stroke, never the existing frame/parent
edge. Removing the hidden slot must not relight or reshape the bare border.
Content and shader effective deformation reach identity with outness; a hidden
slot adds no fill, rim, stroke gate or frame join. There is no later border-return
animation after rollout travel finishes. Fullscreen-detached compatibility is
separate from this attached-origin rule.

Production edge surfaces use one shared Rollout mechanism; consumers provide
content. The OSD and first-level Network popout opt into its border-extrusion
mode; other rollouts keep the default full-body travel pending owner review.

## OSD border extrusion

`Rollout.borderExtrusion` is a mode of the shared component, not a separate
component and not a registry shim. The desktop OSD sets it; the Workbench
**Example** control sets it too, so **current-rollout** is the default travel
comparison and **border-bulge** is what production now does. The mode is
selected while the presentation is fully hidden. Output, microphone and
brightness go through the same isolated services and production controls in
both options.

| Layer | Decision | Pattern / token | Owner inspection |
| --- | --- | --- | --- |
| Posture / task | Transient hardware controls for the desktop owner; finish an adjustment and return to the application. | Existing OSD channels and service actions | Adjust then leave; no persistent panel |
| Structure | Keep the channel order, palette, 56px body, 40px tracks and 32px thumbs. | `Theme.osd*`, channel identity colours | Same content and footprint in both options |
| Interaction | Pointer/wheel, native keyboard and programmatic slider actions share the existing routes; actions refresh expiry. Focus alone is not permanent retention. | `Slider`, `OsdPresentation`, corridor/grace and pressed gesture | Drag, release and leave; retained focus must not latch the OSD |
| Hierarchy | The border grows around stationary content; no travelling full-size background, second fill, scrim or independent rim. | `ShellBorder` merged SDF | Leading contour moves, slider positions do not |
| Geometry / motion | Use Rollout's reveal progress and input/hover contract. Under the opt-in the registered silhouette IS the growing aperture, free radii clamp to the current aperture, effective deformation is identity, and the body parks at its final host coordinate so content does not move. | Shared `Motion`; `Style.rolloutRadius`; origin-right mask | Reveal, reverse mid-flight and retract without a second border recovery |
| Responsive | Keep the target-screen scope and logical coordinates. Fullscreen continues to use the existing capsule, since there is no frame to extrude. | Host mapping, `DataCapsule` | Monitor scope and fullscreen presentation |
| States / access | Preserve native slider labels, focus indicators, disabled/missing channels and mute states. Reserve space for the outside focus ring. Hidden controls must not be interactive. | `Slider` accessibility, `Style.spaceTight`, current input gate | Whole focus ring visible; hidden controls cannot change a value |
| Polish | Reuse the calm frame fill, shared reveal/retract curves and reduced-motion durations. No new decorative animation. | `Theme.bandFill`, shared `Motion` | Bare border is unchanged after removal |

Render path: `OsdStory` → production `OsdSurface` → `Rollout` progress →
`viewportRect`/`silhouetteRect` → `ShellBorder.registerBulge` normalization →
existing `edgemelt` fill/rim → original input registry → hidden removal. One
slot, one fill, one pass; no second rectangle and no new uniform. The
aperture's attached wall and cross-axis extent stay fixed. The mode changes
paint geometry only, not the pointer verdict, service lifetime or input gate.
At zero depth, outness is zero and deformation is identity before removal.
Switching options while fully hidden needs no integrator reset: extrusion
enforces effective identity itself, and current-rollout runs the integrator
again, which springs any leftover matrix back to rest.

Caelestia's `modules/osd/Wrapper.qml`, `modules/drawers/ContentWindow.qml` and
`modules/bar/popouts/ClipWrapper.qml` demonstrate one merged blob renderer and
a clipped reveal. Their travelling/fading content is deliberately not copied.
The [WAI-ARIA slider pattern](https://www.w3.org/WAI/ARIA/apg/patterns/slider/)
and [Radix Slider](https://www.radix-ui.com/primitives/docs/components/slider)
preserve labelled, controlled values and native-style keyboard navigation.
Our Slider's accepted outside focus indicator must fit the owning surface;
these semantics are reused, not reimplemented.

Not designed here: nested rollouts and migration of other surfaces beyond the
Network comparison below. No new tokens. Source conflict: the production full-body rule
above governs the DEFAULT mode and does not govern the OSD's opt-in growing
paint rect; the shared shader's field-restoration and terminal-handoff laws
still do.

Acceptance scope is deliberately narrow. The owner accepted the extruded
OSD's appearance and behaviour on the restarted live desktop. This does not
establish every input/service route or accept other edges and nested rollouts.

## Left Network comparison

Only the first-level Network popout opts into extrusion through
`RailPopoutStack.parentPopout`. Its retained `renderKind` selects the mode so
semantic dismissal cannot switch geometry during retract. Other rail entries
and the nested detail host remain unchanged; this is not the global default.

| Layer | Decision | Pattern / token | Owner inspection |
| --- | --- | --- | --- |
| Task / structure | Inspect connectivity or use an existing network action, then return to the application. Preserve heading, network/device/VPN rows and hierarchy. | `NetworkPopoutContent`, existing network actions | Same useful content, no new settings UI |
| Interaction / states | Keep pointer corridor/grace, password keyboard retention and existing disabled, scanning, empty, joining, success and failure states. Mode survives dismissal until hidden. | `Rollout.keepOpen`, retained `renderKind`, current native controls | Enter from Network cell, cross into body and leave; password route unchanged |
| Geometry / sizing | Grow rightwards from the left rail around full-size stationary content. Preserve preferred width, content-height morph and free-axis clamp; no new size presets or content-derived reveal width. | `Theme.popoutWidth`, `Theme.space4`, shared `borderExtrusion` | Text stays still along the reveal axis; compare wide contour with narrow OSD |
| Polish / endpoint | Reuse the merged frame fill, aperture-relative radii, identity deformation, small motion tier and hidden-neutral handoff. | `Style.rolloutRadius`, shared `Motion`, original input registry | Reveal/retract and reversal; no border relighting or travelling slab |

Render path: Network cell/controller → retained `BarPopouts.renderKind` →
shared `Rollout` progress and parked left body → host-coordinate aperture →
`ShellBorder.registerBulge`/edge snapping → existing shader fill and stroke →
near-settled input aperture → hidden removal. The left body origin is
`edgeInsetH + 0` throughout reveal; only the aperture width changes. Long
content keeps the existing row elision, list cap and vertical placement policy.
No networking actions, focus policy, tokens, shader formulas or nested geometry
are changed. Network extrusion is prepared for live owner review, not accepted
or automatically tested.

## Silhouette law

- The rollout's rect and the band render as one merged SDF silhouette (melt reach per
  01-frame). Nothing inside a rollout may paint a full-size backdrop or its own chrome —
  content sits directly on the silhouette fill.
- Attachment is FLUSH — a rollout's attached edge coincides with
  the band edge (zero gap, no neck-only connection). One shape. Reference:
  `references/battery-popout-corner-join.png`.
- Corner auto-join — a rollout melts into EVERY band segment within
  melt reach, not just its declared edge. A bottom-left rollout fuses with the bottom border
  AND the left band simultaneously (`references/battery-popout-corner-join.png`). This falls
  out of the merged SDF automatically and must never be special-cased away.

## Reveal choreography

- `offsetScale` is **0 = fully shown, 1 = fully hidden**. It drives one travel
  trajectory for full-size content/silhouette and the exposed clip/input viewport;
  these are distinct rectangles, not interchangeable render bounds.
- Reveal and retract do not overshoot. `slideScale = max(0, offsetScale)` prevents
  a custom progress value from moving past the flush line. Organic deformation is
  bounded separately; it is not a bouncing position curve.
- Border-origin travel ends with the body's free edge exactly at its origin wall.
  Travel equals the body dimension along the reveal axis, with no extra melt-reach
  or 5px parking allowance. The shared shader provides origin fill continuation;
  the host does not truncate the body at its declared origin. The spawn border is
  per-rollout (rail popouts: the 60px band; other surfaces: their 16px band).
- Content is clipped at the origin wall, stays opaque and has no default settle
  scale. Retain outgoing content and dimensions through retract; semantic dismissal
  can disable actions immediately, but must not empty the visible body mid-flight.
- Keep the surface and slot until the shared transition is hidden. Before removal,
  deformation is identity and shader contribution is neutral; removing the slot
  must not move, relight or restore the fixed border or its persistent handle.
- LARGE surfaces use 500ms; SMALL surfaces use 250ms. Both tiers use the distinct
  reveal and retract curves defined in `10-motion.md` and shared library `Motion`.
  "Instant on hover" means zero hover delay, not zero animation duration.
- Interruptions retarget from the current position rather than jumping or restarting.
- A rollout spawned from another rollout anchors to the parent's
  settled edge, never its animated viewport edge. Every generation therefore has a stable
  origin and extrudes from the final shared seam; a parent may still reveal independently
  before a child is requested. Chaining is generic within the scene shader's active-slot budget.

## Squash/stretch (goo)

- Goo exists at SUBTLE level (10-motion) — velocity-driven
  squash/stretch applied to silhouette AND content together; per-surface intensity tuned live
  within the shared **2%** target deformation limit. The current formulas and
  defaults are owned by `qsm-shell/docs/12-mechanism.md` and library `Motion`.

## Input

- **RATIFIED (2026-08-16)**: a rollout's hit-rect tracks its revealed rect but activates only
  near-settled (past ~90% revealed) — see 09-input-and-states.

## Keep-open

- **RATIFIED (2026-09-07)**: keep-open is ONE rule, owned by the library's `Rollout`, and every
  consumer reads it the same way instead of inventing its own. It is a hitbox larger than the
  item, covering the corridors a pointer actually sweeps through on the way from opening it to
    using it, plus a delay after the pointer leaves. Two area lists in host coordinates:
    rectangles or `ScenePointer.triangleArea(a, b, c)` values, tested by one `contains()`:
  - `triggerAreas`: what OPENS the rollout, the nub, the rail cell, whatever a pointer finds
    before anything shows. Read with no delay, so a consumer's own "did the trigger fire" logic
    can gate off it too; empty means "nothing here opens on hover", never a fallback.
  - `hoverAreas`: what KEEPS it open once shown, the hitbox, sized to cover the corridor a
    pointer sweeps through (03-rail's travel triangle is one such corridor; 05-osd's revealed
    body strip is another). Empty falls back to the rollout's own silhouette, never to nothing.

  `Rollout` reports `triggered` (pointer inside a trigger area, right now), `hovered` (pointer
  inside a trigger or hover area, right now), `keepOpen` (`hovered`, extended `closeDelay`,
  180ms, `Motion.hoverGrace`, past the moment it drops), and `wantsOpen` (`triggered ||
  keepOpen`, the one property a consumer binds `shouldBeActive` against). The rollout never
  closes itself: it only ever reports. Open descendant hover contributes recursively through
  the declared parent/child relationship. The surface supplies band, anchor and corridor
  areas, then answers `keepOpen` or binds `wantsOpen`; it never adds a second union or grace
  timer. A newly shown body outside all areas receives the same grace, and hiding or
  suppression cancels pending grace. Keyboard retention remains surface policy.

  Before this, two surfaces each invented their own keep-open, and both were broken. The rail's
  region reader sat on an `Item` stacked BENEATH the interactive surfaces: a `HoverHandler` is
  shadowed by stacking order, not shared by it, so a reader placed below everything never saw
  the pointer at all. The OSD's hold lived in a second `HoverHandler` scoped to the rollout's own
  body, so a pointer anywhere in the wider corridor but off the body dropped hover and the OSD
  closed fast. Both are now the one rule above: the rail's reader is `ScenePointer`, declared on
  the `PanelWindow` that is the true ancestor of every surface rather than as a sibling stacked
  with any of them (a `HoverHandler` must sit on the ancestor of what it watches, never beside
  it, or it is shadowed the same way again); the OSD's corridor is `hoverAreas` on its own
  `Rollout`.
