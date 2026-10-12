# caelestia — feature and keybind map

Reference material, not authority. `spec/` still wins every disagreement; this file exists so a
parity decision can be made against facts instead of memory.

Sources: `~/Clonned/caelestia/repo` (the Quickshell shell, HEAD `817a220`) and
`~/Clonned/caelestia-dots/repo` (the Hyprland config).

## A. Keybinds

Bind wiring: `hypr/hyprland/keybinds.lua`. Key strings: `hypr/variables.lua` — every `kb*` is
overridable in `~/.config/caelestia/hypr-vars.lua`. Flags: `locked` = works on the lockscreen
(`bindl`), `mouse` = `bindm`, `release` = fires on release, `repeating` = `binde`.

### Shell

| Keys | Action | Dispatcher / IPC | Category |
| --- | --- | --- | --- |
| `SUPER + SUPER_L` | Toggle launcher (press & release; `release`) | `global` → `caelestia:launcher` (`modules/Shortcuts.qml`) | launcher |
| `CTRL + ALT + Delete` | Session / power menu | `global` → `caelestia:session` | shell |
| `SUPER + N` | Toggle sidebar (notification centre) | `global` → `caelestia:sidebar` | shell |
| `CTRL + ALT + C` | Clear all notifications (`locked`) | `global` → `caelestia:clearNotifs` (`services/Notifs.qml`) | shell |
| `SUPER + K` | Show all panels (launcher + dashboard + osd + utilities) | `global` → `caelestia:showall` | shell |
| `SUPER + L` | Lock screen | `global` → `caelestia:lock` (`modules/lock/Lock.qml`) | shell |
| `SUPER + ALT + L` | Restore lockscreen (restart shell, then lock) | `exec caelestia shell -d` then `global` → `caelestia:lock` | shell |
| `CTRL + SUPER + SHIFT + R` | Kill shell (`release`) | `exec qs -c caelestia kill` | shell |
| `CTRL + SUPER + ALT + R` | Restart shell (`release`) | `exec qs -c caelestia kill; sleep .1; caelestia shell -d` | shell |
| `Caps_Lock` | Refresh Hyprland device list (`locked non_consuming ignore_mods release`) | `global` → `caelestia:refreshDevices` — registered **by the shell**, `services/Hypr.qml:92` | shell |
| `Num_Lock` | Refresh Hyprland device list (same flags, shell-registered) | `global` → `caelestia:refreshDevices` | shell |

### Workspaces

| Keys | Action | Dispatcher | Note |
| --- | --- | --- | --- |
| `SUPER + 1`…`9`, `SUPER + 0` | Go to workspace 1–10 **within the current group** | `fn.wsaction("focus","",i)` → `focus { workspace = floor((id-1)/10)*10 + i }` | one bind per digit, `0` = 10 |
| `SUPER + ALT + 1`…`0` | Move window to workspace 1–10 in current group | `fn.wsaction("move","",i)` → `window.move { workspace = … }` | per digit |
| `CTRL + SUPER + 1`…`0` | Go to workspace **group** i (×10 block) | `fn.wsaction("focus","group",i)` → `focus { workspace = (i-1)*10 + (id%10) }` | per digit |
| `CTRL + SUPER + ALT + 1`…`0` | Move window to workspace group i | `fn.wsaction("move","group",i)` | per digit |
| `SUPER + mouse_up` | Previous workspace | `focus { workspace = "-1" }` | |
| `CTRL + SUPER + Left` | Previous workspace (`repeating`) | `focus { workspace = "-1" }` | |
| `SUPER + Page_Up` | Previous workspace (`repeating`) | `focus { workspace = "-1" }` | |
| `SUPER + mouse_down` | Next workspace | `focus { workspace = "+1" }` | |
| `CTRL + SUPER + Right` | Next workspace (`repeating`) | `focus { workspace = "+1" }` | |
| `SUPER + Page_Down` | Next workspace (`repeating`) | `focus { workspace = "+1" }` | |
| `CTRL + SUPER + mouse_up` | Previous workspace group | `focus { workspace = "-10" }` | |
| `CTRL + SUPER + mouse_down` | Next workspace group | `focus { workspace = "+10" }` | |
| `SUPER + ALT + mouse_up` | Move window to previous workspace | `window.move { workspace = "-1" }` | |
| `SUPER + ALT + Page_Up` | Move window to previous workspace (`repeating`) | `window.move { workspace = "-1" }` | |
| `CTRL + SUPER + SHIFT + Left` | Move window to previous workspace (`repeating`) | `window.move { workspace = "-1" }` | |
| `SUPER + ALT + mouse_down` | Move window to next workspace | `window.move { workspace = "+1" }` | |
| `SUPER + ALT + Page_Down` | Move window to next workspace (`repeating`) | `window.move { workspace = "+1" }` | |
| `CTRL + SUPER + SHIFT + Right` | Move window to next workspace (`repeating`) | `window.move { workspace = "+1" }` | |
| `SUPER + ALT + S` | Move window to special workspace | `window.move { workspace = "special:special" }` | |
| `CTRL + SUPER + SHIFT + Up` | Move window to special workspace | `window.move { workspace = "special:special" }` | |
| `CTRL + SUPER + SHIFT + Down` | Move window out of special workspace | `window.move { workspace = "e+0" }` | |

### Window groups

| Keys | Action | Dispatcher |
| --- | --- | --- |
| `ALT + TAB` | Next window in group (`repeating`) | `window.cycle_next()` |
| `SHIFT + ALT + TAB` | Previous window in group (`repeating`) | `window.cycle_next({ next = false })` |
| `CTRL + ALT + TAB` | Next group (`repeating`) | `group.next()` |
| `CTRL + SHIFT + ALT + TAB` | Previous group (`repeating`) | `group.prev()` |
| `SUPER + Comma` | Toggle group | `group.toggle()` |
| `SUPER + SHIFT + Comma` | Lock active group | `group.lock_active()` |
| `SUPER + U` | Move window out of group | `window.move { out_of_group = true }` |

### Window actions

