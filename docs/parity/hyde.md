# HyDE — feature and keybind map

Reference material, not authority. `spec/` still wins every disagreement; this file exists so a
parity decision can be made against facts instead of memory.

Sources: `~/Clonned/HyDE/repo` (HEAD `fa96c4f`, the Lua generation) and the still-installed
`~/.config/hyde`, `~/.local/share/hyde`, `~/.local/lib/hyde`, `~/.config/hypr` on this machine.
Section C records where the live install diverges from the repo.

## A. Keybinds

Source of truth: `Configs/.local/share/hypr/lua/key_binds.lua` — 407 lines, 94 explicit
`hl.bind` + 70 loop-generated = **164 binds**. `MOD` = `hyde.config.modifiers.main` = `"SUPER"`
(`Configs/.local/share/hypr/lua/variables.lua:105`). Keys are spelled **exactly as registered** —
quirks like `SUPER+ ALT  + F4`, `ALT+TAB`, `SUPER+ CONTROL + M` are preserved because
`hl.unbind` matches the literal string. `hyde.sh.*` targets resolve through `hyde.command_map`
in `Configs/.local/share/hypr/lua/hyde/dispatcher.lua:148-179`.

### Launch

| Keys | Action | Dispatcher / script |
| --- | --- | --- |
| `SUPER + T` | terminal emulator | `exec` → `hyde.config.app.terminal` (`hyde-shell app -T`) |
| `SUPER + ALT + T` | dropdown terminal | `exec, hyde-shell pypr toggle console` |
| `SUPER + E` | file explorer | `exec` → `app.explorer` (`hyde-shell open --fall dolphin file-manager`) |
| `SUPER + B` | web browser | `exec` → `app.browser` (`hyde-shell open --fall firefox web-browser`) |
| `SUPER + C` | text editor | `exec` → `app.editor` (`hyde-shell open --fall code-oss code-editor`) |
| `CTRL + SHIFT + ESCAPE` | system monitor | `exec, hyde-shell system.monitor.sh` |
| `SUPER + A` | application finder | `exec, hyde-shell rofilaunch d` |
| `SUPER + TAB` | rofi window switcher | `exec, hyde-shell rofilaunch w` |
| `SUPER + SHIFT + E` | file finder | `exec, hyde-shell rofilaunch f` |
| `SUPER + SHIFT + G` | game launcher | `exec, hyde-shell gamelauncher` |

### Window

| Keys | Action | Dispatcher / script |
| --- | --- | --- |
| `SUPER + Q` | close focused window | `hl.dsp.window.close()` |
| `ALT + F4` | close focused window | `hl.dsp.window.close()` |
| `SUPER+ ALT  + F4` | kill focused window | `hl.dsp.window.kill()` |
| `SUPER + W` | toggle float | `hl.dsp.window.float({action="toggle"})` |
| `SUPER + G` | toggle group | `hl.dsp.group.toggle()` |
| `ALT + P` | toggle pseudotile | `hl.dsp.window.pseudo()` |
| `SHIFT + F11` | cycle fullscreen states (0→1→2) | local `cycle_fullscreen()` → `window.fullscreen_state` |
| `SUPER + SHIFT + F` | toggle pin on focused window | `exec, hyde-shell window.pin` (`window.pin.lua`) |
| `SUPER + J` | toggle split | `hl.dsp.layout("togglesplit")` |
| `SUPER + CTRL + H` | change active group backwards | `hl.dsp.group.prev()` |
| `SUPER + CTRL + L` | change active group forwards | `hl.dsp.group.next()` |
| `SUPER + Left/Right/Up/Down` | focus in direction | `hl.dsp.focus({direction=…})` |
| `ALT+TAB` | alt-tab: next window (*transparent*) | `exec, hyde-shell altab --next` |
| `ALT+SHIFT+TAB` | alt-tab: previous window (*transparent*) | `exec, hyde-shell altab --prev` |
| `ALT + ALT_R` | alt-tab: apply selection (*release, transparent*) | `exec, hyde-shell altab --apply` |
| `ALT + ALT_L` | alt-tab: apply selection (*release, transparent*) | `exec, hyde-shell altab --apply` |
| `SUPER + SHIFT + RIGHT` | resize window right +30 (*repeating*) | `hl.dsp.window.resize({x=30,y=0,relative})` |
| `SUPER + SHIFT + LEFT` | resize window left −30 (*repeating*) | `hl.dsp.window.resize({x=-30,y=0,relative})` |
| `SUPER + SHIFT + UP` | resize window up −30 (*repeating*) | `hl.dsp.window.resize({x=0,y=-30,relative})` |
| `SUPER + SHIFT + DOWN` | resize window down +30 (*repeating*) | `hl.dsp.window.resize({x=0,y=30,relative})` |
| `SUPER + SHIFT + CONTROL + LEFT/RIGHT/UP/DOWN` | move active window (*repeating*) | local `move_window(dir,30)` — `moveactive` if floating, else `movewindow` |
| `SUPER + mouse:272` | hold to move window (*mouse*) | `hl.dsp.window.drag()` |
| `SUPER + mouse:273` | hold to resize window (*mouse*) | `hl.dsp.window.resize()` |
| `SUPER + Z` | hold to move window (*mouse*) | `hl.dsp.window.drag()` |
| `SUPER + X` | hold to resize window (*mouse*) | `hl.dsp.window.resize()` |

### Workspace

