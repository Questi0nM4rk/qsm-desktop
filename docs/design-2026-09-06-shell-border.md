# ShellBorder: where the rollout mechanism lives

Owner decisions taken 2026-09-06. This is the record; nothing is implemented yet.

## The question

`Rollout`, the two registries and the silhouette shader are the last real
duplication between `qsm-shell` (the general component library) and
`qsm-desktop` (its first consumer). They are not a component — they are a
system — so lifting them needed an owner decision before any code.

## What the measurement said

`shell/components/Rollout.qml` is already a library type and does not know it.
It imports `QtQuick` and `qs.theme`, nothing else: no Quickshell, no Wayland,
no compositor, no service. It reaches its host through exactly seven calls plus
one read.

`shell/screen/EdgeScene.qml` is 1322 lines, but the compositor-specific part of
it is small.

| part | lines that mention it | belongs to |
| --- | --- | --- |
| window, layer shell, exclusive zone | ~45 | consumer |
| input mask | ~50 | consumer |
| the two registries | ~44 | library |
| shader uniform packing | ~51 | library |
| six surfaces hosted inline | the rest | consumer |

The mechanism is geometry, and geometry is not about Wayland.

## Decisions

| layer | decision | why | verified by |
| --- | --- | --- | --- |
| ownership | The library owns `Rollout`, the two registries, the uniform packing, and the `.frag`/`.qsb`. | The melt is one silhouette law, and a second consumer writing its own shader is the album-art defect at system scale: two assemblies of one idea drift by construction. | Owner, 2026-09-06 |
| boundary | The library never names Wayland, monitors or input masks. It publishes plain rectangles; the consumer turns them into a `Region`. | The one thing a component library cannot know is what surface it is drawn on. Rectangles are geometry and cross that line unchanged. | Owner, 2026-09-06 |
| build | The library ships the `.frag` AND the committed `.qsb`, with the `qsb` compile in its own script, exactly as the desktop does today. | The alternative leaves the shader with the consumer, which is the drift above. The cost is that the library stops being pure QML and gains a build step, and that is accepted. | Owner, 2026-09-06 |
| transport | The mask rects leave through a `readonly property var`, which the consumer binds. Not a signal. | A binding cannot forget to subscribe, and cannot deliver an update the consumer drops. Recommended and not contested; revisit if a consumer needs the change event rather than the value. | Assumed by the recommendation, owner did not contest |
| host contract | `Rollout` finds its host by duck typing: the seven functions plus `fullscreen`, written down as a contract. | QML has no interfaces. Seven functions is small enough for a test to hold honest, and the alternative (the rollout emits, the host connects) is more code for the same guarantee. | Owner, 2026-09-06 |
| consumer keeps | The `PanelWindow` per monitor, the layer shell, the exclusive zone, fullscreen detection, pinning, which surfaces exist and where they sit. | These are policy and protocol. A second consumer replaces all of them and keeps every line above. | Owner, 2026-09-06 |

## The seven-call contract

What a `Rollout` requires of its host. Any object answering these is a host.

```qml
registerBulge(id, rect, radius, blend, deform, minEig, edgeBits, rimBits,
              detached, outness)
unregisterBulge(id)
registerRolloutRegion(id, rect)
unregisterRolloutRegion(id)
registerFullscreenCapsule(id, rect, radius)
unregisterFullscreenCapsule(id)
// plus one read:
readonly property bool fullscreen
```

## What this unblocks

The motion tiers (500ms / 250ms) and the goo spring belong to `Rollout` and
move with it. That answers the question this design was ordered ahead of: the
notification popup stack's eviction choreography needs `Motion.revealSmall` and
`Motion.revealCurve`, and those become library tokens as a consequence of the
lift rather than as a vocabulary invented for them. Design the rollout first,
and the motion vocabulary is a result rather than a decision.

## Order of work

Unchanged from the library backlog, and deliberately slow:

1. Port the shader unchanged. No behaviour change, no rename.
2. Render one `ShellBorder` with one dynamically anchored rollout.
3. Review THAT live before adding nesting, welding, resizing or fullscreen.

The rule `contentCenterOffsetX/Y` carries across on day one: a rollout is the
band BULGING, so content that centres itself centres in body plus band. Centring
in the body alone is half a band-depth off, on every rollout, every time.

## Not designed

- The eight-slot budget. Unbounded concurrent chains still need a registry
  redesign, and nothing here changes that.
- Whether a second consumer can supply its own `.frag`. Assume not until one asks.
- Any change to the melt formulas. `spec/12-mechanism.md` stays normative and
  moves with the shader.
