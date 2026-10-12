# Decision table — every gap, keep or not

Every item found missing across [`hyde.md`](hyde.md) and [`caelestia.md`](caelestia.md),
including the ones first rejected. `Keep` is a recommendation for the owner to override.

Filter applied: feature-full, keyboard-driven, colemak-friendly, beautiful in detail,
minimalist — not a caelestia clone.

## Spec debt — already ratified by `spec/`

| # | Item | Keep | Reason |
| --- | --- | --- | --- |
| 1 | Media popout on the rail | **yes** | `spec/03-rail.md` names it outright ("battery, clock, media when present") with a reference png, so it is not a new feature but an unbuilt one. MPRIS data already exists in `MediaService.qml` — this is a popout kind, not a subsystem. |
| 2 | Popup overflow choreography + cap 5 | **yes** | `spec/04-notifications.md` RATIFIES a cap of 5 with older entries sliding up into the top band, clipped, no fade; the code is a static Column at `popupLimit: 4`. It is the single most-seen motion in the shell and currently the least designed. |
| 3 | DND persistence | **yes** | `spec/09` lists `dnd` as a persistence key and it silently resets on restart. Two lines in `ShellState.qml`. |
| 4 | One `state.json` | **yes** | `spec/09` names one file; there are three (`shell.json`, `theme.json`, `notifications.json`). Consolidating removes a class of partial-write bug and makes the state inspectable in one place. |
| 5 | `>calc` actually works | **yes** | `spec/07` RATIFIES libqalculate but `qalc` is not installed, so the mode renders an empty result forever. One package away from a shipped feature. |
| 6 | Phase 10 acceptance walkthrough | **yes** | `spec/13` phase 10 was never run, so no surface has been signed off end-to-end. This is the MVP gate itself, not a feature. |

## Keyboard reach

| # | Item | Keep | Reason |
| --- | --- | --- | --- |
| 7 | Keyboard path into rail popouts | **yes** | Network, bluetooth, sound, battery and calendar are fully built and hover-only, so five working panels sit behind a mouse. This contradicts "keyboard-driven" harder than any missing feature does. |
| 8 | Media keys routed through the shell | **yes** | `hyprland.lua:178-181` sends play/next/prev straight to `playerctl`, so the OSD never sees them — the exact bug the level-key law was written to prevent. `MediaService` already has the transport; only the wire is missing. |
| 9 | Keybind cheat sheet | **yes** | 65 binds exist with no way to see them, and HyDE's `SUPER+/` proved the pattern by reading the compositor's live binds so overrides show up. The shell already publishes 14 descriptions through `hyprctl globalshortcuts`. |
| 10 | Window switcher surface | no | `SUPER+TAB` already cycles via the compositor, and a visible switcher list duplicates what the workspaces overview tab shows better. Revisit if cross-workspace window reach becomes a daily miss. |
| 11 | OSD keyboard-adjustable | no | Volume and brightness already have dedicated hardware keys that drive the OSD, so a second keyboard path to the same sliders adds a mode without adding reach. Neither reference desktop does this either. |

## Small utilities

| # | Item | Keep | Reason |
| --- | --- | --- | --- |
| 12 | Emoji picker `>emoji` | **yes** | One more launcher mode over a static database, no new surface, no new dependency beyond the list itself. Both references ship it and it maps straight onto HyDE's `SUPER+comma`. |
| 13 | Night light | **yes** | The one screen shader with daily value, and the only accessibility-adjacent feature the shell currently lacks entirely. HyDE's 7×9 preset matrix is overkill — one temperature and an on/off is the minimal honest form. |
| 14 | Keyboard-layout indicator | **yes** | `kb_layout = "us,cz"` is live and completely invisible, so the only way to know the current layout is to type and see. One rail status glyph fed by the data `HyprClientsService` already reaches. |
| 15 | Caps / num lock indicator | no | Real value on a laptop with no caps LED, but it is a second status glyph competing for rail space against the layout indicator, which is the more frequent surprise. Fold in later if the layout glyph proves the pattern. |
| 16 | Scratchpad / drop-down terminal | no | Pure compositor binds and window rules with zero shell code, so it does not need to be in a shell round at all. Add it to `hyprland.lua` any time — it is not blocked on qsm. |
| 17 | Game mode as one state | no | `SUPER+ALT+G` already toggles animations, which is 80% of the effect for 0% of the code. Formalising blur and shadow into a named state is polish on a feature that already works. |

## Surfaces

| # | Item | Keep | Reason |
| --- | --- | --- | --- |
| 18 | Shell-side screenshot picker with window snap | no | caelestia's auto-snap to the hovered window, matching its border width and rounding, is genuinely the most beautiful detail in either reference. But the delegated script works today and this is a whole new fullscreen-overlay surface — the right Round 3 candidate, not MVP. |
| 19 | Window inspector as a user surface | no | `shell.qml:312 inspect()` already exists as a dev tool, which is the only audience that ever needed it. Promoting it to a user surface adds a window nobody opens. |
| 20 | Toasts | no | The owner explicitly rejected complicated notification machinery, and the notification popups already carry transient messages. A second transient surface competing with the first is exactly the overcomplication to avoid. |
| 21 | Weather forecast depth | no | The dashboard card shows current conditions and the card is already the busiest thing on the tab. Seven days of forecast is data density for its own sake on a desktop, not a phone. |
| 22 | Notification popup action buttons | **yes** | The centre invokes actions on Enter but the popup — the thing actually on screen when a notification arrives — cannot act on it at all. This is a dead end in the primary flow, not a nice-to-have. |