| Keys | Action | Dispatcher |
| --- | --- | --- |
| `SUPER + 1`…`9`, `SUPER + 0` | navigate to workspace 1-10 | `hl.dsp.focus({workspace=i})` — loop, **10 binds** (`0` = ws 10) |
| `SUPER + KP_1`/`KP_End` … `SUPER + KP_0`/`KP_Insert` | navigate to workspace 11-20 | `hl.dsp.focus({workspace=i+10})` — loop, **20 binds**; each numpad key bound under *both* keysyms so Num Lock state is irrelevant |
| `SUPER + SHIFT + 1` … `SUPER + SHIFT + 0` | move focused window to workspace 1-10 | `hl.dsp.window.move({workspace=i})` — loop, **10 binds** |
| `SUPER + SHIFT + KP_1`/`KP_End` … `KP_0`/`KP_Insert` | move focused window to workspace 11-20 | `hl.dsp.window.move({workspace=i+10})` — loop, **20 binds**, both keysyms |
| `SUPER + ALT + 1` … `SUPER + ALT + 0` | move window to workspace 1-10, silent | `hl.dsp.window.move({workspace=i, follow=false})` — loop, **10 binds** |
| `SUPER + CONTROL + RIGHT` | active workspace forwards | `hl.dsp.focus({workspace="r+1"})` |
| `SUPER + CONTROL + LEFT` | active workspace backwards | `hl.dsp.focus({workspace="r-1"})` |
| `SUPER + CONTROL + DOWN` | nearest empty workspace | `hl.dsp.focus({workspace="empty"})` |
| `SUPER + CONTROL + ALT + RIGHT` | move window to next relative workspace | `hl.dsp.window.move({workspace="r+1"})` |
| `SUPER + CONTROL + ALT + LEFT` | move window to previous relative workspace | `hl.dsp.window.move({workspace="r-1"})` |
| `SUPER + mouse_down` | next workspace | `hl.dsp.focus({workspace="e+1"})` |
| `SUPER + mouse_up` | previous workspace | `hl.dsp.focus({workspace="e-1"})` |
| `SUPER + S` | toggle scratchpad | `hl.dsp.workspace.toggle_special()` |
| `SUPER + SHIFT + S` | move window to scratchpad | `hl.dsp.window.move({workspace="special"})` |
| `SUPER + ALT + S` | move window to scratchpad, silent | `hl.dsp.window.move({workspace="special", follow=false})` |

### Media / level

| Keys | Action | Dispatcher / script |
| --- | --- | --- |
| `F10` | un/mute output (*locked*) | `exec, hyde-shell volumecontrol -o m` |
| `F11` | decrease volume (*locked, repeating*) | `exec, hyde-shell volumecontrol -o d` |
| `F12` | increase volume (*locked, repeating*) | `exec, hyde-shell volumecontrol -o i` |
| `XF86AudioMute` | un/mute output (*locked*) | `exec, hyde-shell volumecontrol -o m` |
| `XF86AudioMicMute` | un/mute microphone (*locked*) | `exec, hyde-shell volumecontrol -i m` |
| `XF86AudioLowerVolume` | decrease volume (*locked, repeating*) | `exec, hyde-shell volumecontrol -o d` |
| `XF86AudioRaiseVolume` | increase volume (*locked, repeating*) | `exec, hyde-shell volumecontrol -o i` |
| `XF86AudioPlay` / `XF86AudioPause` | play/pause media (*locked*) | `exec, playerctl play-pause` |
| `XF86AudioNext` | next media (*locked*) | `exec, playerctl next` |
| `XF86AudioPrev` | previous media (*locked*) | `exec, playerctl previous` |
| `SUPER+ CONTROL + M` | un/mute the focused window | `exec, hyde-shell window.mute` (`window.mute.py`) |
| `XF86MonBrightnessUp` | increase brightness (*locked, repeating*) | `exec, hyde-shell brightnesscontrol -i` |
| `XF86MonBrightnessDown` | decrease brightness (*locked, repeating*) | `exec, hyde-shell brightnesscontrol -d` |

### Screenshot

| Keys | Action | Dispatcher / script |
| --- | --- | --- |
| `SUPER + SHIFT + P` | color picker (*locked*) | `exec, hyprpicker -an` |
| `SUPER + P` | snip screen (partial) (*locked*) | `exec, hyde-shell screenshot s` |
| `SUPER + CONTROL + P` | freeze and snip screen (*locked*) | `exec, hyde-shell screenshot sf` |
| `SUPER + ALT + P` | print focused monitor (*locked*) | `exec, hyde-shell screenshot m` |
| `Print` | print all monitors (*locked*) | `exec, hyde-shell screenshot p` |
| `SUPER + CONTROL + S` | scan text on screen (OCR) (*locked*) | `exec, hyde-shell screenshot sc` |

### Clipboard

| Keys | Action | Dispatcher / script |
| --- | --- | --- |
| `SUPER + V` | clipboard picker | `exec, hyde-shell cliphist -c` |
| `SUPER + SHIFT + V` | clipboard manager (favorites / delete / wipe) | `exec, hyde-shell cliphist` |

### Theme

| Keys | Action | Dispatcher / script |
| --- | --- | --- |
| `SUPER+ ALT + Right` | next wallpaper | `exec, hyde-shell wallpaper --global --next` |
| `SUPER+ ALT + Left` | previous wallpaper | `exec, hyde-shell wallpaper --global --prev` |
| `SUPER+ ALT + Up` | next waybar layout | `exec, hyde-shell waybar --next` |
| `SUPER+ ALT + Down` | previous waybar layout | `exec, hyde-shell waybar --prev` |
| `SUPER+ SHIFT + W` | select a wallpaper | `exec, hyde-shell wallpaper -GS` |
| `SUPER+ SHIFT + R` | wallbash mode selector | `exec, hyde-shell wallbashtoggle -m` |
| `SUPER+ SHIFT + T` | select a theme | `exec, hyde-shell theme.select` |
| `SUPER+ SHIFT + Y` | select animations | `exec, hyde-shell animations --select` |
| `SUPER+ SHIFT + U` | select hyprlock layout | `exec, hyde-shell hyprlock --select` |
| `SUPER + SHIFT + A` | select rofi launcher style | `exec, hyde-shell rofiselect` |

### Session

| Keys | Action | Dispatcher / script |
| --- | --- | --- |
| `SUPER + Delete` | exit hyprland session | `hl.dsp.exit()` |
| `SUPER + L` | lock session | `exec, hyde-shell lock-session` |
| `CTRL + ALT + DELETE` | logout menu (wlogout) | `exec, hyde-shell logoutlaunch` |

### Utility