| Keys | Action | Dispatcher |
| --- | --- | --- |
| `SUPER + left/right/up/down` | Focus window in direction | `focus { direction = … }` |
| `SUPER + SHIFT + left/right/up/down` | Move window in direction | `window.move { direction = … }` |
| `SUPER + Minus` / `SUPER + ALT + Left` | Width −10% (`repeating`) | `fn.resize_active_window(-10, 0)` |
| `SUPER + Equal` / `SUPER + ALT + Right` | Width +10% (`repeating`) | `fn.resize_active_window(10, 0)` |
| `SUPER + SHIFT + Minus` / `SUPER + ALT + Up` | Height −10% (`repeating`) | `fn.resize_active_window(0, -10)` |
| `SUPER + SHIFT + Equal` / `SUPER + ALT + Down` | Height +10% (`repeating`) | `fn.resize_active_window(0, 10)` |
| `SUPER + Z`, `SUPER + mouse:272` | Move window by drag (`mouse`) | `window.drag()` |
| `SUPER + X`, `SUPER + mouse:273` | Resize window by drag (`mouse`) | `window.resize()` |
| `CTRL + SUPER + Backslash` | Center window | `window.center()` |
| `CTRL + SUPER + ALT + Backslash` | Normalize — resize to 55%×70% of screen, then center | `window.resize(fn.resize_by_screen(55,70))` + `window.center()` |
| `SUPER + ALT + Backslash` | Picture-in-picture — float, shrink to ¼ monitor height, move bottom-right, pin | `window.float()` + `fn.move_actions()` + `window.pin { action = "on" }` |
| `SUPER + P` | Pin window | `window.pin()` |
| `SUPER + F` | Fullscreen | `window.fullscreen { mode = "fullscreen" }` |
| `SUPER + ALT + F` | Maximize (bordered) | `window.fullscreen { mode = "maximized" }` |
| `SUPER + ALT + Space` | Toggle floating | `window.float()` |
| `SUPER + Q` | Close window | `window.close()` |

### Special workspaces (scratchpads)

| Keys | Action | Apps spawned |
| --- | --- | --- |
| `SUPER + S` | Toggle special workspace — closes any open special, else opens `special` | `fn.toggle("specialws")` → `workspace.toggle_special(…)` |
| `CTRL + SHIFT + Escape` | System monitor | `foot -a btop … exec btop` |
| `SUPER + M` | Music | spotify (`spicetify watch -s`), feishin |
| `SUPER + D` | Communication | discord, whatsapp |
| `SUPER + R` | Todo | todoist |

App placement comes from the `toggles` object in `~/.config/caelestia/cli.json`, read by
`hypr/utils/functions.lua:205`.

### Apps

| Keys | Action | Command (`variables.lua` default) |
| --- | --- | --- |
| `SUPER + T` | Terminal | `foot` |
| `SUPER + W` | Browser | `firefox` |
| `SUPER + C` | Editor | `codium` |
| `SUPER + E` | File explorer | `thunar` |
| `CTRL + ALT + V` | Audio settings | `pwvucontrol` |

### Utilities

| Keys | Action | Dispatcher / IPC |
| --- | --- | --- |
| `Print` | Screenshot (`locked`) | `exec caelestia screenshot` |
| `SUPER + SHIFT + S` | Screenshot, freeze mode | `global` → `caelestia:screenshotFreeze` (`modules/areapicker/AreaPicker.qml`) |
| `SUPER + SHIFT + ALT + S` | Screenshot, region picker | `global` → `caelestia:screenshot` |
| `CTRL + ALT + R` | Record fullscreen | `exec caelestia record` |
| `SUPER + ALT + R` | Record with sound | `exec caelestia record -s` |
| `SUPER + SHIFT + ALT + R` | Record region | `exec caelestia record -r` |
| `SUPER + SHIFT + C` | Colour picker | `exec hyprpicker -a` |
| `SUPER + V` | Clipboard history | `exec pkill fuzzel \|\| caelestia clipboard` |
| `SUPER + ALT + V` | Clipboard history, delete mode | `exec pkill fuzzel \|\| caelestia clipboard -d` |
| `SUPER + Period` | Emoji picker | `exec pkill fuzzel \|\| caelestia emoji -p` |
| `CTRL + SHIFT + ALT + V` | Paste latest clipboard entry (`locked`) | `exec sleep 0.5s && ydotool type -d 1 "$(cliphist list \| head -1 \| cliphist decode)"` |
| `SUPER + ALT + F12` | Test notification with 2 actions | `exec notify-send … -A 'Test1=…' -A 'Test2=…'` |

### Levels, media, power

| Keys | Action | Dispatcher / IPC |
| --- | --- | --- |
| `XF86MonBrightnessUp` | Brightness up (`locked`) | `global` → `caelestia:brightnessUp` (`services/Brightness.qml`) |
| `XF86MonBrightnessDown` | Brightness down (`locked`) | `global` → `caelestia:brightnessDown` |
| `CTRL + SUPER + Space`, `XF86AudioPlay`, `XF86AudioPause` | Play/pause (`locked`) | `global` → `caelestia:mediaToggle` (`services/Players.qml`) |
| `CTRL + SUPER + Equal`, `XF86AudioNext` | Next track (`locked`) | `global` → `caelestia:mediaNext` |
| `CTRL + SUPER + Minus`, `XF86AudioPrev` | Previous track (`locked`) | `global` → `caelestia:mediaPrev` |
| `CTRL + SUPER + Backspace`, `XF86AudioStop` | Stop playback (`locked`) | `global` → `caelestia:mediaStop` |
| `SUPER + SHIFT + M`, `XF86AudioMute` | Mute sink (`locked`) | `exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` |
| `XF86AudioMicMute` | Mute source (`locked`) | `exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` |
| `XF86AudioRaiseVolume` | Volume +10%, capped at 100 (`locked repeating`) | `exec wpctl set-mute … 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 10%+` |
| `XF86AudioLowerVolume` | Volume −10% (`locked repeating`) | `exec wpctl set-mute … 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-` |
| `SUPER + SHIFT + L` | Sleep (`locked`) | `exec systemctl suspend-then-hibernate` |

Note: volume/mute go through `wpctl` directly, NOT through the shell — the opposite of the qsm
law that level keys route through the shell so the OSD sees them. Brightness and media DO go
through the shell.

### Touchpad gestures — `hypr/hyprland/gestures.lua`

| Gesture | Action |
| --- | --- |
| 4-finger horizontal swipe | Switch workspace (creates new at the end) |
| 3-finger swipe up | Open special workspace `special` |
| 3-finger swipe down | Toggle special workspace (`fn.toggle("specialws")`) |
| 4-finger swipe down | Sleep (`systemctl suspend-then-hibernate`) |

### Shell shortcuts with NO dots keybind

Declared but unbound in the shipped config: `caelestia:nexus`, `caelestia:dashboard`,
`caelestia:utilities`, `caelestia:launcherInterrupt`, `caelestia:screenshotClip`,
`caelestia:screenshotFreezeClip`, `caelestia:unlock`. All under appid `caelestia`
(`components/misc/CustomShortcut.qml`).

