# 05 — OSD (volume / brightness / microphone)

Reference: `references/osd-sliders-right.png`.

## Presentation and shared implementation

- Production and story share desktop `OsdHandle`: the ShellBorder handle tab
  and rotating `chevron-left` glyph read OsdSurface's actual centre/radius/opening
  facts. The surface alone owns its trigger/hold corridor. The handle adds no
  separate hover reader, timer or input handler. Fullscreen/focus hides the arrow
  and collapses the tab to zero height; normal mode keeps the 12x40 tab,
  11px proud offset and 10px glyph. The story's `osd-handle` target is the real glyph
  and its render facts include the shader vector, mapped glyph corners and corridor.

- Normal applications use the attached shell `Rollout`; a fullscreen application
  uses the real shell `DataCapsule`, never the OSD's detached-Rollout shader path.
  Both are centered on the right edge. Fullscreen adds `Theme.space4` inset and
  has no idle handle. The body stays 56px wide and content-height in both modes.
- `OsdSurface` creates one persistent `OsdContent` FocusScope and reparents it
  between the wrapper slots. Output/microphone/brightness use current shell
  `Slider` controls with the same service bindings, ordering, availability,
  40x140px tracks and 28px thumbs. The thumb is the only content a channel
  draws besides its track: it carries the glyph, the reading and the mute route.
- Fullscreen capsule draws its own body (`band` fill, no shadow, no stroke), with no second shader capsule
  registration. `capsuleInputRect` contributes only its shown, enabled body to the
  scene's input mask; fade-out never intercepts the application.
- **OPEN (owner)**: the fullscreen capsule has nothing behind it but the client; whether it
  may be the one exception to the no-shadow law on a bright client is undecided.
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
- Output and microphone mute is one shared route per channel, reached by the
  thumb's double-click, by accessibility/programmatic activation and by
  OsdStory's `toggle-output-mute` and `toggle-microphone-mute`. The route is
  disabled when its AudioService channel is unavailable. Brightness has no mute,
  so its thumb's double-click does nothing. There is no label under a track any
  more; the former `osd-label-action` story flow and its `label-clicked` intent
  are retired with it.
- Workbench session control selects this exact story and inspects real scene data
  without system-mouse operation. `renderFacts` expose actual wrapper bounds and
  corners, input region, retention/focus and each channel's available track span,
  value and thumb geometry. An individual split track segment is not the whole
  track's measurement.
- Production compositor-fullscreen runtime measured the 56x650 OSD capsule with
  all three channels visible; each thumb (then with a label under its track) stayed within its body.
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
- **RATIFIED (2026-10-16, owner)**: every channel draws the same way: the track is `surface`,
  the active level (the filled part) is `primary`, the thumb is `text` and carries its content
  in `textOnPrimary`. Channel identity is the glyph INSIDE the thumb, never a per-channel hue and
  never a caption at the track's end: the thumb is the one thing a channel shows besides its
  track. Fills are flat: no gradient, no thumb shadow. While a channel is live its thumb is
  `text` and the other channels' thumbs sit one step down in `textMuted`.
- **RATIFIED (2026-10-16, owner)**: the thumb shows the glyph at rest and the value while the
  channel is live. Live means a press or drag on the thumb, a wheel step over the track, or
  a service change (volume keys, mixer, brightness keys). The value stays for **1s** after the
  last change, the same budget as expiry, then the glyph returns. One channel at a time shows
  a value; a service event on another channel moves the value there.
- **DEFAULT (2026-08-16, mute route moved 2026-10-16 — owner)**: pills are VERTICAL, surface
  vertically centered on the right edge, height content-driven. Interactions: click/drag on
  a pill sets the value, wheel over it nudges, DOUBLE-CLICK on the thumb toggles mute — mute
  shows via the icon-swap law (muted glyph in the thumb), never a glow. The first click of
  the double-click is an ordinary press on the thumb, which moves nothing by itself; a
  double-click on the bare track is two value jumps, not a mute.
- **DEFAULT (2026-08-16)**: backends — volume/mic via PipeWire default sink/source;
  brightness via brightnessctl (internal display; external monitors out of scope).
- **RATIFIED (2026-08-16)**: event-reactive — ANY state change to a slider's channel (volume
  keys, mixer change, brightness keys, mute toggles, device switch) auto-rolls the OSD out.

## Expiry

- **RATIFIED (2026-08-16)**: retract **~1.5s** after the last event; hovering the OSD holds it
  open (expiry pauses, resumes on leave).

## Numbers (RATIFIED 2026-08-16)

- Surface width **56px**; track **40×140px**; thumb **28px** circle (shrunk from 32 on
  2026-10-16), inset 6px each side of the track and travelling `trackHeight - thumbSize`;
  no shadow under the thumb. Inside the thumb: a **16px** glyph at rest, or the value as a
  two-digit label in caption size while live. Nothing rides at the tracks' ends. Default
  order top→bottom: output volume, microphone, brightness. The 56px body is the whole
  APERTURE: the rollout clips at its own edge, so nothing the column draws past that
  edge is visible.
- **The column's position inside the body is CLAMPED, not nudged.** A `Rollout` centres
  content in body PLUS band, so `Rollout.contentCenterOffsetX` asks for half the
  frame thickness toward the frame. The 12px frame requests 6px; the 56px body's
  half-span minus that request is 22px. The track is not the full envelope: the
  focus ring sits OUTSIDE the track by one half-step (`Style.spaceTight`), and a hovered or
  pressed thumb grows further per side. The ring's outer 2px therefore drew under the frame, where
  the rollout's own `clip` cut them. `OsdSurface` measures the real envelope from the
  channels' own geometry — the slider's implicit width, which already reserves the grown
  thumb, plus the ring's track-plus-gap — and clamps the requested
  offset within `±max(0, bodyWidth / 2 - envelope)`, the closest position to the requested one that
  keeps all three whole. Fullscreen has no band to correct for, sits at offset 0, and the
  same envelope fits its 56px body unchanged.
- Handle: the circle nub sunk INTO the right band (owner 2026-10-17): its centre 2px inside
  the band's inner edge (Theme.osdHandleProud), so 5px of it shows, vertically centered; invisible hover zone is one generous
  continuous rectangle from the arrow glyph's left edge (with small padding) through the
  revealed rollout, through the right frame, to the physical screen edge — no dead gap.
- Appears on the FOCUSED monitor at event time (09-input law).
- **RATIFIED (2026-08-25, owner)**: stays above a fullscreen client when a channel changes. The
  idle hover handle stays hidden and inert there, so fullscreen does not grow a persistent shell
  affordance; hardware events and the revealed OSD controls remain the only entry.