| Keys | Action | Dispatcher / script |
| --- | --- | --- |
| `SUPER + CTRL + B` | hide/toggle waybar | `exec, hyde-shell waybar --hide` |
| `SUPER + slash` | keybindings hint | `exec, hyde-shell keybinds_hint` |
| `SUPER + comma` | emoji picker | `exec, hyde-shell emoji-picker` |
| `SUPER + period` | glyph picker | `exec, hyde-shell glyph-picker` |
| `SUPER + SHIFT + K` | calculator | `exec, hyde-shell calculator` |
| `SUPER + SHIFT + slash` | web search | `exec, hyde-shell rofi.websearch` |
| `SUPER + K` | toggle keyboard layout (*locked*) | `exec, hyde-shell keyboardswitch` |
| `SUPER + ALT + G` | game mode (strip effects) (*locked*) | `exec, hyde-shell gamemode` |

### A.2 Layout-preset binds

One preset active at a time, picked with `hyde-shell layouts --select`. Loaded **on top of** the
table above from `Configs/.local/share/hypr/lua/layouts/`. Not counted in the 164.

| Keys | Action | Dispatcher — preset |
| --- | --- | --- |
| `ALT + J` | toggle split | `layout("togglesplit")` — dwindle |
| `ALT + K` | swap split halves | `layout("swapsplit")` — dwindle |
| `ALT + H` | decrease split ratio | `layout("splitratio -0.1")` — dwindle |
| `ALT + L` | increase split ratio | `layout("splitratio +0.1")` — dwindle |
| `ALT + U` | move window to root subtree | `layout("movetoroot")` — dwindle |
| `ALT + Y` | preselect left/top split | `layout("preselect l")` — dwindle |
| `ALT + I` | preselect right/bottom split | `layout("preselect r")` — dwindle |
| `ALT + M` | swap with master | `layout("swapwithmaster auto")` — master |
| `ALT + F` | focus master | `layout("focusmaster auto")` — master |
| `ALT + period` | focus/cycle next window | `layout("cyclenext")` — master, monocle |
| `ALT + comma` | focus/cycle previous window | `layout("cycleprev")` — master, monocle |
| `ALT + K` | swap with next window | `layout("swapnext")` — master |
| `ALT + J` | swap with previous window | `layout("swapprev")` — master |
| `ALT + A` | add window to master area | `layout("addmaster")` — master |
| `ALT + SHIFT + A` | remove current master | `layout("removemaster")` — master |
| `ALT + LEFT/RIGHT/UP/DOWN/C` | orientation left/right/top/bottom/center | `layout("orientation*")` — master |
| `ALT + N` / `ALT + SHIFT + N` | cycle orientation cw / ccw | `layout("orientationnext"/"orientationprev")` — master |
| `ALT + T` | cycle orientation through all | `layout("orientationcycle left top right bottom center")` — master |
| `ALT + EQUAL` / `ALT + MINUS` | master ratio ±0.05 | `layout("mfact ±0.05")` — master |
| `ALT + U` / `ALT + I` | rotate next / prev stack window into master | `layout("rollnext"/"rollprev")` — master |
| `ALT + EQUAL` / `ALT + L` | column resize + (*repeating*) | `layout("colresize +conf")` — scrolling |
| `ALT + MINUS` / `ALT + H` | column resize − (*repeating*) | `layout("colresize -conf")` — scrolling |
| `ALT + period` / `ALT + comma` | move window ±column | `layout("move ±col")` — scrolling |
| `ALT + Y` / `ALT + I` | swap column left / right | `layout("swapcol l"/"swapcol r")` — scrolling |
| `ALT + U` | promote to own column | `layout("promote")` — scrolling |
| `ALT + F` | fit active window | `layout("fit active")` — scrolling |
| `ALT + SHIFT + F` | fit visible (scrolling) / fit all (scrolling-down) | `layout("fit visible"/"fit all")` |
| `ALT + CTRL + F` | fit visible (scrolling-down only) | `layout("fit visible")` |
| `ALT + Z` | toggle scroll inhibition | `layout("inhibit_scroll")` — scrolling |
| `ALT + O` | expel window to own column | `layout("expel")` — scrolling |
| `ALT + SLASH` | consume window into previous column | `layout("consume")` — scrolling |
| `ALT + M` | consume or expel window | `layout("consume_or_expel prev")` — scrolling |
| `SUPER + SHIFT + mouse_down/mouse_up` | workspace r±1 (scrolling) / e±1 (scrolling-down) | `focus({workspace=…})` — scrolling |
| `SUPER+ mouse_up/mouse_down` | scroll focus left/right (scrolling), up/down (scrolling-down) | `focus({direction=…})` — scrolling |
| `SUPER+CTRL + mouse_up/mouse_down` | scroll focus up/down (scrolling), left/right (scrolling-down) | `focus({direction=…})` — scrolling |

### A.3 Non-keyboard bindings

4-finger touchpad gestures — `Configs/.config/libinput-gestures.conf`:

| Gesture | Command | Category |
| --- | --- | --- |
| `pinch clockwise 4` | `volumecontrol.sh -o i 10` | media/level |
| `pinch anticlockwise 4` | `volumecontrol.sh -o d 10` | media/level |
| `pinch out 4` / `pinch in 4` | `brightnesscontrol.sh i` / `d` | media/level |
| `swipe up 4` | `hyprctl dispatch fullscreen 0` | window |
| `swipe down 4` | `hyprctl dispatch exec screenshot.sh p` | screenshot |
| `swipe right 4` | `hyprctl dispatch exec pkill rofi \|\| cliphist.sh c` | clipboard |
| `swipe left 4` | `hyprctl dispatch exec dunstctl history-pop` | misc |

wlogout accelerators — `Configs/.config/wlogout/layout_1`, `layout_2`: `l` lock → `lockscreen.sh`;
`e` logout → `hyde-shell logout`; `u` suspend → `lockscreen.sh & disown && systemctl suspend`;
`s` shutdown → `systemctl poweroff`; `h` hibernate → `systemctl hibernate`; `r` reboot →
`systemctl reboot`. `layout_2` (the shipped default, `wlogout.style = 2`) drops suspend and
hibernate.

Shell keybinds: `Alt+n` inserts the *n*-th history command
(`Configs/.config/fish/conf.d/hyde.fish`, `bind_M_n_history`); `Ctrl+Right`/`Ctrl+Left` word
motion and `Delete` → `delete-char` (`Configs/.config/zsh/conf.d/binds.zsh`, three
escape-sequence dialects each); `?` on a non-empty buffer appends `--help` and runs
(`Configs/.config/zsh/functions/kb_help.zsh`, `bindkey '?' append_help_and_run`).

