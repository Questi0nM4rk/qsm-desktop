# Gap map — what qsm covers, what is missing, in rounds

Companion to [`hyde.md`](hyde.md) and [`caelestia.md`](caelestia.md). Filtered against the
owner's stated wants: **feature-full, keyboard-driven, colemak-friendly, beautiful in every
detail, minimalist — not a caelestia clone.**

Nothing here is a decision. Rounds are a proposed order; the owner picks.

## 1. What qsm already covers

`DONE` = implemented and reachable. Audited against `spec/00`–`spec/13` and `shell/`.

| Domain | Status | Where |
| --- | --- | --- |
| Rail (logo, workspaces, apps, tray, clock, status, power) | DONE | `modules/bar/Rail.qml:30-234` |
| Workspaces strip + overview tab | DONE | `WorkspaceStrip.qml:39`, `panel/WorkspacesTab.qml:48-141` |
| Tray + native SNI menus | DONE | `Rail.qml:98-134`, `TrayMenuContent.qml:22` |
| Clock + month calendar | DONE | `ClockEntry.qml:14`, `components/MonthCalendar.qml:8` |
| Notification server (bus owned) | DONE | `services/NotificationService.qml:48-60` |
| Notification centre + history, fuzzy search | DONE | `panel/NotificationCenterTab.qml:20-69` |
| OSD — volume / mic / brightness, riding handle | DONE | `modules/osd/OsdSurface.qml:53-106` |
| Launcher — apps, fuzzy + frecency | DONE | `launcher/LauncherSurface.qml:45-58` |
| Launcher modes `>calc >clip >kill >theme` | DONE | `LauncherSurface.qml:24-29` |
| Clipboard history (cliphist + image thumbs) | DONE | `LauncherSurface.qml:305-352` |
| Top panel — 5 tabs, last-tab memory | DONE | `panel/PanelSurface.qml:37-42` |
| Dashboard cards (identity, weather, media, datetime, calendar, rings) | DONE | `panel/DashboardTab.qml:26-500` |
| Media / MPRIS — art ring, transport, seek, player picker | DONE | `services/MediaService.qml:11`, `panel/MediaTab.qml:8` |
| Weather (wttr.in, 30 min cache) | DONE | `services/WeatherService.qml:9-22` |
| Performance — CPU/GPU/mem/storage/net | DONE | `panel/PerformanceTab.qml:8`, `services/PerformanceService.qml:6` |
| Network popout (wifi, APs, VPN) | DONE | `bar/NetworkPopoutContent.qml:9-25` |
| Bluetooth popout (power, discovery, connect/forget) | DONE | `bar/BluetoothPopoutContent.qml:9-18` |
| Audio popout (sinks, sources, volume) | DONE | `bar/SoundPopoutContent.qml:8-22` |
| Battery + power profile | DONE | `bar/BatteryPopoutContent.qml:8-25`, `services/PowerProfileService.qml:6` |
| Session / power menu, arm-then-fire, blur backdrop | DONE | `session/SessionSurface.qml:32-50` |
| Lock (delegated to hyprlock, restyled) | DONE | `services/Delegate.qml:31` |
| Awake / idle-inhibit | DONE | `services/AwakeService.qml:9-20` |
| Wallpaper, per-monitor, cross-fade | DONE | `screen/WallpaperWindow.qml:27-66` |
| Theme engine — N-theme JSON, token cross-fade, persisted | DONE | `theme/Theme.qml:336-368` |
| Screenshot (delegated, notifies through the shell bus) | DONE | `~/.config/hypr/scripts/screenshot` |
| IPC — 20 functions on target `qsm` | DONE | `shell.qml:189-388` |

**Phase ledger**: `PRIMER.md:9-33` — phases 1–9 landed. **Phase 10 (acceptance walkthrough)
never run.**

## 2. Spec debt — ratified, not built

Not new features. The spec already won these arguments; the code hasn't caught up.

| Gap | Spec | State |
| --- | --- | --- |
| **Media popout on the rail** | `spec/03-rail.md` — "battery, clock, **media when present**", ref `references/media-popout-over-app.png` | No `media` popout kind exists. MPRIS lives only in the panel. |
| **Popup overflow choreography** | `spec/04-notifications.md` — RATIFIED cap **5**; older entries slide UP into the top band, newer enter from the bottom, clipped, no fade | Static Column, `popupLimit: 4` (`NotificationService.qml:17`) |
| **DND persistence** | `spec/09-input-and-states.md` — `dnd` is a persistence key | Toggles, forgets on restart (`ShellState.qml:105-110`) |
| **One state file** | `spec/09` names one `~/.local/state/qsm/state.json` | Three files: `shell.json`, `theme.json`, `notifications.json` |
| **`>calc` works** | `spec/07-launcher.md` RATIFIES libqalculate | `qalc` not installed → mode renders empty |
| **Phase 10 walkthrough** | `spec/13-implementation.md` phase 10 | Never run |

## 3. Missing — filtered by the owner's wants

### 3a. Keyboard reach — the biggest real hole

The desktop is built but a lot of it is **mouse-only**. This contradicts "keyboard-driven"
harder than any missing feature.

