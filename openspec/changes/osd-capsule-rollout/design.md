## Context

OsdSurface currently hosts one ColumnLayout inside Rollout; fullscreen detaches
that Rollout and registers a shader capsule. OsdChannel already extends the shell
Slider. OsdState owns monitor targeting and a 1500ms hide timer. EdgeScene owns an
overlay-layer window and its input mask. The desktop provider exposes only rail
popouts and does not yet receive previewEnvironment or isolate OSD services.
`vendor/qsm-shell` resolves to the sibling source repository.

## Goals / Non-Goals

**Goals:** genuine DataCapsule in fullscreen, attached Rollout otherwise, unchanged
compact desktop dimensions, one persistent real-service channel composition and
one presentation lifetime, and an owner-reviewable desktop OSD story.

**Non-Goals:** new provider, shader redesign, notification changes, production
service replacement, unrelated rail cleanup, automatic testing/capture/restart.

## Decisions

### Production surface and shared content

Keep OsdSurface as the one production policy component. Extract its channel column
into OsdContent with output/microphone/brightness slots hosted by current shell
Sliders. Service bindings and channel intent handlers remain in this desktop
composition. OsdSurface creates this content exactly once and changes its visual
parent between a dedicated Rollout slot item and DataCapsule.contentItem. A Loader
per presentation or duplicate columns is rejected: switching must preserve child
objects, bindings, values, mute and current OSD kind. Expose the real content and
controls to the provider through a small native-target API, not child-tree guesses.

Normal mode keeps Theme.osdWidth (56), track width/height (40/140), thumb size (32),
channel palette, order, availability, reading and label action. Channel layout
height is explicit track height plus the shell Slider's current natural label
insets; it never gets a length derived from mock-screen dimensions. Fullscreen
body has the same width and content-driven height, centered at the right edge
with Theme.space4 inset. Explicit bodySize/preferredLength/width/height and inset
overrides are caller sizing, not new library size presets. Capsule padding must
leave the same real 40px track available, not crop it inside 56px.

### Mode-exclusive wrappers and input

Use scene.fullscreen from the existing per-monitor FullscreenService in production.
Rollout is suppressed in fullscreen and its detached/capsule path is disabled for
this surface. DataCapsule is shown only for the active OSD on a fullscreen screen;
it paints its own material and is not registered as a second shader capsule.
Normal Rollout keeps its existing host registry and handle corridor. Fullscreen
has no idle handle/corridor. OsdSurface publishes the shown capsule body input rect
to EdgeScene directly; fade-out/shadow never retains a clickable fullscreen area.
Handle leading-edge/open-fraction data remains truthful for normal mode.

### Production handle parity

Normal-mode story must include the same handle as production: a shader circle
with the accepted handleRadius/handleProud values and the chevron-left glyph whose
rotation follows rollout.openFraction. Extract desktop OsdHandle and use it in
EdgeScene and OsdStory. OsdSurface exposes its existing centre/radius facts; handle
never re-derives a corridor or observes hover independently. Both border hosts
bind handle0 to that component's vector. Fullscreen/focus hides both circle and
glyph; modal/handlesArmed policy stays with the scene and surface. The provider
exposes the real glyph as a named input target and reports the live handle vector,
glyph bounds and surface corridor as render facts. This is desktop policy, not a
new shell component or a test-only drawing copy.

### One desktop lifecycle

OsdState remains the sole owner of visibility, targetScreen, kind and 1500ms expiry.
DataCapsule uses timeout:0; its keepOpen supplies retention, not a second timer.
The normal wrapper supplies wantsOpen including corridor/grace; fullscreen reads
capsule.keepOpen. Only the targeted screen answers retention, including cleanup
when target/mode changes. Repeated show refreshes the existing timer even at the
same level/kind, respecting an already-held surface. A mode switch does not call
show, reset values, rebuild content or cancel/restart the lifetime merely because
the wrapper changed. If the effective hold fact changes, normal pause/resume applies.
Startup and brightness reconcile suppression stay intact. Controls continue to
call the existing audio/brightness service methods; focus-held inputs retain OSD.

### Desktop proof story