## Previously rejected — media decoration

| # | Item | Keep | Reason |
| --- | --- | --- | --- |
| 23 | Screen recording | no | Owner rejected it explicitly. It also drags in `gpu-screen-recorder`, a recordings list, a delete modal and a mode split-button — caelestia's single largest card. |
| 24 | Lyrics | no | A C++ backend across three providers plus a scrolling tab column, dead the moment a track has no lyrics on file. Highest complexity-to-use ratio in either reference. |
| 25 | Bongocat / beat detection | no | A drumming-cat GIF synced to BPM detected live by `aubio` from the PipeWire stream. Novelty that requires a real-time audio-analysis dependency to exist at all. |
| 26 | Cava visualiser | no | A spectrum ring around the media art is defensible as detail-perfection rather than sprawl, and `MediaTab.qml:13` already notes it as not ported. Still a daemon plus a custom-painted item for something that conveys no information — revisit once the media popout exists and the tab feels bare. |
| 27 | Desktop clock plate / background visualiser | no | Floating plates on the wallpaper are the one thing the prime law forbids outright — every surface is a fluid rollout of one edge band. Not a taste call; an architecture violation. |

## Previously rejected — settings and theming

| # | Item | Keep | Reason |
| --- | --- | --- | --- |
| 28 | Nexus-scale settings app | no | Eleven live-editing pages contradict the `spec/09` delegation law that hands NetworkManager, BlueZ and PipeWire to their own tools. `Delegate.qml:26-35` already escapes to nm-connection-editor, blueman and pavucontrol. |
| 29 | Per-app volume mixer | no | A per-app slider row inside the existing sound popout is small and genuinely used daily, so this is the most defensible reject on the list. Cut only because `AudioService.qml:18-20` deliberately skips stream nodes and pavucontrol owns mixer depth — reopening it means reopening that decision. |
| 30 | Wallbash's ~15 app targets | no | Deriving palettes and rewriting Discord, Spotify, VSCode, Chrome, GTK, Kvantum, Qt and vim themes is a second project with a permanent maintenance tail. The N-theme JSON engine is the opposite bet — curated palettes, not derived ones. |
| 31 | 18 animation / 6 layout / 5 workflow presets | no | Eighteen animation presets is what gets built when a decision cannot be made; the `Motion` tokens are one good answer. Adding a picker means every future motion change must hold across 18 variants. |
| 32 | One alternative layout (master or monocle) | no | A real workflow difference rather than decoration, and it costs zero shell code — one compositor bind and a rule. Left out only because it belongs in `hyprland.lua`, not in a qsm round. |
| 33 | The other 9 screen shaders | no | Colour-vision simulation, daltonization, OLED burn-in shift, e-ink paper, grayscale, invert, vibrance and a combiner are accessibility demos and edge-case tools. Each is a shader carried forever to be used approximately never. |

## Previously rejected — launcher sprawl

| # | Item | Keep | Reason |
| --- | --- | --- | --- |
| 34 | Web search `>search` | no | Fits the wants almost perfectly — one mode, keyboard-only, no new surface — and was cut mainly to hold the launcher at four modes deep. `>emoji` is taking the fifth slot this round; this is the strongest candidate for the sixth. |
| 35 | Glyph picker `>glyph` | no | Nearly free once `>emoji` exists: same row UI, different database. Cut because nerd-font glyphs get typed while editing configs, where an editor snippet serves better than a shell mode. |
| 36 | Bookmarks launcher | no | Reads the browser's bookmark DB to fuzzy-open one. The browser's own address bar does this better and also knows history. |
| 37 | Game launcher | no | Merges Steam and Lutris catalogs into a cover-art grid with five styles. It is a special case of the app launcher, and `SUPER+SPACE` already finds Steam. |
| 38 | Package-manager UI / update counter | no | An update count in the rail is plausible on its own merits. HyDE's 8-backend abstraction (pacman, paru, yay, apt, dnf, zypper, flatpak) exists for a distro-agnostic project — this box runs Arch and only Arch. |

## Previously rejected — session and windows

| # | Item | Keep | Reason |
| --- | --- | --- | --- |
| 39 | Session snapshots | no | Save and restore window layouts by name, with per-app plugins for Brave's transient classes, VS Code multi-window and kitty's CWD. The plugin list is the tell: it works only because each app was special-cased, and breaks silently when one changes. |
| 40 | Window groups / scrolling layouts | no | Group cycling, group locking, out-of-group moves, column consume/expel — all compositor behaviour with no shell component. Configure in `hyprland.lua` if wanted; qsm is not involved either way. |
| 41 | Workspace groups (×10 blocks) | no | Treats workspaces as ten blocks of ten so `CTRL+SUPER+3` jumps to the 30s. A hundred addressable workspaces solves a problem that ten workspaces, mostly unused, does not have. |
| 42 | swaync / dunst / waybar / rofi / wlogout parity | no | Matching HyDE's UI means reimplementing 56 waybar modules, 21 bar layouts and 12 rofi menus. Already killed by design — this row exists so the map is honest that ~60% of HyDE's surface area is deliberately gone. |

## Tally

**Keep = yes (13)**: 1 media popout, 2 popup choreography, 3 DND persistence, 4 one state file,
5 `>calc` works, 6 phase-10 walkthrough, 7 popout keyboard path, 8 media keys through the shell,
9 keybind cheat sheet, 12 `>emoji`, 13 night light, 14 layout indicator, 22 popup actions.

Strongest rejects to revisit first: **34 `>search`**, **29 per-app volume row**,
**26 cava ring**, **18 screenshot picker**.
