# 05 — OSD (volume / brightness / microphone)

Reference: `references/osd-sliders-right.png`.

## Presentation and shared implementation

- Production and story share desktop `OsdHandle`: the ShellBorder handle circle
  and rotating `chevron-left` glyph read OsdSurface's actual centre/radius/opening
  facts. The surface alone owns its trigger/hold corridor. The handle adds no
  separate hover reader, timer or input handler. Fullscreen/focus hides the arrow
  and sets the circle radius to zero; normal mode keeps the accepted 7px radius,
  3px proud offset and 12px glyph. The story's `osd-handle` target is the real glyph
  and its render facts include the shader vector, mapped glyph corners and corridor.

- Normal applications use the attached shell `Rollout`; a fullscreen application
  uses the real shell `DataCapsule`, never the OSD's detached-Rollout shader path.
  Both are centered on the right edge. Fullscreen adds `Theme.space4` inset and
  has no idle handle. The body stays 56px wide and content-height in both modes.
- `OsdSurface` creates one persistent `OsdContent` FocusScope and reparents it
  between the wrapper slots. Output/microphone/brightness use current shell
  `Slider` controls with the same service bindings, ordering, availability,
  per-channel palette, 40x140px tracks and 32px thumbs. Reading and mute remain
  thumb/label content; brightness's label is not an action.
- Fullscreen capsule draws its own body and shadow, with no second shader capsule
  registration. `capsuleInputRect` contributes only its shown, enabled body to the
  scene's input mask; fade-out and shadow never intercept the application.
- `OsdPresentation` is the one service-independent visibility/kind/target/1500ms
  timer owner, wrapped by production `OsdState`. Capsule timeout is zero; the
  desktop owns expiry. The targeted screen reports effective retention through
  `setRetention(screen, held)`: the rollout's corridor/grace, the capsule's
  pointer hover, or any channel's live `pressed`. Focus alone never retains
  the OSD; it can persist after a click and outlive pointer departure. Focus
  indicators, keyboard and service actions remain intact. Inactive screens
  cannot overwrite the targeted screen's retention. Same-value
  hold reports do nothing; mode changes alone do not refresh the expiry budget.
- Repeated `show` refreshes the same lifetime, even for the same kind/value. A
  held surface (pointer or gesture) stays held; a focus that outlives its click
  does not, so a new show refreshes the budget while a thumb is still focused.
  Release starts the normal 1500ms budget. Reset cancels pending work. Startup
  and brightness reconciliation do not present the OSD.
- Desktop story `osd-layer` hosts the production surface with isolated fake
  services and the same `OsdPresentation` implementation. Workbench's readonly
  fullscreen preview context selects its presentation; actual window F11 does
  not. The story never invokes production audio or brightness processes.
- Output and microphone labels use Slider's shared `labelAccessibleName` and
  `activateLabel()` route. Names follow the current mute operation; each
  actionable label is disabled when its AudioService channel is unavailable.
  The brightness glyph remains a passive caption. OsdStory exposes
  `toggle-output-mute` and `toggle-microphone-mute` through those same channel
  functions, preserving `label-clicked` intent and separate AudioService
  `operated` evidence. The focused `osd-label-action` flow is prepared for the
  isolated story; it has not been run. Its simulated fullscreen presentation
  is not compositor fullscreen or evidence of live audio behavior.
- Workbench session control selects this exact story and inspects real scene data
  without system-mouse operation. `renderFacts` expose actual wrapper bounds and
  corners, input region, retention/focus and each channel's available track span,
  value, thumb and label geometry. Whole control height includes label insets;
  an individual split track segment is not the whole track's measurement.
- Production compositor-fullscreen runtime measured the 56x650 OSD capsule with
  all three channels visible; each thumb, label and glyph stayed within its body.
  Show/expiry and fullscreen keyboard/input behavior were exercised. The OSD's
  fresh visible Workbench story was not verified; production evidence is not a
  Workbench result, nor does it exercise audio/brightness mutation routes.
- The owner accepted the attached Rollout OSD appearance as the current baseline,
  including its extruded-contour look. This does not accept fullscreen DataCapsule
  appearance; capsule visual acceptance applies only to the composition watched,
  not unviewed states. Keep its footprint and palette while
  unifying small-surface motion; this does not accept unexercised production
  service/input paths or later rail animation changes.
- `OsdSurface` consumes Rollout's only attached geometry. Content is placed
  directly in its readonly `contentItem`; the shared component owns the parked
  body, aperture-relative radii and identity deformation in `02-rollouts.md`.
  There is no surface opt-in or Workbench travel comparison. Fullscreen still
  reparents the same content into DataCapsule without changing its footprint.
- The shared rewrite is loaded by the owner-requested desktop restart. The owner
  accepts its appearance and smooth motion across attached production surfaces,
  including OSD. This is not exhaustive service/input-mask verification, nor
  the compositor-fullscreen geometry and input evidence recorded above.

## Anchor and idle affordance

- **RATIFIED (2026-08-25 — owner, amended)**: the vertical OSD is a true right-frame rollout.
  Its right side joins the frame with squared connected corners; it must never render as a
  detached ellipse with upper and lower bulges.
- **RATIFIED (2026-08-25 — owner, amended)**: the persistent right-band handle rides the
  rollout's live opening edge. Its invisible hold corridor is continuous from the handle and
  revealed OSD through the right frame to the physical screen border, so a cursor held on the
  arrow cannot dismiss the surface.
