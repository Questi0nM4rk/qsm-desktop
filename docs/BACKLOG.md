# Backlog

Open items only, one line each; what is fixed or historical is in git.

## Decisions waiting on the owner

- Rail band 40 wide with a 32 capsule and a 4 gutter (`Theme.reservedLeft`, `railWidth`, `railGutter`): the literal half of the glyph-to-rollout gap (24 to 12) and, with `railPopoutPadding` 8 and `railPopoutRadius` 20, of the rollout padding. To revert, restore 64, `Control lg` and `space2`, and the shell's padding. What the narrow capsule changed: the battery reads at 12 px so "100%" fits, the date is two pairs with a dot (`22.` over `10.`), the updates count takes the glyph's place (a chip beside a glyph covers it at 32), and the two lines span 24 of the 32 (32 would equal the capsule).
- The workspace strip sits at the rail's middle only when the rail is at least 976 tall; on 864 the bottom stack stops it 56 above the middle (centre 376 of 432) and the app list keeps three rows above it. The alternative is the strip under the app list with one row left, or a shorter bottom stack.
- The colour history holds 18 picks in two rows of nine (`ColorPickService.historyLimit`, was 24) so nothing scrolls under a fade; more rows would grow the quick-actions column.
- Top panel defaults that follow the rebuild spec over a ratified or trial line, each one constant to revert: 848 x 536 with `Theme.panelPadding` 8 (half the shell's padding, as the rail's rollouts; the content box stays 832 x 464, so every card keeps its size), label-only tabs, a date block with no time, three Performance rings with the storage as bytes under the memory ring, neutral glyphs and `Theme.loadTone` neutral below 70 percent (was success green and a sky weather glyph), cards 8 apart, the tab bar filling the content box instead of a centred 624.
- Rail popout travel triangle is a geometric no-op at level 1 (the band already spans the rail's height): delete it, or narrow the band to the visible column so it bridges a gutter.
- F5: popup Enter for the default action; spec/04 requires keyboard Enter only for the centre, and a second route may break 09's one-path law.
- Notification group ordering: two apps tied on "has a live entry" compare equal, so a third group can split a section header; pick the tiebreak.
- `ui-guard` clip-growth finding key embeds a layer's live hit rect and its full-hover growth in pixels, so findings depend on shell state: quantise the key, or drive the grown states with `scripts/hover-probe`.
- `PopoutRow` trailing `IconButton` is 24x24 in a ~30px row, so a 44px target does not fit without changing the row height (a spec question).
- Hit targets under 44x44 remain on the compact rail rows, the workspace dots and the colour swatches; one question about the rail's raster.
- `Theme.dark` is `current !== "mountain-dusk"` and `themeToggle` applies those two ids; make `themeToggle` cycle `Theme.themes` and derive `dark` from a theme JSON field, which changes the `dark` status contract.
- Whether the spec stamps keep their dates (`RATIFIED (date, owner)`); the markers stay either way.
- OSD channels: the rebuild spec wants the channels the change did not touch receded, but the owner ruled on 2026-10-18 that every channel draws the same ("jenom sound sviti, zbytek ne"); equal stays until the owner says otherwise, and the alternative is the spec's section 6 item 3.
- Session: Log out and Restart are armed-to-fire like Shut down but draw neutral at rest, only Shut down in `danger`; ux-audit wants every destructive tile cued, the rebuild spec reserves danger for the armed tile. Pick one rule for all three.
- Whether `Rollout.padding` defaults to `Style.rolloutPadding`, and whether `recede` stays band-only (library questions).
- Notification popup Escape: whether it also dismisses all visible notifications.
- The colour picker's card: centred on its sparkle cell (centre 736) it would run 44 below its column (bottom 808) and close a pocket of desktop between them, and the library places a nested rollout inside its parent's span; the ratified `match` tier keeps it flush with the column (centre 676). Keep it flush and say so in RR-1, or design the L-shaped union.
- Which band is the design source: the library's `deep-night.json` says `#271e30`, the live theme renders `#2D1540` (written by `derive-theme` from the wallpaper), and the rebuild spec's contrast figures were computed on the first. Decide, then recompute them.
- `>kill` runs on Enter without a confirm (spec/07 rejects one) and every kill row carries a danger glyph at rest; the rebuild audit wants a second Enter and danger only once armed (D-01, F-14).
- The launcher's search text is 18 px (`TextField` lg); the rebuild spec gives 18 only to the clock role, so this is a library question about the lg field's text step (F-11).
- Clipboard removal (the trash on the selected row, Ctrl+Delete) has no confirm and no undo: one entry is one copy; say if it should confirm like forget and clear do.

## Defects and gaps

- Rail rollout text boxes keep fractional heights (titles 17, metadata 14), so content inside a body sits on a fractional logical y that is still a whole device pixel; rounding them is a library `Prose` change that moves every surface.
- A colour swatch equal to the card it sits on (the history's `#2D1540` on a band-coloured card) is invisible: `ColorSwatch` draws no containment border at rest.
- The rail's app list with rows, its edge fade at three rows and the workspace dots' filled state need a live Hyprland session: the isolated slot has no windows or workspaces.
- The panel's Workspaces tab (tiles, window rects, drag, the wheel strip, tile keys) needs a live Hyprland session: the isolated slot has no workspaces, so only its card and empty strip are measured.
- The Media tab's play button is the largest transport glyph but not a filled `primary`: the library `IconButton` has no filled variant (a type with a unit and a record), and a body painted in the desktop would be a second button.
- A launcher row's keyboard focus ring is clipped on three sides by the list's clip rect (a detail view with the list focused, one row visible); the ring has to live outside the clip, or the list has to leave room for it.
- A launcher row's matched letters are not marked (only the ranking changed: a keyword-only match sorts below a visible one); marking them needs a `ListRow` slot and a decision on how a match reads next to the selected accent name.
- A `ListRow` trailing switch ends 12 px from the row's edge while its leading glyph starts 14 to 16 px from the other (the row inset is one number, the leading box centres its glyph).
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
