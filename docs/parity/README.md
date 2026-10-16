# Parity map — HyDE and caelestia vs qsm-shell

What this is: a factual inventory of the two reference desktops, plus where qsm-shell stands
today. Reference material only — **no decisions are recorded here.** `spec/` remains the sole
authority on look and behavior.

- [`hyde.md`](hyde.md) — HyDE: 164 keybinds + layout/gesture/shell binds, full feature tree, and
  what the live install on this machine has actually lost.
- [`caelestia.md`](caelestia.md) — caelestia: full bind set, the shell's 40+ IPC functions, every
  module and service, and the external `caelestia` CLI.

## Numbers at a glance

| | HyDE | caelestia | qsm-shell (today) |
| --- | --- | --- | --- |
| Keybinds in the shipped config | **164** (+ ~35 layout-preset, + 8 gestures) | **~110** (+ 4 gestures) | **65** (`~/.config/hypr/hyprland.lua`) |
| Binds that talk to a shell | 0 — everything is `exec <script>` | 21 `global` → `caelestia:*` | **14** `global` → `qsm:*` |
| Shell IPC functions | n/a (bash/lua scripts + `hydectl`) | **40+** across 12 targets | **28** on one `qsm` target |
| UI surfaces | waybar (56 modules, 21 layouts) + 12 rofi menus + dunst + wlogout + hyprlock | bar, dashboard, launcher, notifications, sidebar, osd, session, utilities, lock, nexus, areapicker, windowinfo, background | rail, panel (5 tabs), launcher, notifications, osd, session |
| Services / backends | ~40 scripts in `lib/hyde/` | 22 QML services + a C++ plugin | 14 QML services |
| Architecture | shell-out per action; every feature is a script | one Quickshell process, IPC + GlobalShortcuts | one Quickshell process, one SDF shader, GlobalShortcuts |

## qsm-shell's live keybinds — the baseline

Shell actions (`shell/input/Shortcuts.qml`, 14 declared under appid `qsm`):

| Keys | Action |
| --- | --- |
| `SUPER + SPACE` | launcher |
| `SUPER + V` | clipboard (launcher `>clip`) |
| `SUPER + D` | dashboard (top panel, last tab) |
| `SUPER + SHIFT + D` | notification centre |
| `SUPER + W` | workspaces overview |
| `SUPER + SHIFT + B` | pin/unpin the rail |
| `SUPER + L` | lock |
| `CTRL + ALT + DELETE` | session / power |
| `XF86AudioMute` / `XF86AudioMicMute` | mute output / mic |
| `XF86Audio{Raise,Lower}Volume` | volume up/down |
| `XF86MonBrightness{Up,Down}` | brightness up/down |

Compositor-only binds in the same file: `CTRL+Q`/`ALT+F4` close, `SUPER+F` fullscreen,
`SUPER+SHIFT+F` float, `SUPER+G` group, `SUPER+SHIFT+P` pin, `SUPER+J` togglesplit,
`SUPER+TAB`/`SUPER+SHIFT+TAB` cycle, `SUPER+CTRL+H/L` group prev/next, **`SUPER+N/O/I/E` focus**
(+ `SHIFT` resize, + `CTRL` move), `SUPER+Z`/`X`/`mouse:272`/`mouse:273` drag/resize,
`SUPER+T/U/C/B` terminal/files/editor/browser, `CTRL+SHIFT+ESCAPE` btop,
`XF86Audio{Play,Pause,Next,Prev}` → `playerctl`, `SUPER+K` switch kb layout,
`SUPER+CTRL+D` / `SUPER+CTRL+SHIFT+D` disable/enable the internal keyboard, `SUPER+ALT+G`
toggle animations, `SUPER+P` / `SUPER+ALT+P` / `PRINT` screenshot area/monitor/full,
`SUPER+1..0` workspace (+ `SHIFT` move, + `ALT` move silent), `SUPER+LEFT/RIGHT` relative
workspace, `SUPER+CTRL+DOWN` empty workspace, `SUPER+CTRL+LEFT/RIGHT` move workspace to monitor.

## Where the three collide on the same key

Only rows where at least two desktops disagree, or where qsm has taken a key for something else.