## B. Shell IPC surface

`caelestia shell <target> <function> [args]` or `qs -c caelestia ipc call <target> <function>`.
List it with `caelestia shell -s`.

| target | function | what it does |
| --- | --- | --- |
| `drawers` | `toggle(drawer)` | Toggle a drawer on the focused screen. Names from `components/ScreenState.qml`: `bar`, `osd`, `session`, `launcher`, `dashboard`, `utilities`, `sidebar`. `launcher`/`session`/`dashboard` refused while a fullscreen window is focused; unknown name warns. |
| `drawers` | `list()` | Newline list of every boolean drawer on the focused screen. |
| `drawers` | `isOpen(drawer)` | `"1"` / `"0"` / `"unknown"`. |
| `nexus` | `open()` | Open the Nexus settings window. |
| `toaster` | `info/success/warn/error(title, message, icon)` | Emit a toast of that type. |
| `picker` | `open()` / `openFreeze()` / `openClip()` / `openFreezeClip()` | Screenshot region picker: live or frozen frame, to file or straight to clipboard. |
| `lock` | `lock()` / `unlock()` / `isLocked()` | Session lock control and state. |
| `audio` | `cycleOutput()` | Switch to the next PipeWire sink. |
| `brightness` | `get()` / `getFor(query)` | Brightness 0–1 for the active monitor, or for `active` / `model:X` / `serial:X` / `id:N` / name; `-1` if unknown. |
| `brightness` | `set(value)` / `setFor(query, value)` | brightnessctl-style values: `0.1`, `+0.1`, `0.1-`, `10%`, `+10%`, `10%-`. Returns confirmation or parse error. |
| `gameMode` | `isEnabled()` / `toggle()` / `enable()` / `disable()` | Kills animations/blur/shadow/gaps/rounding, enables tearing; `disable` issues a Hyprland `reload`. |
| `hypr` | `refreshDevices()` | Re-read Hyprland devices (caps/num lock, kb layout). |
| `hypr` | `cycleSpecialWorkspace(direction)` / `listSpecialWorkspaces()` | Cycle / list special workspaces holding ≥1 window. |
| `idleInhibitor` | `isEnabled()` / `toggle()` / `enable()` / `disable()` | Wayland idle inhibit. |
| `notifs` | `clear()` | Close every notification. |
| `notifs` | `isDndEnabled()` / `toggleDnd()` / `enableDnd()` / `disableDnd()` | Do-not-disturb. |
| `mpris` | `getActive(prop)` / `list()` | Read any property off the active player (e.g. `trackTitle`); list player identities with config aliases applied. |
| `mpris` | `play/pause/playPause/previous/next/stop()` | Capability-checked transport. |
| `wallpaper` | `get()` / `set(path)` / `list()` | Current wallpaper, set via `caelestia wallpaper -f`, list discovered paths. |

Declaration sites: `modules/Shortcuts.qml:111,138,146`, `modules/areapicker/AreaPicker.qml:50`,
`modules/lock/Lock.qml:59`, `services/Audio.qml:185`, `services/Brightness.qml:111`,
`services/GameMode.qml:57`, `services/Hypr.qml:199`, `services/IdleInhibitor.qml:37`,
`services/Notifs.qml:144`, `services/Players.qml:137`, `services/Wallpapers.qml:69`.

## C. Features

### Root / lifecycle

- Root scope wiring fonts, services, background, drawers, picker, lock, toasts, shortcuts, battery + idle monitors — `shell.qml`
- Live config reload with watched files and a GitHub crash-report URL — `shell.qml` (`settings.watchFiles: true`)
- Bundled Google Sans Flex variable font loader — `modules/GSFLoader.qml`
- Eager start of IdleInhibitor / GameMode / Notifs / Players / Brightness / Weather / VPN so features work on the first keypress — `modules/ServiceLoader.qml`
- Config feedback toasts: loaded / parse-failed / save-failed / unknown-option, for `shell.json` and `shell-tokens.json` — `modules/ConfigToasts.qml`
- Battery warn-level toasts and auto-hibernate at `general.battery.criticalLevel` — `modules/BatteryMonitor.qml`
- Idle timeout chain: per-entry `lock` / `unlock` / `dpms off|on` / Hyprland dispatch / arbitrary command, with audio- and charging-inhibits, lock-before-sleep, logind lock/unlock handling — `modules/IdleMonitors.qml`

### Bar (vertical, left edge)

- Animated left-edge bar: sliver ↔ full width, persistent / state-toggled / hover-revealed, Wayland exclusive zone, per-screen regex exclusion, hides on fullscreen — `modules/bar/BarWrapper.qml`
- User-ordered, per-entry-enabled entry list: `spacer`, `logo`, `workspaces`, `activeWindow`, `tray`, `clock`, `statusIcons`, `power` — `modules/bar/Bar.qml`
- Distro/Caelestia logo button; click toggles the launcher — `modules/bar/components/OsIcon.qml`
- Workspace pill column with paging, per-monitor mode, swap to special-workspace list; click focuses, click-active toggles `special` — `modules/bar/components/workspaces/Workspaces.qml`
- Per-workspace label (number / name initial, configurable label + capitalisation) with stacked app-category window icons — `.../workspaces/Workspace.qml`
- Animated active-workspace indicator pill with optional "active trail" stretch — `.../workspaces/ActiveIndicator.qml`
- Grouped rounded backgrounds spanning contiguous occupied workspaces — `.../workspaces/OccupiedBg.qml`
- Scrollable special-workspace strip: drag to scroll, tap to toggle — `.../workspaces/SpecialWorkspaces.qml`
- Rotated elided active-window title + icon; compact mode strips the leading `App —` prefix; cross-fades on change — `modules/bar/components/ActiveWindow.qml`
- System tray column with optional pill background, icon recolouring, compact collapse behind a chevron, `hiddenIcons` filter — `modules/bar/components/Tray.qml`
- Tray item: left-click activate, right-click secondary activate — `modules/bar/components/TrayItem.qml`
- Vertical clock: stacked hour/minute, optional icon, weekday + day, AM/PM, optional pill — `modules/bar/components/Clock.qml`
- Status icon stack (ordered/enabled): `lockStatus`, `audio`, `microphone`, `kbLayout`, `network`, `bluetooth`, `battery` — `modules/bar/components/StatusIcons.qml`
- Battery level/charging icon, red under 20%; power-profile icon on desktops — `.../status/BatteryStatus.qml`
- Bluetooth adapter icon + one icon per connected device, pulsing while connecting — `.../status/BluetoothStatus.qml`
- Caps-lock / num-lock badges animating in and out — `.../status/LockStatus.qml`
- Red power button opening the session menu — `modules/bar/components/Power.qml`
- Bar scroll actions: workspaces over the workspace entry, volume on the top half, brightness on the bottom half — `modules/bar/Bar.qml:78`

