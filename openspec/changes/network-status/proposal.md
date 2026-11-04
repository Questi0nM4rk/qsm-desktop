## Why

The rail's network glyph tells three things apart (cable, wifi by signal, wifi-off), so a captive
portal and a network with no Internet look like a working connection, and a stopped
NetworkManager, an unknown state and an idle radio all look like an off radio. The owner found
it on the atlas board, where all seven network states are shot: "nejde videt rozdil mezi status
unknown, wifi only, ethernet only, disconnected, unavailable". Notifications fire only for an
Internet loss and its return, on the second 10 s poll, so a person learns that the cable or the
Wi-Fi dropped only when they notice it themselves.

## What Changes

- NetworkService publishes one network status, the most important of eight, in the owner's order
  (problem before connection): NetworkManager unavailable, captive portal, no Internet (or
  limited), connecting, ethernet, Wi-Fi, Wi-Fi on with no link, radio off.
- The rail and the launcher draw that status's glyph: `network` (muted), `circle-alert`,
  `alert-triangle`, `link` (pulsing), `cable`, `wifi` / `wifi-low`, `network` (muted),
  `wifi-off` (muted).
- Every change of the status sends one notification once it has held for 3 s, for results only:
  connecting never notifies, and the status a session starts in is the baseline, not news. This
  replaces the loss and restore notifications on the second poll.
- NetworkService learns of a change from `nmcli monitor` as it happens, not from the next poll.
  The 10 s poll reads only the Wi-Fi signal, which the monitor does not report.
- A device read that fails resets the link state, so a stopped NetworkManager is never read as
  the connection it had before.
- The popout names a stopped NetworkManager, a portal and a missing Internet in its reason line,
  and no longer says "Wi-Fi radio is off" when NetworkManager is down.
- The atlas shoots each state after its notification has come and gone, and one notification.
  The fake machine's nmcli answers `monitor` (qsm-compuse, a commit in the marketplace).

## Capabilities

### New Capabilities

- `desktop-network-status`: the network status, its glyph, its notifications and how it learns
  of a change.

### Modified Capabilities

(none: the desktop's behaviour lives in `spec/`, and spec 03 and 04 are amended in place.)

## Impact

- `shell/services/NetworkService.qml`, `shell/services/NetworkStatus.qml` (in place of
  `ConnectivityState.qml`; the workbench fixture uses it too),
  `shell/modules/bar/Rail.qml`, `shell/modules/bar/NetworkPopoutContent.qml`.
- `spec/03-rail.md` (the glyph line and the notification paragraph), `spec/04-notifications.md`
  (the network example is now the real producer).
- `atlas/desktop.atlas`: the network-states journey waits for the notification instead of two
  polls.
- qsm-shell: the `link` glyph from lucide-static 1.31.0, the source the set already uses.
- qsm-marketplace qsm-compuse `scripts/shims/nmcli`: `monitor` prints a line when the `nm`
  record changes.

## Critiques

- Devil's advocate: "a notification on every change floods a flaky Wi-Fi." Answered: the 3 s
  hold drops a status that flips back, and connecting is not a result; a link that really drops
  and returns twice a minute is news the person wants.
- Devil's advocate: "portal and no Internet before connecting hides the cable glyph." Kept: the
  owner's order puts a problem first, and the popout and the notification still name the link.
  Portal and no Internet count only while a link is up, or radio off and no link could never
  show, because NetworkManager reports no Internet for both.
- Future archaeologist: "why a poll beside the monitor?" Written in the design: the monitor
  reports state, not signal strength, and the glyph's wifi or wifi-low reads the strength.
- Scope sniper: "Bluetooth, audio and battery want the same." Out: the owner asked for the
  network first and to reuse its shape afterwards, in another change.
