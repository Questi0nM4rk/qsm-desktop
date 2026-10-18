# 07 — Launcher

Reference: `references/performance-tab-launcher.png` (app list: search field at bottom,
results above, icon + name + description rows), `references/launcher-command-wallpaper-dark.png`
('>' command mode with thumbnail row).

- **RATIFIED (2026-08-16)**: bottom-center rollout; app picker exactly per the light capture —
  search at the bottom, list above, keyboard-first.
- **RATIFIED (2026-08-16)**: '>' command mode includes a THEME picker in the dark capture's
  thumbnail style — one thumbnail per installed theme (theme = palette + wallpaper pair). The
  system is N-theme-capable; it SHIPS with two (deep dark, mountain dusk) and adding a third
  later must require nothing but dropping in a theme definition. No arbitrary wallpaper
  browsing.
- **RATIFIED (2026-08-16)**: shipped '>' commands = **>calc** (live math via libqalculate,
  Enter copies result), **>clip** (cliphist search incl. image thumbnails: Enter pastes, Del
  removes), **>kill** (fuzzy window/process list, Enter kills — deliberate, no confirm),
  plus **>theme** (the picker). Power verbs rejected — the session surface owns them.
- **DEFAULT (2026-08-16)**: typing a bare '>' lists all commands; Escape, click-outside and
  launching all close; app source = XDG desktop entries, ranking = fuzzy subsequence +
  frecency; theme picker applies instantly on Enter/click.
