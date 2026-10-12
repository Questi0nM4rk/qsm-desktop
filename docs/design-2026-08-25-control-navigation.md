# Control Navigation And External Theme Bridge

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture | The rail stays auxiliary; the launcher command palette is the keyboard-first control entry. | The desktop must stay quiet while the focused application owns attention. A keyboard user needs a searchable entry without turning the rail into a second panel. | Existing launcher and rail; `>action` command mode | UX discoverability, interruption cost |
| task | Keyboard control exposes only keep-awake and night-light toggles in this pass. | They are the two non-destructive quick controls the user named. Cache cleanup remains pointer-only because its rail confirmation is load-bearing; colour pick remains pointer-owned because it takes over the screen. | `LauncherSurface.actionDefs` | UX mode and state visibility |
| interaction | `Super+A` toggles `>action`; type filters, arrows move the shared selection cursor, Enter toggles and keeps the palette open, Escape closes. | One canonical result-list keyboard contract already exists in `SearchField`. Keeping it open makes the resulting state and the next action visible; the same shortcut must also close a toggleable surface. | `ShellState.toggleLauncher`, `SearchField`, `LauncherSurface.activate` | Owner live acceptance 2026-08-27: action window follows the focused monitor; mouse-wheel scrolling and grouped dividers remain correct |
| hierarchy | The rail retains its current restrained geometry. No group, size, or visual hierarchy changes are made before the keyboard path is proven. | The current problem is reachability and external visual seams, not a need for more persistent chrome. | Existing Theme scale | UI structure and spacing |
| system | Qt portal dialogs use qt6ct and GTK dialogs receive a small qsm semantic override. | The portal picker is Qt and currently bypasses qt6ct; GTK owns polkit and standard dialogs. Both need one palette bridge instead of remaining HyDE-coloured islands. | `Theme` deep-night palette mapped to qt6ct and GTK CSS roles | UI color and contrast |
| fullscreen | The shared scene maps on the Wayland overlay layer. On fullscreen only notification popups and the event-driven right OSD are allowed; rail, handles, bar popouts, panel, launcher, clipboard, cheat sheet, and session remain hidden. | Overlay is required to appear over a fullscreen client. The strict allowlist preserves fullscreen attention and the existing click-through law. | `WlrLayer.Overlay`; fullscreen allowlist | UX interruption cost, multi-monitor |
| state | Keyboard toggles remain visible in the palette until dismissed; stale external reads reconcile after commands settle. | A control must show that it registered and what changed. | Existing service optimistic/settled state model | UX feedback |

## Not Designed

- Keyboard adjustment of night-light warmth, colour picking, cache cleanup, media, and a full keyboard rail.
- A new shell visual language, rearranged rail groups, or additional always-visible controls.
- Light-theme bridge output. This pass repairs the active deep-night desktop; the external bridge must become theme-switch-aware before the light theme can claim parity.