### Bar popouts

- Popout host with hover-driven show, Escape to close, and "detach" into a floating WindowInfo or full Nexus window under a focus grab — `modules/bar/popouts/Wrapper.qml`
- Slide/clip positioning that centres the popout on the hovered bar item — `.../ClipWrapper.qml`
- Registry: `activewindow`, `network`, `wirelesspassword`, `bluetooth`, `battery`, `audio`, `kblayout`, `lockstatus`, `traymenu<N>` — `.../Content.qml`
- Active window: icon, title, class, live screencopy preview, detach to WindowInfo — `.../ActiveWindow.qml`
- Network: Wi-Fi enable, top-8 APs with connect/disconnect + spinner, rescan with progress, ethernet per-interface connect/disconnect — `.../Network.qml`
- Wi-Fi password dialog: masked field, connecting state, failure message, auto-forget of the failed profile — `.../WirelessPassword.qml`
- Bluetooth: Enabled + Discovering switches, top-5 devices with battery, connect/forget, "Open settings" → Nexus — `.../Bluetooth.qml`
- Battery: remaining %, time-to-empty/full, "Performance Degraded" reason banner, 3-way power-profile selector — `.../Battery.qml`
- Audio: output + input device radio lists, volume slider (scroll adjusts), "Open settings" → Nexus — `.../AudioPopout.qml`
- Keyboard layout: click to switch, 5th+ entry disabled with "XKB limitation: maximum 4 layouts allowed" — `.../kblayout/KbLayout.qml`; names resolved via `xmllint` over `base.xml`/`evdev.xml`, switching via `hyprctl switchxkblayout` — `.../kblayout/KbLayoutModel.qml`
- Lock keys: "Capslock: Enabled/Disabled", "Numlock: …" — `.../LockStatus.qml`
- Native SNI tray menu with icons, separators, disabled items, push/pop submenus — `.../TrayMenu.qml`
- Shared popout name/visibility state + `detachRequested` signal — `.../PopoutState.qml`

### Dashboard (top edge, 4 tabs)

- Top drop-down panel; owns the profile-picture file picker that copies to `~/.face` and notifies — `modules/dashboard/Wrapper.qml`
- Tab host with horizontal flick/drag between tabs and snap — `.../Content.qml`
- Icon+label tab bar with sliding underline; click to switch, scroll to move next/prev — `.../Tabs.qml`
- **Dash tab** card grid — `.../Dash.qml`
  - User card: profile picture with hover-edit overlay, distro logo gem, uptime badge, WM chip — `.../dash/User.qml`
  - Small weather: icon, temperature, description; refreshes on open — `.../dash/SmallWeather.qml`
  - Large stacked hour • • • minute clock with optional AM/PM — `.../dash/DateTime.qml`
  - Month calendar: weekend colouring, animated today marker; ‹ › month nav, label-click jumps to today, scroll changes month, middle-click resets — `.../dash/Calendar.qml`
  - Three circular gauges: CPU, memory, storage — `.../dash/Resources.qml`
  - Now-playing card: cover in a wavy progress arc, prev/play-pause/next, beat-synced bongocat GIF driven by detected BPM — `.../dash/Media.qml`
- **Media tab** with "Nothing playing" empty state — `.../Media.qml`
  - Cookie-shaped cover art ringed by a radial CAVA spectrum — `.../media/CoverVisualiser.qml`
  - Ambient drifting Material shapes that animate only while playing — `.../media/BackgroundShapes.qml`
  - Title/artist/album, seekable wavy position slider with times, shuffle / prev / play-pause / next / repeat (off→track→playlist) — `.../media/Details.qml`
  - Lyrics header + info button + MPRIS player picker split-button — `.../media/LyricsAndSelector.qml`
  - Auto-scrolling synced lyrics with current-line glow; click a line to seek — `.../media/LyricList.qml`
  - Lyrics info blob: backend, selected candidate, offset (ms) — `.../media/LyricsInfo.qml`
- **Performance tab** with an all-widgets-off placeholder — `.../Performance.qml`
  - CPU/GPU hero cards: model, usage ring, load-morphing shape, temperature with >90 °C warning — `.../performance/HeroCard.qml`
  - Memory ring with % and used/total — `.../performance/MemoryCard.qml`
  - Storage ring with used/total and a disk-picker split-button — `.../performance/StorageCard.qml`
  - Dual-line up/down sparkline plus live speeds and session totals — `.../performance/NetworkCard.qml`
  - Battery "tank" filling to charge level with charging bolt and remaining text — `.../performance/BatteryTank.qml`
- **Weather tab**: city + date, sunrise/sunset, current-conditions card, humidity/feels-like/wind cards, 7-day forecast row — `.../WeatherTab.qml`

### Launcher (bottom, slide-up)

- Slide-up drawer height-clamped against an open dashboard; preloads the app DB at startup — `modules/launcher/Wrapper.qml`
- Search bar (`Type ">" for commands`), Up/Down + Enter + Esc, optional vim keys (`Ctrl+J/N`, `Ctrl+K/P`, `Tab`/`Shift+Tab`) — `.../Content.qml`
- Cross-fade between app list and wallpaper carousel with distinct empty states — `.../ContentList.qml`
- `maxShown` (7) rows with animated highlight and mode-switch transition — `.../AppList.qml`
- App items: icon, name, comment/genericName, favourite heart; frequency-ranked via a SQLite `AppDb`; `hiddenApps` regex filter; terminal apps launch through `assets/wrap_term_launch.sh` — `.../items/AppItem.qml`, `.../services/Apps.qml`
- App-search prefixes (`launcher.specialPrefix`, default `@`): `@i` id, `@c` categories, `@d` comment, `@e` exec, `@w` window class, `@g` generic name, `@k` keywords, `@t` terminal-only — `.../services/Apps.qml`
- Action mode (`launcher.actionPrefix`, default `>`) with 13 default actions — `.../services/Actions.qml`, defaults in `plugin/src/Caelestia/Config/launcherconfig.hpp`: Calculator, Scheme, Wallpaper, Variant, Random, Light, Dark, Shutdown\*, Reboot\*, Logout\*, Lock, Sleep, Settings (\* dangerous, hidden unless `enableDangerousActions`)
- `>calc <expr>` live Qalculate evaluation; Enter copies via `wl-copy`; chip opens `terminal → fish -C exec qalc -i '<expr>'` — `.../items/CalcItem.qml`
- `>scheme <q>` picker from `caelestia scheme list` with two-tone preview → `caelestia scheme set -n <name> -f <flavour>` — `.../services/Schemes.qml`, `.../items/SchemeItem.qml`
- `>variant <q>` 9 M3 variants → `caelestia scheme set -v <variant>` — `.../services/M3Variants.qml`, `.../items/VariantItem.qml`
- `>wallpaper <q>` horizontal thumbnail carousel with live colour preview on highlight — `.../WallpaperList.qml`, `.../items/WallpaperItem.qml`
- Action verbs: `autocomplete <sub>`, `setMode light|dark`, logind verbs (`logout`/`poweroff`/`reboot`/`hibernate`/`suspendThenHibernate`), else `execDetached` — `.../items/ActionItem.qml`
- Per-source fuzzy/fzf toggle (apps, actions, schemes, variants, wallpapers) — `utils/Searcher.qml`