| Keys | HyDE | caelestia | qsm-shell |
| --- | --- | --- | --- |
| `SUPER + SPACE` | — | — | **launcher** |
| `SUPER + A` | app finder (rofi) | — | — |
| `SUPER + SUPER_L` | — | **launcher** (tap) | — |
| `SUPER + W` | toggle float | browser | **workspaces overview** |
| `SUPER + D` | — | communication scratchpad | **dashboard** |
| `SUPER + N` | — | sidebar (notif centre) | **focus left** |
| `SUPER + E` | file explorer | file explorer | — (`SUPER+U` instead) |
| `SUPER + B` | browser | — | browser |
| `SUPER + T` | terminal | terminal | terminal |
| `SUPER + C` | editor | editor | editor |
| `SUPER + Q` | close window | close window | — (`CTRL+Q` instead) |
| `SUPER + F` | — | fullscreen | fullscreen |
| `SUPER + S` | scratchpad | special workspace | — |
| `SUPER + P` | snip screen | pin window | **screenshot area** |
| `SUPER + SHIFT + P` | color picker | — | pin window |
| `SUPER + V` | clipboard picker | clipboard picker | **clipboard** |
| `SUPER + K` | toggle kb layout | show all panels | toggle kb layout |
| `SUPER + L` | lock | lock | lock |
| `SUPER + M` | — | music scratchpad | — |
| `SUPER + R` | — | todo scratchpad | — |
| `SUPER + U` | — | move out of group | **file manager** |
| `SUPER + G` | toggle group | — | toggle group |
| `SUPER + TAB` | rofi window switcher | — | cycle next in group |
| `ALT + TAB` | alt-tab switcher | cycle next in group | — |
| `SUPER + slash` | **keybind cheat sheet** | — | — |
| `SUPER + comma` | emoji picker | toggle group | — |
| `SUPER + period` | glyph picker | emoji picker | — |
| `CTRL + ALT + DELETE` | wlogout | session menu | session menu |
| `Print` | screenshot all monitors | screenshot | screenshot full |
| `F10`/`F11`/`F12` | mute / vol− / vol+ | — | — |
| arrow cluster | focus (`SUPER+arrows`) | focus (`SUPER+arrows`) | **`N/O/I/E`**; arrows = workspace |

Two structural differences worth naming:

- **Level keys.** qsm routes volume/mic/brightness through the shell (`qsm:volumeUp`, …) so the
  OSD is the single source of truth. caelestia routes brightness and media through the shell but
  volume through `wpctl` directly. HyDE shells out for all of them.
- **Media keys.** caelestia owns them in-shell (`caelestia:mediaToggle/Next/Prev/Stop`); qsm and
  HyDE both hand them to `playerctl` — so qsm has an MPRIS service and a MediaTab but no media
  keybind wired into it.

## Feature domains — coarse coverage

Status column is **evidence-based, verified by grep of `shell/`** — it says whether an
implementation exists, not whether it matches either reference in depth.