Dunst has **no keyboard shortcuts** (upstream removed them); mouse only —
`mouse_left_click = context, close_current`, `mouse_middle_click = do_action, close_current`,
`mouse_right_click = close_all` (`Configs/.config/dunst/dunstrc`).

## B. Features

### Bar / status

- **Waybar top dock**, all outputs, exclusive zone, live style reload — `Configs/.config/waybar/config.jsonc`
- **21 selectable bar layouts** (`hyprdots/01..17`, `khing`, `macos`) cycled or picked — `Configs/.local/share/waybar/layouts/`, driven by `lib/hyde/waybar.py`
- **~56 modules.** The `.config/waybar/modules/*.jsonc` files are empty stubs; real definitions are globbed from `Configs/.local/share/waybar/modules/`. Notables: `custom/cpuinfo`, `custom/gpuinfo` (+`#amd/#intel/#nvidia`), `custom/sensorsinfo`, `custom/updates`, `custom/weather`, `custom/mediaplayer`, `custom/spotify`, `custom/cava`, `custom/dunst`, `custom/swaync`, `custom/clipboard`, `custom/cliphist`, `custom/theme`, `custom/wallchange`, `custom/wbar`, `custom/workflows`, `custom/hyprsunset`, `custom/keybindhint`, `custom/gamemode`, `custom/display`, `custom/power`, `image#wallpaper`, `image#profile`, `wlr/taskbar`, `hyprland/workspaces` (+`#kanji`/`#roman`), `temperature#0/#2/#27`, `network#bandwidth*`
- **Hover drawers** — `group/volumecontrol` (output reveals mic), `group/mediaplayer` (title reveals transport), `group/eyecare`, `group/hide-tray`, `group/user-menu` — `Configs/.local/share/waybar/modules/group-*.jsonc`
- **10 right-click GTK menus** — `Configs/.local/share/waybar/menus/` (`hyde-menu.xml`, `power.xml`, `dunst.xml`, `swaync.xml`, `hyprsunset.xml`, `mediaplayer.xml`, `spotify.xml`, `clipboard.xml`, `gpuinfo.xml`, `pulseaudio.xml`)
- **CPU/GPU/sensor/battery/weather feeds** — `lib/hyde/cpuinfo.sh`, `gpuinfo.sh`, `amdgpu.py`, `sensorsinfo.py`, `battery.sh`, `weather.py`
- **Cava audio visualizer**, one daemon broadcast to many readers — `lib/hyde/cava.py` (`manager` + client)
- **Update counter** — `lib/hyde/system.update.py` over `pm.py`
- **MPRIS now-playing** — `lib/hyde/mediaplayer.py`

### Notifications

- **dunst** is the default daemon; `dunstrc` is *generated* from the wallpaper palette by `wallbash/scripts/dunst.sh`, source at `Configs/.local/share/hyde/dunst.conf`
- Progress-bar OSD for volume/brightness, 20-item sticky history, rofi-backed dmenu/context menu (`-config notification.rasi`), `Wallbash-Icon` theme chain, per-urgency colors, named classes `HyDE Alert` / `HyDE Notify`, app icon overrides (slack/telegram/skype), per-monitor DPI — same two files
- **swaync alternative** (installer picks one) — `Configs/.config/swaync/config.json`: control center with DND, MPRIS, inline backlight + volume sliders, 4-button quick grid (nm-connection-editor, blueman-manager, hyprsunset toggle, logout)
- **Battery notifications** — low/critical/full/unplug thresholds with per-event commands (`critical = systemctl suspend`) — `lib/hyde/batterynotify.lua` (UPower DBus daemon)
- **Notification feed for the bar** — `lib/hyde/notifications.py` (dunstctl history → waybar JSON)

### Launcher / menus — all rofi

- **App launcher / window switcher / file browser / run** — `lib/hyde/rofilaunch.sh` (`d`/`w`/`f`/`r`)
- **12 launcher styles + launchpad + steam_deck** picker — `lib/hyde/rofiselect.sh`, themes in `Configs/.local/share/hyde/rofi/themes/`
- **Clipboard picker + manager** (history, favorites, delete, wipe, image history, image OCR) — `lib/hyde/cliphist.sh`, thumbnails via `cliphist.image.py`
- **Emoji picker** (`emoji.db`, multi-select, recents) — `lib/hyde/emoji-picker.sh`
- **Glyph picker** (`glyph.db`, nerd fonts) — `lib/hyde/glyph-picker.sh`
- **Calculator** (rofi-calc) — `lib/hyde/calculator.sh`
- **Web search** with per-engine icons — `lib/hyde/rofi.websearch.sh`, engines in `share/hyde/websearch.lst`
- **Browser bookmarks launcher** — `lib/hyde/bookmarks.py` + `rofi.bookmarks.sh`
- **Game launcher** over a merged Steam + Lutris catalog, 5 grid styles — `lib/hyde/gamelauncher.sh` + `gamelauncher/{catalog,steam,lutris}.py`
- **Quickapps dock**, cursor-anchored — `lib/hyde/quickapps.sh`
- **Alt-tab switcher** with a focus-history state machine — `lib/hyde/altab.lua` + `altab/hyprland.lua`
- **Preset pickers** (animations, layouts, shaders, workflows) sharing one selector engine — `lib/hyde/rofi.{animations,layouts,shaders,workflows}.lua` over `luautils/selector/common.lua`

### OSD

- **Volume/mute OSD** for sinks, sources and MPRIS players, swayosd or notify-based, boost to 120% — `lib/hyde/volumecontrol.sh`
- **Brightness OSD** — `lib/hyde/brightnesscontrol.sh` (brightnessctl)
- **Per-window mute** — `lib/hyde/window.mute.py` (PipeWire sink-inputs of the focused window)
- Step sizes and notify on/off are config: `[volume]`, `[brightness]` in `Configs/.local/share/hyde/schema/config.toml`

### Wallpaper / theming

