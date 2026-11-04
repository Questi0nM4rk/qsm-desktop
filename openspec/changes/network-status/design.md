## Context

`NetworkService` reads NetworkManager through nmcli every 10 s: devices, radio, the Wi-Fi list,
VPN profiles and the cached connectivity. Its `glyph` is computed from two booleans
(`ethernetActive`, `wifiConnected`), and `ConnectivityState` sends a loss notification on the
second poll without Internet and a restore notification on the next full reading. When nmcli
fails, the device probe clears the lists but leaves both booleans as they were.

## Goals / Non-Goals

**Goals:** one status owned by `NetworkService`, a glyph per status, one notification per
settled result, a change seen within a second, the stale link state gone.

**Non-Goals:** the same shape for Bluetooth, audio and battery (the owner's next step, another
change); an active connectivity check (`nmcli networking connectivity check`), which spec 03
keeps out; any change to connect, disconnect, VPN or the password prompt.

## Decisions

- **The status is a function of what the probes read, computed in one binding, in
  `NetworkStatus.qml`.** It takes `available`, the device rows, `wifiEnabled`, the signal and the
  Internet state, and derives the link facts, `status`, `statusKey` and `presentation` (glyph,
  muted, summary, detail, problem) in the order of the requirement. A binding has no second
  writer, so the glyph, the colour, the popout and the notification read the same value in the
  same frame, and one table holds every sentence. The workbench fixture instantiates the same
  type over its scripted answers, as it did `ConnectivityState`, which `NetworkStatus` replaces,
  so a story shows the status the shell computes.
- **Portal and offline need a link.** NetworkManager reports `none` for a machine with no link at
  all, so without the guard `radio-off` and `idle` could never show.
- **`available` comes from the device probe's exit code.** Exit 0 is available; anything else
  (8 is "NetworkManager is not running", per nmcli's man page) is unavailable, and the probe then
  empties the device rows and the network list, so no link fact reads the last link. The radio
  read fails the same way and reads off.
- **The notification owner is a settle timer in `NetworkService`.** Each change of `statusKey`
  (the status plus the connection it names) restarts a 3 s timer; when it fires and the key
  differs from the last one reported, the service notifies and stores the key. The first fire of
  a session stores the key without notifying. `connecting` restarts the timer and is never
  reported. This replaces `ConnectivityState`'s two-sample rule, which existed to drop a single
  bad reading: the 3 s hold drops it as well, and a second rule for the same job would be a second
  owner.
- **`nmcli monitor` is a trigger, not a source.** A long-running Process reads it line by line and
  any line calls `refresh()` through a 150 ms coalescing timer, because the monitor prints several
  lines for one change. The probes stay the one reader of state, so the monitor's line format
  never becomes a parser to maintain. A change that lands while a probe still reads waits for it
  rather than being skipped. When the monitor exits, it is started again after 2 s. The 10 s poll
  reads only the Wi-Fi list, because the monitor reports every change but the signal strength.
- **The connecting pulse is an opacity loop on the rail glyph** of period `Motion.pulse`, the
  library's breath of a waiting surface, which doubles under reduced motion (a loop calms by
  getting slower, the library's law).
- **Notification copy** (summary, body):
  - `wifi`: "Connected to SSID", "Wi-Fi".
  - `ethernet`: "Connected by cable", the connection name.
  - `idle`: "Disconnected", "Not connected to any network."
  - `radio-off`: "Wi-Fi is off", "Turn it on in the network popout."
  - `offline`: "No Internet connection", "CONNECTION is connected, but has no Internet access."
    (limited: "has limited Internet access").
  - `portal`: "Sign in to the network", "CONNECTION asks for a sign-in before it gives Internet
    access."
  - `unavailable`: "Network status unavailable", "NetworkManager is not running."

## Risks / Trade-offs

- A monitor that never prints (nmcli missing its D-Bus) leaves the rail on its last reading until
  the next change it hears of; the log says each time the monitor exited.
- The fake machine's monitor polls its state file every 0.5 s, so the atlas sees a change within
  half a second; the real one is event-driven.

## Proof

The atlas's network-states journey shoots the rail and the popout in all seven states after each
notification has gone, plus one notification, on the fake machine. Each state's rail glyph is read
from the item tree, and the notification's summary from the notification's item. A second run
of the journey changes no shot.