| Domain | HyDE | caelestia | qsm-shell |
| --- | --- | --- | --- |
| Status bar | waybar, 56 modules, 21 layouts | vertical left bar, 8 entry types | rail — `modules/bar/Rail.qml` |
| Workspaces widget | `hyprland/workspaces` module | pill column, groups, special strip | `WorkspaceStrip.qml` + `WorkspacesTab.qml` |
| Tray | `wlr/taskbar` + SNI | tray column + native SNI menu | `TrayMenuContent.qml` |
| Clock / calendar | waybar clock | vertical clock + dash calendar | top-band clock bump (spec 06), `DashboardTab.qml` |
| Hover popouts | waybar `group/*` drawers + 10 GTK menus | 9 registered popouts | 5 — battery, bluetooth, network, sound, tray (`BarPopouts.qml`) |
| Notifications | dunst (or swaync) | own server + popups + sidebar | own server — `NotificationService.qml`, `modules/notifications/` |
| Notification centre | swaync control center | right sidebar, grouped | `NotificationCenterTab.qml` |
| OSD | volumecontrol.sh / brightnesscontrol.sh via notify | 3 right-edge sliders | `modules/osd/` |
| Launcher | rofi, 12 styles | slide-up, apps + `>` actions + `@` prefixes | `LauncherSurface.qml` — apps + `>calc >clip >kill >theme` |
| Clipboard | cliphist picker + manager (favorites, wipe, image OCR) | `caelestia clipboard [-d]` via fuzzel | launcher `>clip` |
| Calculator | rofi-calc | `>calc` (Qalculate) | `>calc` |
| Emoji / glyph picker | both, own DBs | emoji only | **none found** |
| Web search / bookmarks | both | — | **none found** |
| Session / power | wlogout, 2 layouts | right-edge column | `SessionSurface.qml` |
| Lock screen | hyprlock, 8 layouts, fingerprint | own QML lock: PAM + fingerprint + Howdy | delegated to hyprlock (restyled) |
| Idle | hypridle 4-step ladder | in-shell `IdleMonitors` chain | delegated to hypridle; `AwakeService.qml` inhibits |
| Wallpaper | 6 backends incl. ONNX depth parallax | own layer + `caelestia wallpaper` | `screen/WallpaperWindow.qml` |
| Theming engine | wallbash → ~15 app targets | M3 dynamic scheme → shell + editors + terminal | per-theme JSON + `Theme.qml` (N-theme law) |
| Screenshot | 6 modes + OCR + QR + satty annotate | own areapicker, 4 modes, window snap | delegated to `~/.config/hypr/scripts/screenshot` |
| Screen recording | wl-screenrec / wf-recorder | `caelestia record` + utilities card + list | **none found** |
| Media / MPRIS | waybar module + playerctl binds | full media tab, lyrics, cava, beat sync | `MediaService.qml`, `MediaTab.qml` (Cava referenced) |
| Weather | waybar module + wttr.in | Open-Meteo service + tab + lock card | `WeatherService.qml`, in `DashboardTab.qml` |
| System monitor | waybar cpu/gpu/sensors + btop | performance tab, 5 cards, sparklines | `PerformanceTab.qml`, `PerformanceService.qml`, `StatRing.qml` |
| Network UI | nm-applet / nm-connection-editor | full nmcli front-end + Nexus pages + VPN | `NetworkPopoutContent.qml`, `NetworkService.qml` |
| Bluetooth UI | blueman | popout + Nexus pair/manage pages | `BluetoothPopoutContent.qml` |
| Audio device UI | pavucontrol / waybar menu | popout + Nexus page + per-app volumes | `SoundPopoutContent.qml`, `AudioService.qml` |
| Battery / power profile | waybar + `batterynotify.lua` | popout + tank widget + auto-hibernate | `BatteryPopoutContent.qml`, `PowerProfileService.qml` |
| Keybind cheat sheet | `SUPER+/`, reads live binds, 8 languages | — | **none found** |
| Settings GUI | `hydectl config` TUI + 49-section TOML | **Nexus** — 11 pages, live-editing | **none found** — `state.json` + theme JSON only |
| Toasts | dunst `HyDE Notify` class | 4-type toast stack + `toaster` IPC | **none found** |
| Game mode | `gamemode.sh` strips effects | `GameMode` service + quick toggle | `SUPER+ALT+G` toggles animations only |
| Night light | hyprsunset, 7+9 presets | — | **none found** |
| Screen shaders | 10 (CVD, OLED saver, e-ink, vibrance…) | — | edge-melt SDF only (different purpose) |
| Alt-tab switcher | own focus-history state machine | compositor group cycling | compositor group cycling |
| Window inspector | — | WindowInfo: preview, details, kill | `HyprClientsService.qml` (data only) |
| Scratchpads | `SUPER+S` + pyprland console | 5 app-bound special workspaces | **none found** |
| Session snapshots | `session.py` save/restore layouts | — | **none found** |
| Layout / animation presets | 6 layouts, 18 animations, 5 workflows | — | **none found** |
| Touchpad gestures | 8 (libinput-gestures) | 4 (native Hyprland) | **none found** |
| Package/update UI | `pm.py`, 8 backends, waybar counter | — | **none found** |
| Game launcher | Steam + Lutris merged catalog | — | **none found** |
| Desktop widgets | — | desktop clock (9 positions) + cava visualiser | **none found** |
| CLI | `hyde-shell`, `hydectl`, `hyde-ipc` | `caelestia` (separate repo) | `qs ipc call qsm <fn>` only |

## What is explicitly NOT in this map

- No per-feature audit against `spec/` — the qsm column reports "an implementation exists", not
  spec conformance.
- No parity decisions, priorities or phase assignments. Nothing here says a gap should be filled.
- The `caelestia` CLI's own repo is not cloned; its subcommands in `caelestia.md` §D are
  reconstructed from call sites, not read from source.
