> Superseded mixed travelling motion specification; historical snapshot, not the current attached-expansion target.

# 10 — Motion

## Reveal token

- Reveal uses cubic-bezier **(0.05, 0.7) / (0.1, 1.0)**: fast out of the border,
  soft landing. Retract uses **(0.3, 0) / (0.2, 1)** toward hidden. Neither travel
  curve overshoots; bounded goo supplies the subtle deformation separately.
- Shared `qsm-shell/qml/QsmShell/Style/Motion.qml` owns Rollout curves and duration
  tiers: LARGE **500ms**, SMALL **250ms**. Desktop `shell/theme/Motion.qml` exposes
  its remaining consumer motion vocabulary, not an alternative Rollout mechanism.

## Goo

- Squash/stretch is barely visible: shared maximum **2%**, default intensity **0.01**,
  stiffness **200** and near-critical damping **28**. Per-surface intensity overrides keep
  the same ceiling. The library's `Motion` tokens and normative `12-mechanism.md` own it;
  ordinary reveal/retract curves do not overshoot.

## Secondary tokens

- SMALL-surface reveal/retract tier: **250ms**, using the respective curves above.
- OSD and rail popouts explicitly use the shared small tier for reveal and retract.
  Rail content stays opaque with its outgoing dimensions through the shared close;
  no independent content fade or unload timer races the extrusion. Semantic
  dismissal immediately disables actions, and hidden completion unloads the body.
- The shared shader paints a full-size translated body through reveal/retract,
  not the shrinking clip viewport. Radii stay body-relative and content has no
  default settle scaling. Easing/duration changes do not substitute for this
  geometric motion; `../qsm-shell/docs/12-mechanism.md` defines the mechanism.
- Attached retract finishes at its origin wall. Effective goo and shader joins
  reach their hidden endpoint there; no extra sideways parking or delayed return
  of the border follows the motion.
- Popout entry-to-entry morph glide: **250ms**, using its `emphasizedEasing` token.
- Micro-interactions (hover states, tick fades, icon swaps): **130ms**, standard decelerate.
- PRESS response tier = **80ms**, standard
  decelerate — a press must land under the finger, not after it; on the micro tier the control
  reads as lagging the click. RELEASE returns on the micro tier, so a control settles back
  rather than snapping. Hover growth and press push are separate states, never one tint.
- Reduced motion disables Rollout goo and uses **120ms** for its reveal and morph
  tiers. Micro-interactions retain their token-specific reduced durations; do not
  turn every token into 120ms. No travel overshoot exists in either motion mode.