- **Wallbash** — the core: extracts a 4-primary × 9-accent palette from the wallpaper and rewrites app themes. Engine `lib/hyde/wallbash.sh`; applier `lib/hyde/color.set.sh`; mode toggle (`theme`/`auto`/`dark`/`light`) `lib/hyde/wallbashtoggle.sh`; debug printer `wallbash.print.colors.sh`
- **Wallbash targets**: cava, Chrome/Chromium (generated browser theme), Discord (Vencord/Vesktop/WebCord/ArmCord), Spotify (spicetify Sleek), Vim, wayle, VS Code/VSCodium/Cursor (auto-installed `.vsix`), swaync, dunst, GTK/waybar CSS — `Configs/.config/hyde/wallbash/{always,theme,scripts}/`
- **Wallpaper front end** — list/set/next/prev/random/select/get/output + thumbnail cache — `lib/hyde/wallpaper.sh` (+ `wallpaper/{help,core,cache,select}.sh`)
- **6 wallpaper backends** — `wallpaper.awww.sh` (default), `.swww.sh` (deprecated), `.hyprpaper.sh`, `.mpvpaper.sh` (video), `.waydeeper.sh` (**ONNX depth-map parallax**, models `depth-anything-v3-base`/`midas-small`/`depth-pro-q4`), `.kon.sh` (Dolphin "set as wallpaper" KIO service menu)
- **12 official themes** + import from the hyde-gallery — `Scripts/themepatcher.lst`, `lib/hyde/theme.{select,switch,patch}.sh`, `theme.import.py`, `hydectl theme import`
- **18 animation presets** — `Configs/.local/share/hypr/lua/animations/` (`00-disable` … `vertical`), managed by `lib/hyde/animations.lua`
- **6 layout presets** with their own ALT keymaps — `lua/layouts/{00,dwindle,master,monocle,scrolling,scrolling-down}.lua`, managed by `layouts.lua`
- **5 workflow presets** (Default, Editing, Gaming, Powersaver, Snappy) that restyle the whole compositor — `lua/workflows/`, managed by `workflows.lua`
- **10 screen shaders** — blue-light-filter, color-vision (CVD sim *and* daltonization), grayscale, invert-colors, oled-saver (burn-in pixel shift), paper (e-ink), vibrance (skin-tone protected), wallbash (tints Hyprland blur with the palette), `custom.frag` (combine any), `disable.frag` — `Configs/.config/hypr/shaders/`, managed by `lib/hyde/shaders.lua`
- **hyprsunset night light** — temperature 1000-20000K, gamma 20-100, 7 temp + 9 gamma presets in the bar menu — `lib/hyde/hyprsunset.sh`, `Configs/.config/hypr/hyprsunset.conf`
- **Toolkit theming** — GTK3/Qt5/Qt6/Kvantum wallbash colors, isolated `hyde_hyprland` dconf profile, `xsettingsd`, `nwg-look` — `Configs/.config/{qt5ct,qt6ct,Kvantum,gtk-3.0,dconf,xsettingsd,nwg-look}/`, applier `lib/hyde/color/{hypr.sh,dconf.lua}`
- **Palette hand-tuner GUI** (Qt6) — `lib/hyde/pygui/color.shuffle.py`
- **Themed extras archives** — Firefox userconfig + extensions, 2 GRUB themes, Wallbash GTK + icon themes, 2 SDDM themes, Spotify Sleek, Steam Metro — `Source/arcs/`
- **Font installer** — `lib/hyde/font.sh`

### Screenshot / recording

- **Screenshot** — all outputs / area / window / frozen area / focused monitor, with pre/post hooks and l10n — `lib/hyde/screenshot.sh` over vendored `lib/hyde/grimblast`
- **Annotation** — satty (configurable, `[screenshot] annotation_tool`) — `Configs/.config/satty/config.toml`
- **OCR** — tesseract text extraction to clipboard, auto-installs language packs — `lib/hyde/shutils/ocr.sh`
- **QR decode** — `lib/hyde/shutils/qr.sh` (zbarimg)
- **Screen recording** — `wl-screenrec` with `wf-recorder` fallback, region or full — `lib/hyde/screenrecord.sh`
- **Color picker** — `hyprpicker -an`, bound directly

### Clipboard

- **cliphist history daemons** — text + image watchers plus `wl-clip-persist` so the clipboard survives app exit — `[desktop.start].{text_clipboard,image_clipboard,clipboard_persist}` in the schema
- **Picker + manager UI** with a favorites store — `lib/hyde/cliphist.sh`
- **Bar module + menu** — `custom/clipboard`, `custom/cliphist`, `Configs/.local/share/waybar/menus/clipboard.xml`

### Session / lock / idle

- **hypridle ladder** — 60 s dim → 120 s `loginctl lock-session` → 300 s DPMS off → 500 s suspend, with a `source = ./hypridle/*` drop-in point, dbus/systemd inhibit respected — `Configs/.config/hypr/hypridle.conf`
- **Lock** — `hyde-shell lock-session` (loginctl if `org.freedesktop.ScreenSaver` is present, else `lockscreen.sh` as a systemd unit) — `lib/hyde/lockscreen.sh`
- **8 hyprlock layouts** selectable via a one-line `theme.conf` rewrite — HyDE, Anurati, Arfan on Clouds, IBM Plex, IMB Xtented, SF Pro, greetd, greetd-wallbash — `Configs/.config/hypr/hyprlock/`
- **Lock-screen assets** — wallpaper background, profile picture, MPRIS album art, cava bars, time-of-day greeting, weather via wttr.in, battery icon, keyboard layout; plus a layout test/preview mode — `lib/hyde/hyprlock.sh`, boilerplate `Configs/.local/share/hypr/hyprlock.conf`
- **Fingerprint auth** — `Configs/.local/share/hypr/hyprlock-fingerprint.conf`
- **wlogout power menu**, 2 layouts × 2 styles + its own icon set — `Configs/.config/wlogout/`, launcher `lib/hyde/logoutlaunch.sh`
- **Idle inhibitor** — bar toggle plus a pywayland daemon that can inhibit on audio playback — `lib/hyde/idle-inhibitor.py` (`--all`, `--audio`)
- **Session snapshots** — save/restore window layouts by name, per-app plugins (Brave via transient `initialClass` rules, VS Code multi-window, kitty CWD from the process tree), Hyprland + niri backends — `lib/hyde/session.py`, `session/{manager,pluginloader,compositor/*,plugins/*}.py`
- **Polkit agent** — first available from a priority list — `lib/hyde/polkitkdeauth.sh`
- **XDG portal reset** — `lib/hyde/resetxdgportal.sh`
- **uwsm session integration** — `hyde-shell logout`, `hl.on("hyprland.shutdown")` → `uwsm stop`, env in `Configs/.config/uwsm/`

