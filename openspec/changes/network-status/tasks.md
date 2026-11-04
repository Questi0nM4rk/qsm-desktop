## 1. The fake machine streams changes

- [x] 1.1 qsm-compuse `scripts/shims/nmcli`: `monitor` runs until killed and prints one line in
  nmcli's own format ("Connectivity is now 'X'", "NetworkManager is stopped", "NetworkManager is
  running", else "Networkmanager is now in the 'connected' state") each time the `nm` record
  changes, also while `nm.running` is false. Proof: in a slot, `drive slot mock` of
  `.nm.connectivity` and of `.nm.running` each print their line within a second.

## 2. One status and its glyph

- [x] 2.1 `NetworkService.qml`: `available` from the device probe's exit code, the reset of the
  link state on a failed read, `status` and `statusKey`, `glyph` and `glyphMuted` over the status.
  `Rail.qml` reads them and pulses on `connecting`; the launcher keeps `glyph`. qsm-shell gains
  `link.svg`. Proof: the network-states journey's rail shots draw the requirement's glyph and
  colour in each state, read from the item tree.
- [x] 2.2 `NetworkService.qml`: the `nmcli monitor` Process with the 150 ms coalescing timer and
  the restart. Proof: the journey's rail shot follows a mock change with no 26 s wait.

## 3. One notification per result

- [x] 3.1 `NetworkService.qml`: the 3 s settle timer, the baseline, the copy of the design;
  `NetworkStatus.qml` replaces `ConnectivityState.qml` and its two-sample rule. Proof: the journey shoots
  one notification (no Internet), and the toast shows the design's summary; connecting sends none
  (no toast in its shot window).

## 4. The popout and the documents

- [x] 4.1 `NetworkPopoutContent.qml`: the reason line names `unavailable`, `portal`, `offline`
  and `radio-off`. `spec/03-rail.md` and `spec/04-notifications.md` describe the status, its
  glyphs and its notifications. `atlas/desktop.atlas`: the shorter waits and the notification
  shot. Proof: two runs of the network-states journey, each state's popout shot reads its reason,
  and the second run changes no shot.
