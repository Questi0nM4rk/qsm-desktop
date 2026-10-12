# 02 — Rollouts

## Target and deployment boundary

Rollout expands its source container's silhouette around full-size content. The
library's [`rollout-expansion` spec](../../qsm-shell/openspec/changes/rollout-expansion/specs/rollout-expansion/spec.md)
defines the target; [`Rollout` record](../../qsm-shell/docs/components/Rollout.md)
and [`12-mechanism`](../../qsm-shell/docs/12-mechanism.md) own its component and
shader contracts. This consumer does not implement another expansion mechanism.

Current source uses expansion for OSD, all rail entries and nested details,
panel/session, ModalHost consumers and attached notifications, with no style
selector. Rail source paint survives its outgoing child; matched heights use the
full body, not the reveal aperture. Rollout owns modal target-size morph; animated
notification extents pass through directly. Detached fullscreen stays separate.
The production desktop is restarted on the owner's request using `scripts/qsm-run`.
The owner reviewed all attached production surfaces and accepts the rewrite's
appearance and smooth motion across them, not only Network. Service, keyboard and
input-mask correctness are not inferred from this visual/motion acceptance;
generic library variants remain a separate review scope.

The old contract is retained under `archive/rollout-travel/` as superseded
material. It is not a competing instruction or a completed-change assertion.

## Consumer contract

- Supply host, stable rollout identity, requested full body dimensions, source
  edge/parent and content. Keep dimensions independent of animated/clipped children.
- Supply host-owned open intent and suppression; the library reports pointer,
  grace and animation facts. Surface policy decides dismissal and keyboard
  retention without reimplementing containment, timers or nested geometry.
- Use the host's frame depth normally; explicit inset overrides remain available
  where a composition deliberately differs. Anchor centring and nudge apply only
  to the free axis; a child starts at its parent's settled full-body edge.
- Put content directly on the common silhouette. No full-size backdrop, second
  border, travelling-body offset, independent reveal scale/fade or attached goo.
- Keep outgoing content identity and requested dimensions through retract; disable
  retired actions immediately. The Rollout registers its near-settled aperture
  for input, never hidden body or paint-only weld extensions. Modal catch regions
  and Wayland conversion remain desktop policy.
- Use the shared small/large curves, reduced-motion durations and one size-animation
  owner. Already animated child extents set `animateBodySize: false`; notification
  entrance/eviction is not duplicated by the expanding container.

## Render and terminal contract

Intent → shared progress → stationary full-size content and growing aperture →
host-coordinate silhouette → ShellBorder normalization/welds → one shader union,
fill and glass edge → separate input registry → hidden removal.

The contour grows along `edges[0]`; additional contacts square corners without
adding a diagonal reveal. Source-side corners join flush; free radii clamp to
current aperture half extents. Frame/parent joins preserve non-origin contacts,
exact full-span seams and short-child T-junctions. Input never inherits paint-only
edge snapping or continuation.

At zero depth, outness is zero and deformation is identity before unregistering.
The slot preserves the incoming fill/rim field, existing edge gate and lighting;
the source border and persistent handles must not recover in a second motion.
There is no origin-wall sink, parking allowance or delayed visibility timer.

## Review and migration

Keep OSD's accepted footprint, palette, services, focus clearance and pointer /
pressed-gesture retention. Keep Network's existing radio confirmation, scanning,
password keyboard retention, rows and feedback states; only its container's
geometry changes. Network's wider contour and opposite edge inform the same
general mechanism, not a permanent network-specific rule.

Source migration covers the attached callers above; geometry opt-ins and the
travel comparison are removed. Live owner review remains one item at a time.
No source edit or catalog refresh is evidence that a running QML window reloaded.

Fullscreen capsules stay outside the attached expansion contract: there is no
frame to expand. They keep their own content/service lifetime and overlay/input
policy. The owner judges one live item; tests, captures, validation and automatic
input require an explicit request. New planning does not change or restart the
live desktop.