### Notifications (popups)

- Top-right popup stack, sidebar-matched width — `modules/notifications/Wrapper.qml`
- Stack height clamped against OSD/session/utilities; "+N more" chips at top and bottom; dismissed cards fly off sideways — `.../Content.qml`
- Card interactions: horizontal swipe/drag to dismiss (`clearThreshold`), vertical drag to expand/collapse (`expandThreshold`), middle-click closes, left-click invokes the single action when `actionOnClick`, hover pauses auto-dismiss — `.../Notification.qml`
- Expanded card: app name, full Markdown body with clickable links, close button, one button per action, copy-body button that flips to a tick for 3 s — `.../Notification.qml`
- Avatar = image + app-icon badge / app icon / urgency icon; critical urgency colouring; `hints.value` progress ring — `.../Notification.qml`

### Sidebar (notification centre, right edge)

- Full-height right sidebar sliding in from the right — `modules/sidebar/Wrapper.qml`, `.../Content.qml`
- Animated "N notification(s)" header, "All up to date!" empty state, floating `clear_all` button that staggered-clears group by group — `.../NotifDock.qml`
- Group gestures: horizontal drag clears the group, right-click toggles expand, middle-click clears group, vertical drag expands/collapses — `.../NotifDockList.qml`
- Per-notification gestures: horizontal drag dismisses one, middle-click closes one, right-click/vertical drag toggles the group — `.../NotifGroupList.qml`
- Grouped-by-app card: avatar with badge, app name, relative time, count pill with rotating chevron, critical colouring — `.../NotifGroup.qml`
- Collapsed one-line summary + expanded card with timestamp and Markdown body — `.../Notif.qml`
- Flickable action strip with fade edges: close, action chips (icon or text, respects `hasActionIcons`), copy-body chip — `.../NotifActionList.qml`
- Persisted expanded-group set across reloads — `.../Props.qml`

### OSD (right edge)

- Slides in on any volume/mute/mic/brightness change, auto-hides after `osd.hideDelay` unless hovered, shifts left for sidebar/session, suppressed while utilities is open — `modules/osd/Wrapper.qml`
- Three vertical filled sliders, each scroll-adjustable and draggable: speaker volume (always), microphone (`osd.enableMicrophone`), per-monitor brightness (`osd.enableBrightness`) — `.../Content.qml`

### Session (power menu, right edge)

- Right-edge column sliding in, shifting left for the sidebar — `modules/session/Wrapper.qml`
- Four buttons around a centred animated GIF: Logout, Shutdown, [GIF], Hibernate, Reboot; Up/Down + Enter + Esc, optional vim keys; icons/commands overridable; routes through logind SessionManager with `execDetached` fallback — `.../Content.qml`

### Utilities (bottom-right quick panel)

- Slides up bottom-right, morphs to sidebar width when the sidebar is open, hidden under the session menu; persists card expansion and chosen recording mode — `modules/utilities/Wrapper.qml`, `.../Content.qml`
- Concave blob path fusing the panel with the sidebar — `.../Background.qml`
- Keep Awake card: switch + "Active since HH:MM" chip — `.../cards/IdleInhibit.qml`
- Screen recorder card: SplitButton with 4 modes (fullscreen, region `-r`, fullscreen+sound `-s`, region+sound `-sr`), blinking REC/PAUSED pill, elapsed timer, pause/stop — `.../cards/Record.qml`
- Recordings list: collapsible newest-first `recording_*.mp4` list with play / open-folder / delete per row — `.../cards/RecordingList.qml`
- Delete confirmation modal with scrim, Cancel/Delete, click-outside cancels — `.../RecordingDeleteModal.qml`
- Quick toggles (configurable, deduped, reflows past 6): wifi, bluetooth, mic, settings, gameMode, dnd, vpn — `.../cards/Toggles.qml`
- Toast stack above the panel, capped at `maxToasts`, fullscreen policy all/important/none, click anywhere dismisses — `.../toasts/Toasts.qml`
- Four toast types with distinct colour/icon: Info, Success, Warning, Error — `.../toasts/ToastItem.qml`

### Lock screen

- Wayland session lock with pre-warmed screencopy so the blurred backdrop works when locked — `modules/lock/Lock.qml`
- Blurred wallpaper or live screen-copy backdrop; lock icon spins 360° and expands into the panel — `.../LockSurface.qml`
- Three-column layout: weather/fetch/media | clock+auth | resources/notifications — `.../Content.qml`
- Centre column: big clock, date line, profile picture, password input, state message; scales down below 1440p — `.../Center.qml`
- Huge hour/minute clock with AM/PM chip in 12-hour mode — `.../center/Clock.qml`
- `~/.face` profile picture masked into a ClamShell shape with `person` fallback — `.../center/ProfilePic.qml`
- Password pill: leading icon reflects the auth method (fingerprint/face/lock/fingerprint_off) and spins while authenticating; trailing dot morphs into a submit arrow — `.../center/PasswordInput.qml`
- Typed characters pop in as random Material shapes settling into circles; cycling placeholders — `.../center/InputField.qml`
- State messages: per-method and global auth errors, plus Caps/Num lock and non-default keyboard layout status — `.../center/StateMessage.qml`
- PAM password + optional fingerprint (`fprintd-list`, auto-retry) + optional Howdy face unlock (Enter on empty buffer; auto on wake), per-method try counters — `.../Pam.qml`
- Now-playing card with blurred art and prev/play-pause/next — `.../Media.qml`
- Notification dock with grouped list, expand-beyond-preview, "No Notifications" / "Unlock for Notifications" states — `.../NotifDock.qml`, `.../NotifGroup.qml`
- CPU/RAM/disk in Pentagon/Slanted/Gem shapes with wavy fill; red temp badge above 90 °C — `.../Resources.qml`
- Neofetch-style card: distro logo, OS/WM/USER/UP/BATT lines, terminal colour swatches — `.../Fetch.qml`
- Weather card auto-refreshing every 15 min, forecast only on tall screens — `.../WeatherInfo.qml`
- Brief weather info: description, temperature + condition icon, feels-like, high/low — `.../weather/BriefInfo.qml`
- Hourly forecast strip with Cookie4Sided temp shapes, precipitation %, "Now" label — `.../weather/Forecast.qml`