### Keybind hints

- **`SUPER + /` cheat sheet**, read from the *compositor's live binds* so user overrides show up, served from a runtime cache refreshed on close — `lib/hyde/keybinds_hint.sh` + `keybinds/hint-hyprland.py` (`--format json|md|dmenu|rofi`)
- Descriptions use a `[Group|Subgroup] text` convention; binds without one land under "Misc" — documented in `KEYBINDINGS.md`
- `hyde-shell keybinds_hint --reload` forces a cache rebuild; bar entry `custom/keybindhint`
- Keybind reference in 8 languages — `Source/assets/keybinds/`

### Settings / config

- **`config.toml`** — 49 sections, fully annotated, JSON-schema validated — `Configs/.local/share/hyde/schema/config.toml` + `config.toml.json`. User overrides in `~/.config/hyde/config.toml`. Covers: wallpaper + 3 backends, 12 rofi pickers, wlogout, battery notify, screenshot + OCR, wallbash, waybar, weather, 4 cava profiles, volume, brightness, sysmonitor, hyprlock, notification, hyprland anim/float rules, `[desktop.ui]` (20 theme/font keys), `[desktop.app]` (6 default apps), qt5/qt6/gtk3, `[desktop.start]` (17 autostart units), mediaplayer
- **`hydectl config`** — interactive TUI config editor with syntax-highlighted preview
- **Config registry** — per-app edit targets with pre/post reload hooks (hyde, kitty, zsh, dunst, hyprland, waybar, rofi) — `Configs/.local/share/hyde/config-registry.toml`
- **Lua config engine** — reads the TOML, exports env + hyprland values, optional daemon — `lib/hyde/config.lua`; hyprland-lua JSON schema for editor completion at `Configs/.local/share/hypr/schema/hyprland-lua.json`
- **User config never overwritten** — `~/.config/hypr/hyprland.lua` loads *after* HyDE's binds; `hyde.binds.dedup = true` makes a re-bind replace rather than double-fire (flags must match) — `Configs/.config/hypr/hyprland.lua`, `lua/hyde/binds.lua`

### Scripts and CLI