- The corridor belongs to `OsdSurface`, not the scene. It computes both of its own shapes,
  closed (a nub-sized strip, found before anything shows) and open (the revealed rollout's full
  vertical extent), from its own leading edge and rollout bounds, and feeds both outward two
  ways: `EdgeScene` reads back only the current one, as `corridorZone`, for its input mask, and
  no longer reaches into the rollout to open it; the library `Rollout` reads the same two shapes
  directly as `triggerAreas` (closed strip) and `hoverAreas` (open strip), so its own `wantsOpen`
  already answers "is the pointer holding this open" and `OsdState.setHovered` is fed straight
  from that instead of a separate show-only handler. The corridor's own numbers are unchanged and
  stay the owner's to tune: this changes who computes them and what they drive, not what they
  are. `OsdState`'s ~1.5s auto-hide (below) is a different rule from the library's 180ms hover
  grace: one hides after silence, the other only cancels a close already scheduled.
- **DEFAULT (2026-08-16)**: the handle exists on EVERY monitor; the surface itself appears on
  the focused monitor at event time; hover-opening uses that monitor's own surface.

## Sliders

- **RATIFIED (2026-08-16, redesigned 2026-08-19 — owner)**: THICK TRACKS, one per channel
  (output volume / microphone / brightness), and the value rides a CIRCULAR THUMB that travels
  the track. The reading is inside the thumb, so the number is wherever the eye already is —
  on the thing that moved. A readout set above the track in caption text was legible only if
  you already knew where to look.
- **RATIFIED (2026-08-19)**: each channel carries its OWN hue, drawn from the palette
  (output = accent, microphone = secondary, brightness = warning — warm, because the channel is
  light). Three identical grey tracks gave no way to tell at a glance which one had moved.
  Legitimate multi-hue: these are distinct categories rather than peers of one kind, and each
  keeps its own glyph, so colour is never the only signal.
- **RATIFIED (2026-08-19)**: the hue is IDENTITY, the thumb is EMPHASIS. The track's colour
  does not change with which channel is live; the thumb is always the lightest thing on the
  surface (raised) over a track darker than the band (inset), and the active channel's thumb
  goes to full `text` while the others sit a step down. De-emphasis is never opacity.
- **DEFAULT (2026-08-27)**: the active vertical level uses its channel hue as a subtle vertical
  gradient: brightest at the thumb's leading edge and darker at the base. It preserves the
  channel identity while giving the filled track depth without adding another affordance.
- **DEFAULT (2026-08-16)**: pills are VERTICAL, surface vertically centered on the right
  edge, height content-driven. Interactions: click/drag on a pill sets the value, wheel over
  it nudges, clicking the channel icon toggles mute — mute shows via the icon-swap law
  (muted glyph), never a glow.
- **DEFAULT (2026-08-16)**: backends — volume/mic via PipeWire default sink/source;
  brightness via brightnessctl (internal display; external monitors out of scope).
- **RATIFIED (2026-08-16)**: event-reactive — ANY state change to a slider's channel (volume
  keys, mixer change, brightness keys, mute toggles, device switch) auto-rolls the OSD out.

## Expiry

- **RATIFIED (2026-08-16)**: retract **~1.5s** after the last event; hovering the OSD holds it
  open (expiry pauses, resumes on leave).

## Numbers (RATIFIED 2026-08-16)

- Surface width **56px**; track **40×140px**; thumb **32px** circle, inset 4px each
  side of the track and travelling `trackHeight - thumbSize`; solid lift under the thumb 2px
  (4px while dragging), zero blur. Small channel glyphs ride at the tracks' ends. Default
  order top→bottom: output volume, microphone, brightness. The 56px body is the whole
  APERTURE: the rollout clips at its own edge, so nothing the column draws past that
  edge is visible.
- **The column's position inside the body is CLAMPED, not nudged.** A `Rollout` centres
  content in body PLUS band, so `Rollout.contentCenterOffsetX` asks for 8px toward the
  frame on this surface's 16px band. Half of 56 is 28; the 8px pull leaves 20, which is
  exactly the track's own half and NOTHING over. But the track is not the envelope: the
  focus ring sits OUTSIDE the track by one half-step (`Style.spaceTight`), a hovered or
  pressed thumb grows further per side, and a clickable channel glyph's hit box is at
  least one large icon tall. The ring's outer 2px therefore drew under the frame, where
  the rollout's own `clip` cut them. `OsdSurface` measures the real envelope from the
  channels' own geometry — the slider's implicit width, which already reserves the grown
  thumb, plus the ring's track-plus-gap and the label hit box — and clamps the requested
  offset within `±max(0, bodyWidth / 2 - envelope)`, the closest position to the requested one that
  keeps all three whole. Fullscreen has no band to correct for, sits at offset 0, and the
  same envelope fits its 56px body unchanged.
- Handle: **3px** proud of the band (LIVE-TUNE; owner-tuned down twice from 6 — "a nub, not
  a bulge", Theme.handleProud), vertically centered; invisible hover zone is one generous
  continuous rectangle from the arrow glyph's left edge (with small padding) through the
  revealed rollout, through the right frame, to the physical screen edge — no dead gap.
- Appears on the FOCUSED monitor at event time (09-input law).
- **RATIFIED (2026-08-25, owner)**: stays above a fullscreen client when a channel changes. The
  idle hover handle stays hidden and inert there, so fullscreen does not grow a persistent shell
  affordance; hardware events and the revealed OSD controls remain the only entry.