### Drawers / frame / gestures

- Per-screen border exclusions so tiled windows sit inside the shell frame — `modules/drawers/Exclusions.qml`
- Layout and stacking of every drawer, including how session/OSD/toasts shift for the sidebar — `.../Panels.qml`
- Animation-aware input-mask maths so clicks pass through the frame but land on panels — `.../Regions.qml`
- Hover-to-open for OSD, dashboard, utilities, launcher, sidebar, bar and popouts — `.../Interactions.qml`
- Edge drag/swipe gestures per panel with individual `dragThreshold`s; scroll over the bar forwarded to it; "shortcut mode" keeps keybind-opened panels open; all disabled on fullscreen — `.../Interactions.qml`
- Rounded blob frame that squishes as panels slide, drop shadow, session scrim, auto-hide on fullscreen, click-outside close via `HyprlandFocusGrab` — `.../ContentWindow.qml`

### Background / wallpaper

- Per-monitor background layer hosting wallpaper, visualiser and desktop clock — `modules/background/Background.qml`
- Cross-fading wallpaper with a "Wallpaper missing?" panel and file picker — `.../Wallpaper.qml`
- Desktop CAVA bar visualiser along the bottom, optional auto-hide when a window is present, optional wallpaper blur — `.../Visualiser.qml`
- Desktop clock in 9 positions, optional translucent plate with wallpaper blur, optional shadow, `invertColors`, `scale` — `.../DesktopClock.qml`

### Area picker / screenshot

- Per-screen overlay with exclusive keyboard focus, 4 modes (live/freeze × file/clipboard) — `modules/areapicker/AreaPicker.qml`
- Crosshair picker that auto-snaps to the window under the cursor (matching its border width and rounding), free-region drag, dimmed cut-out scrim, Esc cancels; result to `swappy -f` or `wl-copy --type image/png` + `notify-send` — `.../Picker.qml`

### Window info

- Window inspector: live preview + details + actions — `modules/windowinfo/WindowInfo.qml`
- Live screencopy thumbnail with "`<title>` on monitor `<name>` at x, y" caption — `.../Preview.qml`
- Detail rows: Address, Position, Size, Workspace, Monitor, Initial title/class, PID, Floating, Xwayland, Pinned, Fullscreen — `.../Details.qml`
- "Move to workspace" 5×2 grid, Tile/Float toggle, Pin/Unpin, red Kill — `.../Buttons.qml`

### Nexus (settings app)

- Settings shell with blob background, nav pane + page area, pip/close corner button — `modules/nexus/Nexus.qml`
- Standalone floating window titled "Nexus — `<page>`" with per-screen theming — `.../WindowFactory.qml`
- Cross-page state: current page, sub-page back-stack, search, selections — `.../NexusState.qml`
- "Search settings" bar + category-grouped nav list with icon chip, label, description — `.../NavPane.qml`, `.../navpane/NavLocations.qml`
- Page loader with directional fade+slide; per-page sub-page stack with push/pop — `.../Pages.qml`, `.../common/StackPage.qml`
- Authoritative 11-page list — `.../PageRegistry.qml`; page→component mapping and "under construction" fallback — `.../PageCompRegistry.qml`
  - **Wallpaper & style**: wallpaper preview, Wallpapers/Colours buttons, Display wallpaper / Transparency / Dark theme toggles — `pages/WallpaperAndStyle.qml`; wallpaper grid with Browse/Random/Featured and folder categories — `wallandstyle/WallpaperSelect.qml`, `WallpaperCategory.qml`; Colours placeholder — `ColourSelect.qml`
  - **Network**: ethernet section, Wi-Fi on/off, live-rescan list, Show all / Saved / Add network, VPN provider list with status + ping and Add provider — `pages/NetworkPage.qml`; sub-pages `network/EthernetDetailPage.qml` (connect, info rows, IPv4 DHCP/DNS-only/Manual), `AddNetworkPage.qml` (hidden SSID, security select, 8-char validation), `NetworkDetailPage.qml` (Forget/Disconnect, autoconnect, IPv4), `AddVpnPage.qml` (built-in autofill, interface, custom commands), `AllNetworksPage.qml` (tri-state filter chips), `SavedNetworksPage.qml`
  - **Connected devices**: Bluetooth on/off, saved devices with tap-to-connect + battery, Pair new device, Discoverable/Pairable — `pages/BluetoothPage.qml`; `bluetooth/BtDeviceInfo.qml` (Forget, Trusted/Blocked/Wake, battery, MAC), `BluetoothPairing.qml`
  - **Audio**: output/input volume sliders + mute + device lists, App volumes row — `pages/AudioPage.qml`; per-app sliders — `audio/AppVolumes.qml`
  - **Updates**, **Plugins**: not implemented — placeholders in `PageCompRegistry.qml`
  - **Panels**: nav into Dashboard/Taskbar/Launcher/Sidebar/Utilities — `pages/PanelsPage.qml`; `panels/DashboardPanel.qml` (enabled, hover, 4 tabs, 6 perf widgets, drag threshold), `TaskbarPanel.qml` (persistent, hover, drag, component nav, 3 scroll actions), `LauncherPanel.qml` (action prefix validation, max items/wallpapers, vim keys, dangerous actions, 5 fuzzy toggles), `SidebarPanel.qml`, `UtilitiesPanel.qml` (3 cards, 7 quick toggles); taskbar sub-pages `taskbar/BarWorkspaces.qml`, `BarActiveWindow.qml`, `BarTray.qml`, `BarStatusIcons.qml` (drag-to-reorder editor + Add entry), `BarClock.qml`
  - **Apps**: default Terminal/Audio/Playback/File-manager pickers + All apps — `pages/AppsPage.qml`; `apps/AllApps.qml`, `AppInfo.qml` (Favourite/Hidden toggles, App ID, Command)
  - **Services**: poll intervals, lyrics backend, default player, volume/brightness/max-volume steps, visualiser bars, smart scheme, GPU override — `pages/ServicesPage.qml`; notifications + toast-event matrix — `services/NotificationsPage.qml`
  - **Language & region**: system language, weather-location placeholder, °C/°F units, 12/24-hour clock — `pages/LanguageAndRegion.qml`
  - **About**: animated logo + version, Hostname/Device/Distro/Kernel/Firmware, Shell/CLI/Quickshell/Qt versions, plugin count — `pages/AboutPage.qml`
