## Context

OsdContent already answers OsdChannel.iconClicked using AudioService mute
methods. Brightness explicitly has no mute. OsdStory hosts the same production
surface with isolated fake services and already dispatches actions by name.

## Goals / Non-Goals

**Goals:** consume the shared label operation, provide meaningful names and
observe actual fake-service state through production content. **Non-Goals:**
live audio mutation, changing focus policy, another backend, OS pointer use,
networking, desktop polish, restart or package upgrade.

## Decisions

1. Depend on the implementation and focused verification of shell's
   `shell-label-action-parity`, not an invented duplicate keyboard handler.
2. Set `labelAccessibleName` in OsdContent for output and microphone, naming
   the current operation (Mute/Unmute output or microphone). Brightness remains
   a caption and receives no mute action. Availability must agree with current
   AudioService capabilities; unavailable channels cannot mutate service state.
3. Add `toggle-output-mute` and `toggle-microphone-mute` to OsdStory's existing
   action dictionary and visible declarations. Resolve the actual channel and
   call `activateLabel()`; existing iconClicked callbacks are the only route to
   the service. Unknown, hidden or unavailable targets return false.
4. One focused installed-Workbench flow covers pointer, actual focus/key input,
   public actions, unavailable refusal and normal/simulated-fullscreen host
   state. The real production components use isolated fake services; observe
   service-operation evidence separately from label intent. Programmatic
   calls must not secretly synthesize input or claim keyboard delivery.
5. Strategy B: consume only after the shell segment, verify this same named
   item, then owner review. No TDD, snapshots, screenshot sweeps or generic
   harness changes. Shell and desktop tests do not count as owner acceptance.

## Risks / Trade-offs

- Normal production OSD is not a globally focused keyboard surface → preserve
  EdgeScene policy; the existing action picker calls AudioService independently.
  Focus-capable Workbench input verifies the component, not compositor focus.
- Fake audio does not prove actual hardware changed → state this limitation.
- Existing output host may not bind availability consistently → fix only the
  selected channel's enabled binding if needed; do not alter other service policy.

## Migration Plan

The shared shell code lands first in the current local import arrangement.
Then update desktop hosts/story and the current OSD spec. No runtime restart,
commit or archive is included; retain the running owner's desktop untouched.

## Open Questions

None for this bounded label operation. Other action-menu capabilities remain
separate shell-integration items, not implied completed by this change.
