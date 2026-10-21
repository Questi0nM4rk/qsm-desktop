# Backlog

Open items only, one line each; what is fixed or historical is in git.

## Decisions waiting on the owner

- Top panel defaults that follow the rebuild spec over a ratified or trial line, each one constant to revert: 864 wide (the width that centres on the rail band and the monitor edge with both edges on whole device pixels), label-only tabs, a date block with no time, three Performance rings with the storage as bytes under the memory ring, the distro mark `textMuted`, cards 8 apart.
- Rail popout travel triangle is a geometric no-op at level 1 (the band already spans the rail's height): delete it, or narrow the band to the visible column so it bridges a gutter.
- F5: popup Enter for the default action; spec/04 requires keyboard Enter only for the centre, and a second route may break 09's one-path law.
- Notification group ordering: two apps tied on "has a live entry" compare equal, so a third group can split a section header; pick the tiebreak.
- `ui-guard` clip-growth finding key embeds a layer's live hit rect and its full-hover growth in pixels, so findings depend on shell state: quantise the key, or drive the grown states with `scripts/hover-probe`.
- `PopoutRow` trailing `IconButton` is 24x24 in a ~30px row, so a 44px target does not fit without changing the row height (a spec question).
- Hit targets under 44x44 remain on the compact rail rows, the workspace dots and the colour swatches; one question about the rail's raster.
- `Theme.dark` is `current !== "mountain-dusk"` and `themeToggle` applies those two ids; make `themeToggle` cycle `Theme.themes` and derive `dark` from a theme JSON field, which changes the `dark` status contract.
- Whether the spec stamps keep their dates (`RATIFIED (date, owner)`); the markers stay either way.
- Whether `Rollout.padding` defaults to `Style.rolloutPadding`, and whether `recede` stays band-only (library questions).
- Notification popup Escape: whether it also dismisses all visible notifications.
- The colour picker's card: centred on its sparkle cell (centre 736) it would run 44 below its column (bottom 808) and close a pocket of desktop between them, and the library places a nested rollout inside its parent's span; the ratified `match` tier keeps it flush with the column (centre 676). Keep it flush and say so in RR-1, or design the L-shaped union.
- Which band is the design source: the library's `deep-night.json` says `#271e30`, the live theme renders `#2D1540` (written by `derive-theme` from the wallpaper), and the rebuild spec's contrast figures were computed on the first. Decide, then recompute them.

## Defects and gaps

- The colour picker rollout's history is eaten by its edge fades: the list viewport is a few rows tall and the library `ScrollCue` paints a fixed 48 px fade at each end (`modules/bar/ColorPickContent.qml` around line 309), so no swatch is fully visible (owner: "kdy je mala, tak ten fade in, and fade out na ni, proste sezere vsechny items"). Check every desktop scroll area the same way once the library bounds the fade by the viewport (qsm-shell backlog).
- The rail's keyboard route is source-reviewed only (Tab order, the card a focused quick-action cell opens, the workspace slots' focus ring, accessible names): Quickshell is not on the AT-SPI bus without `QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1` at launch, so no tree was read and no key was driven.
- Theme artwork (`dark-rain-world.png`, `light-forest-dark-winter.jpg`) is untracked, so a fresh checkout lacks the images the theme JSONs name (`qsd-i63`).
- `EdgeScene.handlesArmed` disables every monitor for one global modal; `keyboardGrab` has no surface or screen owner and a prompt's closure can release another instance's grab (`qsd-om3`).
- Launcher retirement follows the global modal name, not each monitor's activation; `submitNetwork()` clears the password only after an accepted backend start.
- `ModalHost` only announces activation: launcher probe and clipboard thumbnail work can finish after dismissal; define which work cancels and rejects stale results.
- `LauncherSurface.qml` keeps unreachable dispatch branches; remove them with its lifecycle work.
- `BarPopouts` is not a `Rollout` (it calls the registry directly, hosts a nested stack, lacks the `suppressed` guard), so the keep-open region test lives twice, in `Rollout` and in `EdgeScene.popout1UnionContains`; the library `Rollout` cannot yet parent a nested rollout.
- The scene shader holds eight simultaneous silhouettes, so unbounded nested rollout chains need a registry redesign in the library.
- `Rollout.contentCenterOffsetX` costs half a band-depth on the attached side; only the OSD and session column are checked, not the rail popouts, panel, launcher or notification centre.
- `NotificationCard.qml` threw "Passing incompatible arguments to C++ functions" from `syncFullscreenCapsule` while a scene was fullscreen-transitioning; re-check with the log.
- `PopoutRow` and `ResultRow` are two wrappers over `ListRow`; fold them if their model shapes allow it.
- `BatteryPopoutContent`'s profile switch glides and the library `Segmented` does not; `RailDeviceCell`'s cross divider has no library type.
- Raw numbers remain in the bar popouts (letter spacing on the vertical app labels, margins, opacities, border widths, one `SvgIcon size: 58`) with no `Theme` token.
- Dimming by `opacity` remains on the rail while the session surface is open, inactive rail apps, off-centre theme cards and the bell; an icon, photo or scene fade cannot blend toward the band.
- `Theme.artworkRingStroke`: the library avatar ring is a share of the picture and reads heavy around a large cover.
- `ScrollCue.fadeColor` is hand-matched to each list's ground; no gate catches a wrong colour.
- Receded muted text on `surface` and `overlay` is about 3.4 and 2.6 against the 4.5 floor; only the band is enforced.
- The sound rollout was reported closing before the pointer reached a target; re-measure with live pointer geometry under the 180 ms hitbox rule.
- `scripts/test-quickshell` "command-centre parent selection did not restore" failed once and passed on re-run; find the race or delete the check.
- The command-centre check in `scripts/test-quickshell` reads the focused monitor, not the one the suite drives.
- `scripts/validate` stops at `test-quickshell` while a live instance holds the config path, so the shader freshness check after it never runs.
- Audio: the saved duplex ALC257 profile can accept streams and stay silent until PipeWire, pipewire-pulse and WirePlumber restart; QSM only binds volume and mute.
- Quickshell 0.3.1 is installed; 0.3.2 fixes notification action-label updates and needs a separately approved system upgrade, then a re-check of label-only replacement.
- Quickshell aborts with `Signal: Aborted (6)` in PipeWire teardown on every shutdown (upstream, no local fix); next step is a debug-symbol reproduction and an upstream report.