- Shared settings widgets under `modules/nexus/common/`: `ToggleRow`, `SliderRow` (scroll-adjustable), `StepperRow`, `SelectRow`, `TextFieldRow`, `RowButton`/`NavRow`, `InfoRow`, `SectionHeader`, `ConnectedRect`, `ItemList`, `NetworkList`, `EthernetSection`, `AudioDeviceList`, `ListEditor` (press-and-drag reorder), `WallItem`, `PopupRow`/`BlobPopup`/`DialogRowButton`/`DialogSelectButton`, `AnimatedLogo`

### `services/` capabilities

- **Audio** — PipeWire sink/source/stream volume + mute, output cycling, hosts the Cava visualiser and beat tracker; volume capped at `services.maxVolume`; sink/source-change toasts — `services/Audio.qml`
- **Brightness** — per-monitor backlight across three backends: `brightnessctl` (internal), `ddcutil` (DDC/CI, 500 ms rate-limited queue), `asdbctl` (Apple Studio Display); monitor query by active/model/serial/id/name — `services/Brightness.qml`
- **Colours** — Material 3 scheme provider: ~90 role colours + 16 terminal colours, transparency/layering maths, auto-contrast `on()`, wallpaper luminance, live reload from `~/.local/state/caelestia/scheme.json`, pushes matching Hyprland `layer_rule` blur/ignore_alpha — `services/Colours.qml`
- **GameMode** — one toggle killing animations/blur/shadow/gaps/rounding and enabling tearing; state derived from live Hyprland options — `services/GameMode.qml`
- **Hypr** — Hyprland facade: workspaces/monitors/toplevels, caps/num lock, keyboard layout (XKB rules parsed for pretty names), special-workspace cycling, raw-event routing, self-registers the Caps_Lock/Num_Lock refresh binds — `services/Hypr.qml`
- **IdleInhibitor** — Wayland idle inhibit with `enabledSince` timestamp, persisted — `services/IdleInhibitor.qml`
- **NetworkUsage** — throughput + session totals with 30-sample sparkline history from `/proc/net/dev`, ref-counted polling, 64-bit counter-wrap handling — `services/NetworkUsage.qml`
- **Nmcli** — full NetworkManager front-end: scan/connect/forget/hidden SSID, saved-profile + security introspection, autoconnect and PSK-flag management, ethernet connect/disconnect with link speed and data usage, IPv4 DHCP/manual/custom-DNS editing; driven by a long-lived `nmcli monitor`; heuristic password-required detection — `services/Nmcli.qml`
- **VPN** — multi-provider adapter engine: WireGuard, Cloudflare WARP, NetBird, Tailscale, plus user-defined providers; connect/disconnect/toggle, auth-URL extraction, WARP self-registration, provider switching, live bytes/ping/server stats — `services/VPN.qml`
- **Notifs** — freedesktop notification server with actions, markup, hyperlinks, images and persistence; DND; history at `~/.local/state/caelestia/notifs.json` — `services/Notifs.qml`
- **NotifData** — per-notification model: adaptive relative-time, expiry policy, action list, disk image caching to `~/.cache/caelestia/imagecache/notifs` — `services/NotifData.qml`
- **Players** — MPRIS aggregation with active-player selection, config aliases, YouTube art fallback, media keys, now-playing toasts — `services/Players.qml`
- **Recorder** — start/stop/pause with elapsed timer, every action gated behind a `pidof gpu-screen-recorder` liveness probe — `services/Recorder.qml`
- **Screens** — screen filtering by per-monitor `enabled` config — `services/Screens.qml`
- **ShellState** — per-screen drawer state (`bar`, `osd`, `session`, `launcher`, `dashboard`, `utilities`, `sidebar` + `dashboardTab`, `dashboardDate`) and the live-component registry — `services/ShellState.qml`, `components/ScreenState.qml`
- **Time** — shared second-precision clock with 12/24-hour split components — `services/Time.qml`
- **Wallpapers** — searchable recursive wallpaper model, set/random/preview with live dynamic-scheme colour preview — `services/Wallpapers.qml`
- **Weather** — current conditions, 7-day and hourly forecast via Open-Meteo, geolocation via ip-api (with full rate-limit handling) and Nominatim/Open-Meteo geocoding, city cache — `services/Weather.qml`
- **Utils** — icon resolution for apps/network/bluetooth/weather/notifs/volume/battery/tray/special-ws (`utils/Icons.qml`), XDG paths (`utils/Paths.qml`), fuzzy/fzf search base (`utils/Searcher.qml` + `utils/scripts/fuzzysort.js`, `fzf.js`), regex-list matcher (`utils/Strings.qml`), image type checks (`utils/Images.qml`), fastfetch-style system facts (`utils/SysInfo.qml`), shared Wi-Fi connect flow (`utils/NetworkConnection.qml`)

### C++ plugin capabilities — `plugin/src/Caelestia/`

- `CUtils` (version, item save, file ops, item-tree lookup) — `cutils.cpp`; wallpaper luminance/dominant colour — `imageanalyser.cpp`; Qalculate calculator — `qalculator.cpp`; HTTP with response metadata — `requests.cpp`; shell-wide `Toast`/`Toaster` — `toaster.cpp`; SQLite app-launch frequency DB — `appdb.cpp`
- Config system: `GlobalConfig` + per-section objects, per-monitor overrides, design tokens, M3 easing curves, variable-font builder — `Config/`
- Services: Cava visualiser (`Services/cavaprovider.cpp`), aubio beat detection (`beattracker.cpp`), PipeWire capture (`audiocollector.cpp`), CPU/GPU/memory/storage/disk sensors (`cpu.cpp`, `gpu.cpp`, `memory.cpp`, `storage.cpp`, `diskinfo.cpp`, `sensorslib.cpp`), lyrics with LRCLIB/NetEase/Local backends (`lyrics.cpp`), logind session management (`sessionmanager.cpp`)
- Internal: Hyprland socket client (`Internal/hyprextras.cpp`), keyboard devices (`hyprdevices.cpp`), circular buffers + sparkline + visualiser bars (`circularbuffer.cpp`, `sparklineitem.cpp`, `visualiserbars.cpp`), M3 progress indicators (`circularindicatormanager.cpp`, `linearindicatormanager.cpp`)
- Models: recursive filesystem/image model — `Models/filesystemmodel.cpp`
- Images: on-disk resized image cache + async provider — `Images/imagecacher.cpp`, `cachingimageprovider.cpp`, `iutils.cpp`
- Components: viewport-culled lazy list view, button row, animated wavy line — `Components/lazylistview.cpp`, `buttonrow.cpp`, `wavyline.cpp`
- Blobs: metaball group with spring-physics deformable rounded rects and smooth-min GLSL shaders — `Blobs/` + `Blobs/shaders/blob.frag`, `blob.vert`