- **`hyde-shell`** (625-line bash, v1.1.0) — 17 builtins: `help`, `man`, `reload`, `scripts`, `wallbash`, `version`, `release-notes`, `completion`, `validate`, `pyinit`, `luainit`, `uv`, `luarocks`, `init`, `logout`, `lock-session`, `pypr` (+ `app`). Everything else falls through to a script resolver walking `HYDE_SCRIPTS_PATH` with precedence `.lua` → `.sh` → `.py` → bare executable (Lua first, so a stale `.sh` can't shadow its replacement) — `Configs/.local/bin/hyde-shell`
- **`eval "$(hyde-shell init)"`** — the env prelude nearly every script starts with
- **`hydectl`** (Go/Cobra ELF, `r45.5b3a9cc`) — `completion`, `config`, `dispatch` (plugins), `reload`, `select {emoji,glyph}`, `tabs`, `theme {select,set,next,prev,import}`, `wallpaper {get,set,list,next,previous,random,select,output}`, `version`, `zoom` — `Configs/.local/bin/hydectl`
- **`hyde-ipc`** (Go ELF) — config-watching IPC/script daemon; `-memlimit`, `-nowatch`, `-timeout`, `-verbose`
- **Metadata-driven help + completions** — `@name:`/`@cmd:` comments parsed into help pages, man pages, and bash/zsh/fish completions — `lib/hyde/completions.py`, `help.py`, `completions/hyde-shell.{bash,zsh,fish}`
- **Package manager abstraction** — 8 backends (pacman, paru, yay, apt, dnf, zypper, flatpak, + meta contract) — `lib/hyde/pm.sh`, `pm.py`, `package_managers/*.py`
- **Isolated runtimes** — uv-backed python venv and luarocks tree under `$XDG_STATE_HOME/hyde/` — `lib/hyde/pyutils/{python_env,lua_env}.py`
- **Shared libraries** — `globalcontrol.sh` (467 lines: XDG dirs, `print_log`, `send_notifs`, `get_hyprConf`, `get_themes`, `set_conf`, `pkg_installed`, `get_monitor_scale`), `shutils/{argparse,l10n}.sh`, `shell/activate{,.fish}`, `luautils/*` (toml, json, argparse, hyprctl, log, notify, state, theme parser, selector, rofi pos)
- **Installer** — `Scripts/install.sh` + `install_{pre,pkg,aur,pst}.sh`, `restore_{cfg,fnt,shl,svc,thm}.sh`, deez-dots manifests (`dots.toml`, `Scripts/dots/*.toml`, `Scripts/dots-groups/{core,extra,optionals,shell,notification-daemon}.toml`), nvidia driver DB, `uninstall.sh`, NixOS flake, `Scripts/hydevm/` VM harness
- **Ordered, recorded migrations** — `Scripts/migrations/v25.8.2 … v26.8.2.sh` (v26.7.4 / 26.8.1 / 26.8.2 are the hyprlang→Lua move)
- **Other user-facing scripts** — `system.monitor.sh`, `fastfetch.sh`, `gamemode.sh`, `keyboardswitch.sh`, `window.pin.lua`, `open.lua` (Gio mime/default-app opener), `app.sh` (app2unit systemd-scoped launcher), `xdg-terminal-exec` (vendored Default Terminal Execution Spec), `reload.py`, `restore.config.sh`, `fzf_preview.sh`

### Integrations

- **Hyprland** — Lua config layer: `hyde.lua` entry, `key_binds.lua`, `variables.lua`, `window_rules.lua` (float-by-class/title, picture-in-picture, modals, XWayland video-bridge suppression — all regex-precompiled), `layer_rules.lua` (blur + `ignore_alpha` for rofi/waybar/notifications/swaync/logout, no-anim on `selection`), `events.lua` (clamp new floating windows to the monitor; `uwsm stop` on shutdown), `start_up.lua` (17-item autostart roster), `dynamic.lua`, `env.lua`, `defaults.lua` — `Configs/.local/share/hypr/lua/`
- **waybar** — bar + 56 modules + 21 layouts + 9 menus, managed by `waybar.py --watch`
- **rofi** — every menu in HyDE; palette stub `theme.rasi` is wallbash-overwritten, functional themes in `.local/share/hyde/rofi/themes/`
- **dunst / swaync** — notifications (installer picks one)
- **swww / awww / hyprpaper / mpvpaper / waydeeper** — wallpaper backends
- **wlogout** — power menu
- **hyprlock / hypridle / hyprsunset / hyprpicker** — lock, idle, night light, color pick
- **pyprland** — `scratchpads` plugin only; `console` drop-down terminal (`fromTop`, 75%×60%, class `console-dropdown`, in the float rule list) — `Configs/.config/pypr/config.toml`
- **libinput-gestures** — 8 four-finger touchpad gestures
- **Shells** — fish (`conf.d/hyde.fish`: XDG bootstrap, `HYPRLAND_CONFIG` discovery, starship, eza/`hyde-shell pm` aliases, `Alt+n` history bind) and zsh (`conf.d/00-hyde.zsh`, `binds.zsh`, `hyde/{env,prompt,terminal}.zsh`, p10k, fzf, `?`-help widget, `hydectl` completion)
- **Terminals / apps** — kitty (`hyde.conf`, `theme.conf`), foot via `[desktop.app]`, Code/Code-OSS/VSCodium settings, Dolphin + baloo, vim (`wallbash.vim`), lsd, fastfetch (7 custom logos), MangoHud, satty, electron/chrome/spotify flag files, `xdg-desktop-portal` hyprland portals, `menus/applications.menu`, `xdg-terminals.list`

## C. Live divergence

Bottom line: **HyDE is not the desktop on this machine any more.** The Hyprland layer is fully
detached — **zero of the 164 HyDE keybinds are live** — while a *pre-Lua* generation of HyDE's
script and config tree is still on disk, unloaded and unstarted. The clone in `~/Clonned/HyDE/repo`
is also **newer than what is installed**, so some divergence is version skew, not owner action.

### 1. Compositor layer: fully replaced

- Active config is `~/.config/hypr/hyprland.lua` — **qsm-owned**, 222 lines. No `dofile()`, no `hyde.lua` load, no `if not hyde then` guard (`grep 'hyde.lua\|dofile\|if not hyde'` → 0 matches).
- **`~/.local/share/hypr/` does not exist.** HyDE's entire Lua layer — `hyde.lua`, `key_binds.lua`, `variables.lua`, `window_rules.lua`, `layer_rules.lua`, `events.lua`, `start_up.lua`, `layouts/`, `workflows/`, `animations/`, `schema/` — is not installed.
- Consequence: all 164 binds, the 6 layout keymaps, the 5 workflow presets, the 18 animation presets and HyDE's window/layer rules are gone. There is no `~/.config/hypr/hyprland.conf` either, so nothing hyprlang-based loads.
- The replacement binds shell actions as `hl.dsp.global("qsm:<name>")` compositor→shell messages (`launcher`, `clipboard`, `dashboard`, `notifications`, `workspaces`, `rail`, `lock`, `session`, `volumeMute/Up/Down`, `micMute`, `brightnessUp/Down`) and rebinds focus/resize/move onto the `N/O/I/E` cluster instead of arrows.
- Two backups survive — `~/.config/hypr/hyprland.lua.bak-qsm` and `.bak-2026-08-19` — both already qsm-authored, so HyDE's Lua config was never resident here.

### 2. Script tree is the legacy generation, and its migration never ran

- `~/.local/lib/hyde/` has **81 entries vs the repo's 99**; only 52 names overlap.
- **47 repo files absent live**, including every Lua/py replacement and every new subsystem: `altab/`, `altab.lua`, `animations.lua`, `layouts.lua`, `workflows.lua`, `shaders.lua`, `window.pin.lua`, `batterynotify.lua`, `open.lua`, `config.lua`, `app.sh`, `session/` + `session.py`, `gamelauncher/`, `package_managers/`, `pm.py`, `pygui/`, `keybinds/`, `luautils/`, `shell/`, `shutils/`, `wallpaper/`, `completions/`, `completions.py`, `help.py`, `reload.py`, `bookmarks.py`, `cava.py`, `cliphist.image.py`, `window.mute.py`, `system.monitor.sh`, `system.update.py`, `rofi.{animations,layouts,shaders,workflows}.lua`, `rofi.bookmarks.sh`, `rofi.websearch.sh`, `wallpaper.{awww,hyprpaper,kon,waydeeper}.sh`, `xdg-terminal-exec`, `pyproject.toml`, `uv.lock`.
- **29 legacy-only files present live** that the repo dropped: `animations.sh`, `batterynotify.sh`, `cava.sh`, `configuration.py`, `dontkillsteam.sh`, `hypr.unbind.sh`, `keybinds.hint.py`, `parse.config.py`, `parse.json.py`, `shaders.sh`, `swwwall{bash,cache,kon,paper,select}.sh`, `sysmonlaunch.sh`, `systemupdate.sh`, `testrunner.sh`, `themeselect.sh`, `themeswitch.sh`, `wallbash.{hypr,qt}.sh`, `wbarconfgen.sh`, `wbarstylegen.sh`, `windowpin.sh`, `workflows.sh`, `gnome-terminal`, `hyde-config`, `hyq`, `pyutils/`.
- That list is **exactly `Scripts/migrations/v26.7.4.sh`'s `superseded` set** — the Lua migration was never applied. Under the legacy `.sh`-before-`.lua` resolution these files *shadow* their replacements (`themeselect.sh` and `theme.select.sh` both exist; `swwwallpaper.sh` is a deprecation shim forwarding to `wallpaper.sh --backend swww --global`).
- Cross-check: every `hyde-shell <script>` call in the live waybar modules **does** resolve in live `~/.local/lib/hyde/`. The legacy stack is internally consistent — just never started.

### 3. CLI version skew

| | Live | Repo |
| --- | --- | --- |
| `hyde-shell` | legacy, **6 verbs**: `-i/interactive`, `-r/reload`, `zoom`, `wallbash`, `--help`, `--list-script`, `--list-script-path` | **17 verbs** (see §B) |
| `hydectl` | `r23.b3fb401` — no `config` subcommand | `r45.5b3a9cc` — adds `config` (TUI editor) |
| `hyde-ipc` | **absent** | present (2.7 MB Go daemon) |
| extra live binary | `hyde-wallpaper-monitor-watch` (legacy) | — |

Missing live `hyde-shell` verbs include `pypr`, so `SUPER + ALT + T` (dropdown terminal) would
fail even if it were bound; also `help`, `man`, `scripts`, `version`, `release-notes`,
`completion`, `validate`, `pyinit`, `luainit`, `uv`, `luarocks`, `init`, `logout`,
`lock-session`, `app`.

### 4. A third, older bind file is stranded on disk

`~/.local/share/hyde/keybindings.conf` (174 lines) is the **Hyprdots-era hyprlang** file and
differs from *both* generations: `alt, space` for the launcher (not `SUPER+A`), `SUPER+F` for the
browser (not `SUPER+B`), `SUPER+Backspace` for logout (not `CTRL+ALT+DELETE`), `SUPER+grave` for
the scratchpad (not `SUPER+S`), `Alt_R, Control_R` for the waybar toggle, `Alt, Return` for
fullscreen, `swaylock` for lock, and `Alt, Tab` mapped to `movefocus, d`. It references scripts
that no longer exist live under those names. Nothing sources it.

### 5. No HyDE daemon is running

Live processes (`/proc/*/comm`): `Hyprland`, `start-hyprland`, `qs` (quickshell = qsm-shell),
`swww-daemon`, `wl-paste`, `power-profiles-`.

Not running: **waybar, dunst, hypridle, hyprsunset, nm-applet, blueman-applet, udiskie,
wl-clip-persist, pypr.** Notes:

- `hypridle` is **absent despite** qsm's own `hyprland.start` hook trying to start it (`pgrep -x hypridle >/dev/null || hypridle`) — worth checking.
- `swww-daemon` **is** running even though qsm's header says the shell replaces swww with its own wallpaper layer.
- `org.freedesktop.Notifications` is taken over by qsm (`scripts/notification-takeover`); dunst is retired.
- Clipboard: qsm starts its own text+image `wl-paste --watch cliphist store` pair for the launcher's `>clip` mode, but **not** `wl-clip-persist`.

### 6. Integration configs that are gone

Absent entirely — feature lost, not just dormant:

| Path | Feature lost |
| --- | --- |
| `~/.config/pypr` | pyprland `console` drop-down terminal |
| `~/.config/swaync` | swaync notification center (the dunst alternative) |
| `~/.config/satty` | screenshot annotation |
| `~/.config/libinput-gestures.conf` | **all 8 touchpad gestures** |
| `~/.config/hypr/shaders` | **all 10 screen shaders** + `hyde-shell shaders --select` |
| `~/.config/hypr/hyprlock/` | **all 8 lock layouts**; `SUPER+SHIFT+U` selector has nothing to pick |
| `~/.config/hypr/hyprsunset.conf` | hyprsunset day/night profiles |
| `~/.config/MangoHud` | game overlay config |
| `~/.config/kitty/hyde.conf` | kitty HyDE theming |
| `~/.config/fish/conf.d/hyde.fish` | fish XDG bootstrap, aliases, `Alt+n` history bind |
| `~/.config/zsh/conf.d/00-hyde.zsh`, `binds.zsh`, `functions/kb_help.zsh` | zsh env/prompt, `Ctrl+Arrow` word motion, `?`-help widget |
| `~/.config/starship/starship.toml` | HyDE prompt |

`~/.config/hypr/scripts/` now holds a single qsm-authored `screenshot` script — the three live
screenshot binds call it, not `hyde-shell screenshot`.

### 7. Present but dormant (retirable, or restorable)

`~/.local/share/waybar/` intact — **56 modules, 21 layouts, 9 menus**; `~/.config/waybar/` intact
(46 stubs, `config.jsonc`, `config.ctl` with 20+ layout rows, `includes/`, `menus/`, `modules/`,
`scripts/`, `styles/`, all CSS). `~/.config/rofi/` (`config.rasi`, `theme.rasi`, `themes/`),
`~/.config/wlogout/` (layout, icons, styles, themes), `~/.config/dunst/` (`dunstrc` +
`dunst.conf`), `~/.local/share/hyde/` (`config.toml` 7.9K defaults, `dunst.conf`, `emoji.db`,
`glyph.db`, `hyde.conf`, `hyprlock.conf`, `rofi/{assets,themes}`, `schema/`, `wallbash/`, plus
stale `hyprland.conf`/`.bak`/`keybindings.conf`), `~/.config/hyde/{themes,wallbash}` with **all
12 official themes** and the full `always/theme/scripts` wallbash set,
`~/.config/hypr/{themes,wallpapers}`, `~/.config/fastfetch/`.

### 8. Configs edited rather than removed

- `~/.config/hyde/config.toml` — reduced to a 7-line stub whose only setting is `[cava.stdout] max_instances = 2`, with a comment about "HyDE's Waybar Cava wrapper" — a qsm-era edit, not a HyDE default.
- `~/.config/hypr/hypridle.conf` — **qsm-authored**: 600 s dim → 1200 s `hyprlock` → 3000 s DPMS, `before_sleep_cmd = hyprlock`. Repo ships 60/120/300/**500 s suspend**, `$LOCK_CMD = hyde-shell lockscreen.sh`, a `$UNLOCK_CMD` cleanup and `source = ./hypridle/*`. So: no suspend-on-idle, no lockscreen indirection, no drop-in extension point.
- `~/.config/hypr/hyprlock.conf` — **qsm-authored**, `background { path = screenshot }` with the qsm palette; deliberately does *not* source HyDE's `$LAYOUT_PATH`. HyDE's boilerplate remains unreferenced at `~/.local/share/hyde/hyprlock.conf`.