## Features

- Bluetooth LE pairing: a BlueZ agent for display-passkey, request-passkey/PIN, confirmation, cancel and timeout; the generic prompt may come from qsm-shell, the agent stays here.
- Wi-Fi credential flow: protected-network activation and final SSID identity are unverified against real hardware.
- A second theme's external Qt/GTK material (session-static deep-night today).
- Workspace spill: keyboard-driven cross-workspace window move.
- Panel notification cards are always expanded; collapse for dense lists.
- Launcher polish: row rhythm, empty and degraded states; cross-rollout token audit against the one ladder (`spec/11`).
- Animation ideas, none ruled on: OSD thumb pulse, launcher row stagger, theme card entrance, notification exit slide, panel tab crossfade, session button press hold, calc result flash.
- Keybind cheat sheet sizing is LIVE-TUNE; notification-centre row spacing awaits the owner's feel.

## Structure

- Desktop UIX review (`qsd-zbo`): every surface's states, controls, motion and input geometry; starts after the owner accepts the library items the desktop uses.
- The desktop has no test below `scripts/test-quickshell`; `Theme` imports Quickshell (`themesProbe`, `ShellState`), so about 40 UI files cannot load in `qmltestrunner`. Cutting that edge comes first.
- Split `ShellState` into pure state and a Quickshell adapter when something needs it.
- 23 UI files import `qs.services` directly; invert them per file (data in as properties) as each surface is touched.
- `docs/audit-2026-08-20.md` carries a human-trial list that was never driven: bluetooth, battery, sound, media transport, calendar paging.
- `~/.cache` holds about 65G of live caches (`uv`, `yay`, `omarchy`, `pre-commit`); reclaim by hand with their own tools.

## Unverified at runtime

- Owner review of the action menu one item at a time (audio first, then Wi-Fi, Bluetooth, toggles, panel tabs); isolated flows are not acceptance.
- Live pointer, drag, wheel, focus leaving and returning, and screen-reader output.
- Workspace-local fullscreen: entry and exit, two displayed fullscreen clients, special workspaces and client moves.
- Real nmcli, BlueZ, audio and brightness backends, and the full `scripts/validate` production gate.
- The CPU/RAM panel handle under live load, and the main-keyboard toggle with real hardware.
- Residual lint debt in `scripts/qml-lint.baseline`: repair with the owning surface, never by a blanket refresh.