## D. External CLI

The `caelestia` CLI is a **separate repo** (`github.com/caelestia-dots/cli`, AUR `caelestia-cli`)
and is NOT cloned locally. Reconstructed from every invocation across both repos plus the
READMEs.

| Command | What it does | Evidence |
| --- | --- | --- |
| `caelestia install` | Install the dots (replaces the deprecated `install.fish`) | `caelestia-dots/repo/README.md:29` |
| `caelestia update` | Full system update + update the dots | `README.md:55` |
| `caelestia shell -d` | Start the shell detached | `hypr/hyprland/execs.lua:29`, `keybinds.lua:71,79` |
| `caelestia shell -k` | Kill the shell | `manifest.toml:6` |
| `caelestia shell -s` | List the IPC surface (targets + typed signatures) | `caelestia/repo/README.md:151` |
| `caelestia shell <target> <fn> [args]` | Invoke any IPC function from §B | `README.md:146`, `launcherconfig.hpp`, `hypr/utils/functions.lua:220` |
| `caelestia screenshot` | Take a screenshot | `keybinds.lua:167` |
| `caelestia record [-s\|-r\|-sr\|-p]` | Record fullscreen / with sound / region / region+sound; `-p` toggles pause | `keybinds.lua:170-172`, `services/Recorder.qml:58,62` |
| `caelestia clipboard [-d]` | Clipboard history picker (fuzzel + cliphist); `-d` delete mode | `keybinds.lua:208,209` |
| `caelestia emoji -p` | Emoji picker, paste mode | `keybinds.lua:210` |
| `caelestia wallpaper -f <path>` | Set wallpaper from a file | `services/Wallpapers.qml:38,94` |
| `caelestia wallpaper -r` | Random wallpaper | `services/Wallpapers.qml:33` |
| `caelestia wallpaper -p <path>` | Print the scheme JSON for a wallpaper (live colour preview; stdout → `Colours.load`) | `services/Wallpapers.qml:117` |
| `caelestia wallpaper --no-smart` | Suffix disabling smart-scheme generation | `services/Wallpapers.qml:15` |
| `caelestia scheme list` | List schemes with name + flavour | `modules/launcher/services/Schemes.qml` |
| `caelestia scheme get -nfv` | Get current scheme name / flavour / variant | `services/Colours.qml` |
| `caelestia scheme set -n <name> [-f <flavour>]` | Set scheme | `Schemes.qml`, `manifest.toml:3` |
| `caelestia scheme set -v <variant>` | Set M3 variant | `M3Variants.qml` |
| `caelestia scheme set --notify -m <light\|dark>` | Set light/dark mode with a notification | `services/Colours.qml` (`setMode`) |
| `caelestia --version` | CLI version (Nexus About page) | `pages/AboutPage.qml` |

`~/.config/caelestia/cli.json` also drives special-workspace app placement via its `toggles`
object (`hypr/utils/functions.lua:205`).

### `scripts/` and `extras/` in the shell repo — not user-facing

- `scripts/qml-lint-conventions.py` — repo lint enforcing QML conventions (the only file there)
- `extras/version.cpp` + `extras/CMakeLists.txt` — bakes `CAELESTIA_VERSION` in for `CUtils.version`
- `assets/wrap_term_launch.sh` — 3-line launcher wrapper for terminal apps: `cat ~/.local/state/caelestia/sequences.txt` then `exec "$@"`
- `assets/pam.d/{passwd,fprint,howdy}` — PAM stacks for lockscreen password / fingerprint / face auth

## E. Other dotfiles worth noting

- `manifest.toml` — component/package manifest driving `caelestia install`; top-level packages `caelestia-shell`, `caelestia-cli`; `post_install` seeds the scheme and starts the shell, `post_update` restarts it
- `uwsm/env` — `QT_QPA_PLATFORMTHEME=qtengine`, `QT_WAYLAND_DISABLE_WINDOWDECORATION=1`, `QT_AUTO_SCREEN_SCALE_FACTOR=1`
- `uwsm/env-hyprland` — toolkit backends (`GDK_BACKEND`, `QT_QPA_PLATFORM`, `SDL_VIDEODRIVER`, `CLUTTER_BACKEND`, `ELECTRON_OZONE_PLATFORM_HINT`), XDG session vars, `_JAVA_AWT_WM_NONREPARENTING=1`
- `hypr/hyprland/execs.lua` — autostart: `gnome-keyring-daemon`, polkit-gnome agent, `wl-paste --watch cliphist store` (text + image), `trash-empty 30`, cursor theme, geoclue agent + `gammastep`, `mpris-proxy`, `caelestia shell -d`; plus window-open/title listeners that auto-float+center Bitwarden and PiP-corner any `Picture-in-Picture` window
- `hypr/hyprland.lua` — bootstrap: seeds `hypr/scheme/current.lua`, creates `~/.config/caelestia/hypr-vars.lua` and `hypr-user.lua`, merges user overrides, then loads env/general/input/misc/animations/decoration/group/execs/rules/gestures/keybinds
- `hypr/scheme/{default,current}.lua` — the colour scheme Hyprland uses for borders, groupbar, shadow, background (written by `caelestia scheme set`)
- `fish/config.fish` — sources `~/.local/state/caelestia/sequences.txt` for terminal colours
- `nvim/colors/caelestia.lua` + `nvim/lua/plugins/caelestia.lua` — colorscheme watching `scheme.json` (watches the *directory*, because writes are atomic renames)
- `vscode/caelestia-vscode-integration/` — packaged VSIX + theme applying the live scheme
- `spicetify/` — Spotify theme
- Also themed: `btop/`, `fastfetch/`, `foot/`, `firefox/`, `zen/`, `micro/`, `thunar/`, `zed/`, `starship.toml`