Add `osd-layer` to the existing qsm-desktop stories provider, not Compose support
or a third provider. Keep the existing rail implementation behind its current
branch and route the new story to a small OsdStory using real OsdSurface, a real
ShellBorder host, and isolated fake AudioService/BrightnessService/OsdState modules.
Preview does not import production service processes. Fake OsdState must resolve
the same presentation-state implementation as production instead of cloning its
timer behavior. If extracting a shared injectable presentation object is needed,
do it in the state-owning task; wrapper modules instantiate that one object.
The preview state module exposes the canonical OsdPresentation file through a
symlink and a local non-singleton qmldir entry. It does not import the production
state directory relatively: Quickshell's preview module redirection blackholes
that path. Both wrappers therefore instantiate the same source safely.

Adapter receives previewEnvironment only as a harness-owned input and forwards it
to OsdStory. Logical screenRect determines the proof scene; its fullscreen flag
selects the production scene's mode. F11/actual workbench window fullscreen is not
this flag. An ordinary neutral mock app/background lives in the desktop story;
do not import another provider fixture or build a second placement algorithm.
Provider capabilities declare preview support through the harness's existing
contract. Controls expose independent channel availability, sample state and
presentation operations. Native targets point to the actual controls; component
intent, fake-service result and scenario setup have separate provenance. A rejected
route stays rejected; no fabricated completion. Reset cancels timers/work and
resets state without startup events. Both modes preserve content identity/state.

### Library ownership

Use public component contracts first. Any missing reusable contract is reported
with a concrete failing behavior and corrected in qsm-shell, with an owning
component record and shell spec updated in the same bounded correction. Do not
re-derive library hover/geometry in the provider to hide a component defect.
No shell source edit is currently assumed necessary.

### Small-surface animation consistency

The owner accepts the OSD visual baseline and asks for unification. OSD keeps
its existing compact dimensions and small-tier shared Rollout animation; capsule
opacity remains the library capsule's separate presentation, not a fake rollout.
Rail BarPopouts must also select the documented small tier. Its outgoing content
and natural dimensions remain present and opaque until the shared rollout is no
longer visible. The controller can clear semantic identity immediately; the host
retains only a rendering selection for the closing interval. Closing content is
not an interactive target and cannot report itself as the active semantic item.
New content can interrupt retract and reverses the same library motion; hidden
completion cannot unload that newly selected content. Switching content in an
already open host does not introduce an independent close/reveal opacity effect.
No local fade or delay timer substitutes for Rollout.visible/animating. Existing
nested placement, seamless joins, sizing policy and controller identity remain.
The owning change is in desktop BarPopouts, not new library easing or animation
flags. Shell behavior/docs/specs need revision only if a reusable defect appears.
The owner's subsequent close feedback identifies that reusable defect: the shader
was painting the shrinking aperture. Shell change `rollout-body-retract` separates
full translated silhouette from clipped input viewport, keeps full-body radii and
aligns deformation pivots; default content settle scaling is off. Desktop reads
those real geometry facts and does not add another translation or easing fix.
The same owning shell change also ends attached motion at the exact origin wall,
with identity effective deformation and no zero-outness shader contribution, so
border recovery is not a second animation. This endpoint correction is compiled
but remains visually unaccepted until the owner reviews the revised item.

## Risks / Trade-offs

- Reparenting can discard focus/grabs during a mode transition → keep one visual
  object and do not synthesize gestures; cancel an invalid active gesture through
  the component contract if needed, reporting any missing contract in shell.
- Several screens answering retention can overwrite one singleton → only the
  current target reports, and a target change recomputes its hold fact coherently.
- QML hot reload may affect an owner's running shell → no deliberate production
  restart/input without permission; report that source changes may reload.
- Fake timers can drift from production → share the presentation object, not
  just similarly named methods. Real services remain untouched.
- Previous green shell flows do not prove this desktop composition → preparation
  is source-reviewed only until the owner requests checks/live operation.

## Migration Plan

Implement channel content, wrapper/input integration, shared presentation state,
then isolated story/provider routing sequentially. Update `spec/05-osd.md` and the
ideology's fullscreen exception in place. Leave all other surfaces and dirty work
untouched. No commit, archive or deployment is included without authorization.

## Open Questions

None for product scope. A discovered reusable component gap blocks only its
dependent task until a bounded shell correction and matching docs/specs are ready.