| Gap | Who has it | Why it matters here |
| --- | --- | --- |
| **Rail popouts unreachable by keyboard** | caelestia (Escape-close under a focus grab; still hover-open) | network / bluetooth / sound / battery / calendar exist and are fully built, but hover is the only way in. Four working panels behind a mouse. |
| **Media keys don't route through the shell** | caelestia (`caelestia:mediaToggle/Next/Prev/Stop`) | play/next/prev go to `playerctl` directly (`hyprland.lua:178-181`), so the OSD never sees them — the exact bug the level-key law was written to kill. `MediaService` already exists. |
| **No keybind cheat sheet** | HyDE (`SUPER+/`, reads the compositor's live binds, so overrides show) | 65 binds and no way to see them. `hyprctl globalshortcuts` already carries the shell's 14 with descriptions. |
| **No window switcher surface** | HyDE (alt-tab with focus history), caelestia (group cycling) | Currently `SUPER+TAB` = compositor `cycle_next` only — no visible list, no cross-workspace reach. |
| **OSD not keyboard-adjustable** | caelestia (scroll + drag; also no keys) | Neither has this; noting it as an option, not a gap. |

### 3b. Small utilities that fit minimalism

Each is one launcher mode, one rail cell, or one glyph — no new surface.

| Gap | Who has it | Cost |
| --- | --- | --- |
| **Emoji picker** | both (HyDE has glyph too) | one more launcher mode: `>emoji`. Zero new surface. |
| **Night light / gamma** | HyDE (hyprsunset, 7 temp + 9 gamma presets) | one rail toggle or `>night`. HyDE's preset matrix is overkill — one temperature and an on/off is the minimal form. |
| **Keyboard-layout indicator** | caelestia (popout + XKB pretty names) | `kb_layout = "us,cz"` is live and invisible. One rail status glyph. |
| **Caps / num lock indicator** | caelestia (animated badges) | one glyph pair; caelestia even self-registers the refresh binds. |
| **Scratchpad / drop-down terminal** | HyDE (pyprland `console`), caelestia (5 app-bound specials) | pure compositor binds + rules. No shell code. Colemak-friendly key needed. |
| **Game mode** | caelestia (`GameMode` service + toggle), HyDE (`gamemode.sh`) | `SUPER+ALT+G` already toggles animations — formalising it as one state (animations + blur + shadow off) is a small step. |

### 3c. Surfaces worth considering

Bigger than 3b, smaller than a clone.

| Gap | Who has it | Note |
| --- | --- | --- |
| **Shell-side screenshot picker** | caelestia (`areapicker`: auto-snaps to the window under the cursor, matching its border width and rounding, dimmed cut-out scrim) | qsm delegates to a script. The window-snap detail is genuinely beautiful and nothing else on the box does it. |
| **Window inspector as a user surface** | caelestia (`WindowInfo`: preview, address/size/workspace, move-to-workspace grid, kill) | qsm has `shell.qml:312 inspect()` as a dev tool only. |
| **Toasts / transient confirmations** | caelestia (4 types + `toaster` IPC) | Owner said no complicated notification centre — this is the opposite: the lightweight "theme set" / "wifi connected" ack. Still, it is a new surface. |
| **Weather forecast depth** | both (7-day + hourly) | qsm shows current conditions only. Dashboard card already exists. |
| **Notification actions in popups** | caelestia (buttons per action, copy-body, markdown links) | qsm's centre invokes on Enter; popup-side action buttons are thinner. |

## 4. Explicitly rejected

Recommendation, not decision. These import complexity the owner said no to, or duplicate what
already works.

| Rejected | Why |
| --- | --- |
| Screen recording | Owner said no. |
| Lyrics, bongocat, beat detection, cava visualiser | `MediaTab.qml:13` already records "explicitly not ported". Decoration, not function. |
| Desktop widgets (clock plate, background visualiser) | Prime law: every surface is edge-attached. |
| Nexus-scale settings app (11 pages, live-editing) | Violates the delegation law in `spec/09`. Escapes to pavucontrol / blueman / nm-connection-editor already exist. |
| Per-app volume mixer | `AudioService.qml:18-20` deliberately excludes stream nodes; pavucontrol owns mixer depth. |
| Wallbash's ~15 app targets (Discord, Spotify, VSCode, GTK, Kvantum…) | The N-theme JSON engine is a different, simpler bet. Re-theming the world is a second project. |
| 18 animation presets / 6 layout presets / 5 workflow presets | Anti-minimalist by construction. One good motion tier set beats 18. |
| 10 screen shaders (CVD sim, OLED saver, e-ink, vibrance) | Only night light has daily value; the rest are demos. |
| Glyph picker, web search, bookmarks launcher, game launcher, package-manager UI | Feature sprawl in a launcher that should stay four modes deep. |
| Session snapshots (save/restore window layouts) | Large, stateful, fragile. HyDE needs per-app plugins to make it work. |
| Window groups / scrolling layouts | Compositor concern, not shell. |
| Workspace *groups* (caelestia's ×10 blocks) | 10 workspaces is already more than gets used. |
| swaync / dunst / waybar / rofi / wlogout parity | Retired by design — the shell replaced them. |

## 5. Proposed rounds

### Round 0 — close spec debt

Everything in §2. No new features, no new keys. This is the "the spec already decided" round:
media popout, popup overflow choreography + cap 5, DND persistence, one `state.json`, install
`qalc`, run the phase-10 walkthrough.

### Round 1 — keyboard reach

Make what exists reachable without a mouse (§3a): keyboard path into the rail popouts, media
keys routed through the shell so the OSD sees them, and a keybind cheat sheet fed by
`hyprctl globalshortcuts`. Colemak keys still free on plain `SUPER`: **A, R, S, H, Q, Y, M**
plus `, . / ;` — `H` and `M` sit inside the `N/O/I/E` cluster.

### Round 2 — small utilities

§3b, each a single cell or launcher mode: `>emoji`, night light, keyboard-layout glyph,
caps/num badges, scratchpad binds, game mode as one state.

### Round 3 — surfaces

§3c, one at a time, each with its own spec section first: screenshot picker with window snap,
window inspector, toasts, weather forecast depth, popup action buttons.