- **DEFAULT (2026-08-16)** theme definition format: one JSON per theme (name, wallpaper path,
  token overrides over the baseline table in 11-theme) in a themes/ dir — third theme = one
  new JSON + wallpaper, zero code (07's N-theme law).
- **RATIFIED (2026-08-16, amended 2026-08-17 — caelestia numbers, owner parity ruling)**:
  width **600px**, max **7 rows**, row height **57px**.
- **RATIFIED (2026-10-19, owner, replaces the 2026-08-21 morph)**: the body keeps ONE height
  (7 rows + the search field) whatever the result count; results scroll inside it. Owner:
  "NENAVIDIM RANDOM UI JUMPING". The `>theme` carousel shares the same height.
- **RATIFIED (2026-08-21, owner)**: unselected rows recede to opacity 0.45 (row-level dim) so the row
  Enter fires on is unmistakable; `>kill` rows carry the danger color on the glyph — a kill
  list must not look like a launch list.
- **RATIFIED (2026-10-16, owner)**: the selected row is `accent` at 12 percent opacity over
  `surface` with the name in `accent`; no side marker. Rows stay 57px.
- **RATIFIED (2026-08-25, owner)**: the `>theme` carousel shares the ONE selection cursor
  (09): hovering a card SELECTS it — it becomes the centered card — and Enter applies the
  selected card, never a merely-centered other. Hover adds no growth of its own; selection
  is the response.
- **RATIFIED (2026-08-25, owner)**: `>kill` rows separate with `space3` (12px) instead of
  the standard 4px row gap — a mis-hover must not sit 4px from an irreversible kill. Enter
  still kills with no confirm (deliberate, above); the gap is the safety, not a dialog.
- LIVE-TUNE: result row anatomy details, empty states.
- **RATIFIED (2026-08-25, amended 2026-08-27, owner)**: `>action` is the keyboard view of the
  safe rail quick controls. **Super+A** toggles this seeded mode and maps it on the focused
  monitor. It fuzzy-filters the actions, shares the normal
  arrow-key selection cursor, and Enter keeps a repeatable action selected so the state change
  and the next available action stay visible. The Panel row participates in normal fuzzy ranking
  and opens the selected panel tab. Detail rows remain query-filterable. Brightness toggles
   between the remembered level and the 1% floor. Sound details expose output volume and
   mute; output volume reveals the shared horizontal Slider directly below its own row.
  Connected non-selectable dividers group results as Quick actions, Hardware, System, and Tools;
  arrow navigation skips them and centres its target so the top clip keeps Tools above Pick a
  colour. Owner live acceptance: the action window follows the focused monitor and wheel scrolling
  retains the correct divider layout. Only non-destructive, non-screen-taking rail actions belong
   in the first pass.

## Action-menu input and audio adoption

The owner changes volume or mute without leaving the action menu or losing the
selected operation. `Super+A` starts with search focus and the `>action` prefix,
so typing filters immediately. Up/Down enters menu navigation and Enter activates
the selected result; `/` returns from the menu to search. Unmodified Colemak-DH
`n/e/i/o` means left/down/up/right outside
text input. Up/Down or `i/e` move the visual cursor, including from the Slider;
Left/Right or `n/o` decrease/increase in the Slider, otherwise return/open a
detail. Enter opens the editor or returns to its row; Escape closes the editor
before retreating from the detail. Search keeps literal letters, slash, caret,
selection and clipboard shortcuts; its Up/Down returns to menu navigation.
No global shortcuts or extra speculative Vim commands.

Selection is a stable result identity, not a stale array index. State updates,
re-ranking and repeated Enter retain that identity and the active input region;
they never restore focus to search on a timeout. User filtering may choose a new
first selectable result without moving focus out of the text input: `keyboard`,
`neio`, slash, caret movement and clipboard shortcuts remain text operations.
The surface observes TextField's `focused` (the inner input), not its frame's
`activeFocus`, and does not replace the field's native focus-forwarding handler.
Entering search cancels pending focus handoffs and closes row editors. Headers
and unavailable audio actions are skipped.

The production `AudioService.setOutput` and `toggleOutputMuted` own consequences;
changing volume uses the existing unmute-on-adjust policy. Values and availability
are rendered directly from the service, not copied optimistically into results.
Mute has a named Switch; row, switch, keyboard and accessible activation use the
same operation. Output, microphone and brightness each expose an attached Slider
through the same editor route, with a live percentage, named accessible control,
availability guard and service-owned consequence. Microphone adjustment follows
unmute-on-adjust; brightness preserves its one-percent minimum. The brightness
category opens its level editor and offers a separate dim/restore operation.
Device/mixer routes remain intact. No level is copied into menu selection state.

| layer | decision | why | token or pattern | verified by |
| --- | --- | --- | --- | --- |
| posture/task | transient keyboard-led audio control for the owner | desktop ideology, accepted shell menu | existing launcher/detail path | owner changes volume then repeats mute |
| ia/interaction | search-focused opening; menu/search/editor focus regions; stable identity independent of text-input focus | typing must stay text, next Enter must operate the selected result | TextField.focused; APG/Radix selection; native Slider keys | owner types keyboard continuously, then uses arrows/Enter and returns via slash |
| hierarchy/token | one named row, editor beneath its text column | accepted menu composition, no detached second title | ListRow.expandedContent/contentInset; Slider md; Switch sm; Theme.launcherRowHeight | owner judges attachment and selected focus |
| responsive/state | bounded list, fixed heading, elided names; expansion adds only actual viewport height | keep existing 600px/max-seven-row sizing and screen clamp | ListRow headingHeight/expansionHeight, ListView and ScrollCue | owner navigates offscreen rows and absent audio |
| polish | use existing disclosure/state motion and reduced-motion handling | no new silhouette or paint mechanism | ListRow clip → layout → existing ModalHost/Rollout → registry/shader/input; unchanged screen coordinates | owner checks reveal and reduced motion |

Native accessibility names/values remain on ListRow, Slider and Switch. Pointer
drag, wheel and keyboard call the same controlled Slider route. Empty search
uses the existing EmptyState; unavailable output reports its absence and refuses
activation. No new tokens, type, backend or Workbench runtime. This implements the
owner's accepted composition rather than redesigning controls; speech and live
production behavior remain unverified until explicitly checked.

Workbench hosts this item as `action-menu-audio`: the actual LauncherSurface in
the existing bottom-attached Rollout, starting in Sound details. The parent menu
contains only Sound and commands only `>action`; ordinary app/kill/calculator and
real Bluetooth routes are not reachable. The surface accepts command/action
allowlists and optional ranking persistence, with production defaults unchanged.
Preview AudioService owns local levels, mute and availability. Delegated mixer
launches are explicitly refused, not reported as success. Controls expose output
availability, boundaries, parent/detail and reduced motion; events distinguish
surface intent from local service results. No production state or frecency file
is written. Native targets resolve the real search/menu/row/Slider objects.

The Wi-Fi detail lists available networks with signal and secured/open readings,
keeps the arm-then-confirm radio-off rule, and exposes rescan, connect and
disconnect. `NetworkService` decodes nmcli's terse escaping, coalesces duplicate
SSIDs into one row per network, disconnects the current Wi-Fi device instead of
assuming the connection name equals the SSID, and reports a real reason per exit
status. The password goes to nmcli's stdin prompt and is cleared immediately: it
is never an argument, an environment value or an event payload. Enterprise
networks delegate to NetworkManager rather than asking for a password that cannot
complete them. A secured network opens its editor beneath its own row; the editor
closes on success, keeps the field and the reason on failure, and disappears when
the network or the radio goes away.
Every dismissal route, including click-outside and replacement by another modal,
clears the editor and password immediately; an already accepted service operation
may still complete but must not reopen or refocus the dismissed editor. A rejected
service start never retains the supplied password. VPN availability follows its
own profile, not the presence of a Wi-Fi adapter; disruptive VPN-off still needs
confirmation. Busy and unavailable operations remain nonselectable.

Retirement follows the launcher's own host activation, including monitor
migration while the global modal name remains launcher. The inactive instance
clears editors/secrets and cancels only its own read-only calculator/probe and
focus/layout work. Late results cannot publish into or focus the inactive host.
Only the active host consumes a launcher seed. Intentional clipboard-copy and
application-launch consequences are not cancelled on dismissal.
Network operations and rescans have bounded deadlines. Timeout kills only the
service's own child and reports one failure; a signal-terminated process never
counts as success merely because its exit code is zero or undefined.

Glyphs use bundled names: layers for panel tabs, trash-2 for cache cleanup,
rotate-cw for rescan, network for connectivity/settings and pipette for picking
a colour. Network and pipette use the same pinned Lucide source as existing
assets. Wi-Fi rows use the Wi-Fi glyph; their Connected reading names active
state rather than requesting an absent wifi-connected asset.
The owning list supplies each row's width through the stable menu target, even
while a model replacement temporarily removes its attached ListView reference;
insertion/retirement must not evaluate a null view or collapse the row's width.

`BluetoothService` wraps Quickshell's adapter and devices so an operation's
lifetime belongs to a service, not to a menu delegate. It reports pending,
completion, failure, a vanished adapter or device, and a timeout; an unpaired
device delegates to the Bluetooth manager and no GATT control is implied. While an
operation runs the rows it could target are not selectable — unavailable and busy
are different states, and a Switch that would do nothing is disabled instead.
The Forget row keeps its distinct selection identity but reads pending/failure
from the device address used by the service; a prefixed row ID is not an operation
target. Forget still requires arm-then-confirm, including retry after failure.

Every per-kind decision is a table keyed by `kind`: the action it runs, the line
it reports, whether it can be selected, the rows its detail owns. Adding a kind
adds one entry, never another branch. Handlers are read through one
`callHandler`, never as `table[key]?.(item)`: this QML engine accepts that syntax
and then never calls the function.

The desktop Workbench carries one story per route — `action-menu-audio`,
`action-menu-wifi`, `action-menu-bluetooth`, `action-menu-toggles` — each hosting
the production launcher inside the real rollout with isolated services, plus
`panel-tabs` for the panel's tab group. `scripts/check-action-menu` drives them
through simulated Qt input. Repeated menu clicks and OSD pointer/key/action mute
pass isolated flows after waiting for reveal. That is integration evidence, not
owner acceptance: live hit testing, real hardware, pairing agents, speech output
and the live window remain unverified.

The Quick actions group also contains Disable/Enable main keyboard, backed by the
same `main-keyboard` CLI and MainKeyboardService as the rail cell above Keep awake.
Its keyboard/keyboard-off glyph mirrors the rail's enabled/disabled state.
Its Switch names "Disable main keyboard" and is checked when disabled. Click,
Switch and Enter share one toggle; pending/unavailable rows are nonselectable and
the supporting line keeps failure or recovery information visible. It neither
opens a detail nor steals the cursor when its label changes. `action-menu-toggles`
offers isolated keyboard states; it never touches real input devices.
