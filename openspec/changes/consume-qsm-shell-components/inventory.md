# qsm-shell component inventory (tasks 2.1–2.3)

## Scope and terminology

This is a filesystem inventory, not a migration. “Direct consumer” means a QML
instantiation or JavaScript import of the local entry; a component's children
are recorded as composition, not counted as a second consumer. Preview QML is
included because it is an executable consumer. All paths below are relative to
the qsm-desktop root unless the path starts with `../qsm-shell`.

Import resolution has two measured hosts. Quickshell 0.3.1 maps the leading
`qs` namespace directly to its config root and therefore requires
`shell/QsmShell`; plain Qt tools resolve the same URI through qsm-shell's own
`qml/qs/QsmShell` projection when `vendor/qsm-shell/qml` is on their import
path. A `shell/qs/QsmShell` desktop projection is valid only for the latter and
is not the runtime contract.

Desktop style remains consumer-owned: `Theme` is dynamic (`ShellState.theme`,
`ShellState.reducedMotion`, and the theme list; `shell/theme/Theme.qml:16-29`),
and `ShellState` owns keyboard/modal state (`shell/state/ShellState.qml:59-61`).
The concrete prerequisite for using shared visual components is a
`qs.QsmShell.Style.Style.backend` object exposing the active desktop palette,
font families, surface/disabled opacity, reduced-motion values, and the compact
control plus level-track/thumb geometry—not merely accepting the qsm-shell
deep-night fallback tokens. The backend hook and fallback are
defined at `../qsm-shell/qml/QsmShell/Style/Style.qml:8-44`.

Dependency labels used below are exactly: **style**, **asset/icon resolution**,
**state**, **service**, **monitor/focus**, **scene/rollout**, **none**.

## Local entries and consumer mapping (15)

| Local entry and direct consumers | Local composition and meaningful roots/transitive consumers | qsm-shell API, compatibility, desktop dependency |
|---|---|---|
| `SectionLabel.qml` — `modules/bar/SoundPopoutContent.qml:29,80`; `modules/bar/NetworkPopoutContent.qml:504,527`; preview `FoundationPreview.qml:55,123,184` | `Text` only; roots are the sound/network popout and foundation preview. | `qs.QsmShell.Components.SectionLabel` (`qmldir:22`), a `Text` with no declared API (`Components/SectionLabel.qml:1-3`). Close visual counterpart, but the shared type reads Style rather than the local Theme singleton. **style**; candidate after backend. |
| `LevelBar.qml` — `modules/bar/SoundPopoutContent.qml:63`; `modules/bar/BarPopouts.qml:339`; `modules/panel/MediaTab.qml:185` | `Item` + track/fill/thumb + `MouseArea` + `WheelHandler`; roots are sound, bar popout, and media seek/level UI. Host owns `value`; `moved` is the service/state handoff (`LevelBar.qml:13-26`). | `LevelBar` (`qmldir:23`) has the same `value`, `wheelStep`, `fill`, `moved` shape (`qsm-shell/.../LevelBar.qml:8-15`), but its Style geometry must be backend-compatible. **style, service, state**; interaction cohort, not leaf. |
| `SearchField.qml` — `modules/cheatsheet/CheatSheetSurface.qml:148`; `modules/clipboard/ClipboardSurface.qml:180`; `modules/panel/NotificationCenterTab.qml:131`; `modules/launcher/LauncherSurface.qml:752` | Filled `Rectangle`, `TextInput`, nested `SvgIcon`; owns focus and key routing to list signals and calls `ShellState.claimKeyboardSelection()` (`SearchField.qml:21-48,104-163`). Roots are four keyboard-driven surfaces. | Public `SearchField` (`qmldir:7`) has matching named properties/signals plus an extra `selectionClaimed` signal (`qsm-shell/.../SearchField.qml:8-29`). **Not a drop-in**: shared keyboard ownership/selection contract differs; desktop state dependency remains. **style, state, monitor/focus**; explicitly excluded until reconciled. |
| `ResultRow.qml` — `modules/clipboard/ClipboardSurface.qml:217` (delegate); `modules/launcher/LauncherSurface.qml:713` (delegate) | Result model row with header mode, thumbnail, local `AppIcon`, glyph `SvgIcon`, animation, and `StateLayer` (`ResultRow.qml:23-45,96-147,223-239`). Roots are launcher and clipboard list selection. | Public `ResultRow` (`qmldir:8`) has `item`, `selected`, `compact`, `header`, `danger`, activation/hover API (`qsm-shell/.../ResultRow.qml:9-15`). **Not a drop-in**: shared header/danger semantics and centralized selection behavior do not match the local model contract. **style, asset/icon resolution, state**; excluded. |
| `ModalHost.qml` — `screen/EdgeScene.qml:1086,1111,1131` | Full-scene catch `MouseArea` + nested local `Rollout`; requires `scene`/`name`, registers `<name>-catch`, and drives `ShellState` (`ModalHost.qml:22-75,102-113`). Root is `EdgeScene`, with three modal surfaces. | **No qsm-shell public type by design**; `qmldir` has no ModalHost. Keep local. **scene/rollout, monitor/focus, state**; excluded pending a future public contract. |
| `Rollout.qml` — `screen/EdgeScene.qml:1213,1227,1244,1258`; `modules/session/SessionSurface.qml:110`; `modules/notifications/NotificationPopupStack.qml:141`; `modules/osd/OsdSurface.qml:29`; `modules/panel/PanelSurface.qml:65` (and composed by `ModalHost.qml:62`) | Scene-owned extrusion, silhouette/bulge and hit-region registries, fullscreen suppression, animation and goo; requires `scene` and `rolloutId` (`Rollout.qml:24-70,160-168,263-293`). Roots are all edge surfaces and `EdgeScene`. | **No qsm-shell public type by design**; no Rollout in `qmldir`. Keep local; it is not a generic visual primitive. **scene/rollout, monitor/focus, state**; excluded. |
| `MonthCalendar.qml` — `modules/panel/DashboardTab.qml:443`; composed local buttons at `MonthCalendar.qml:27,48` | Month state, keyboard/wheel shifting, 42-cell grid and two local `IconButton`s (`MonthCalendar.qml:8-22,23-55,77-123`). Root is dashboard calendar. | Public `MonthCalendar` (`qmldir:5`) has `shown`, `today`, `monthShifted`, not the local readonly `today` nor local-only child-button behavior (`qsm-shell/.../MonthCalendar.qml:12-16`). **Mismatch**: consumer must handle `monthShifted` and date ownership. **style, state**; lists/controls cohort, not drop-in. |
| `PopoutRow.qml` — `modules/bar/BluetoothPopoutContent.qml:62`; `ColorPickContent.qml:373`; `NetworkPopoutContent.qml:312,513,536`; `SoundPopoutContent.qml:34,85` | Marked selectable row with two `SvgIcon`s, local `StateLayer`, optional local `IconButton`, and clicked/action signals (`PopoutRow.qml:20-45,70-83,85-143`). Roots are device/network/color/audio popouts. | Public `PopoutRow` has the same declared properties/signals (`qmldir:6`; qsm-shell `PopoutRow.qml:10-20`) and close composition, but shared layer uses its own row reference and Style. **style**; service/state callbacks remain desktop-owned; eligible only after backend and callback parity. |
| `Card.qml` — `modules/panel/DashboardTab.qml:26,155,198,392,436,451`; `modules/panel/PerformanceTab.qml:128,160,185,222,259,409`; previews `QsmShellImport.qml:9`, `PaletteCard.qml:6`, `FoundationPreview.qml:82,114,153`; composed by `Capsule.qml:5` | Flat `Rectangle` with `surfaceColor`/`surfaceOpacity` (`Card.qml:17-25`); roots are dashboard/performance cards and previews, and it is the base of local Capsule. | Public `Card` has the same two properties (`qmldir:3`; qsm-shell `Card.qml:6-7`). **Close API match**, but colors default through Style, so migration requires the active Style backend. **style**; first leaf candidate (retain local source for rollback). |
| `IconButton.qml` — `modules/bar/ColorPickContent.qml:175`; `modules/bar/NetworkPopoutContent.qml:438`; `modules/panel/MediaTab.qml:210,218,225,231,238`; `modules/osd/OsdSlider.qml:203`; composed by `MonthCalendar.qml:27,48` and `PopoutRow.qml:131` | `Item` + local `SvgIcon` + local `StateLayer`, `clicked`, padded target (`IconButton.qml:12-19,30-47`). Roots are color/network/media/OSD controls and transitive calendar/popout controls. | Public API matches (`qmldir:21`; qsm-shell `IconButton.qml:8-12`), but visual defaults use Style and the nested shared primitives. **style**; interaction cohort after leaf/backend proof. |
| `SvgIcon.qml` — direct consumers `screen/EdgeScene.qml:945`; `modules/session/SessionButton.qml:56`; `modules/panel/StatRing.qml:70`; `modules/panel/DashboardTab.qml:64,86,135,172,230,307,351,365,376`; `modules/panel/MediaTab.qml:96`; `modules/panel/PanelSurface.qml:124`; `modules/panel/PerformanceTab.qml:40,87,273,329,369`; `modules/notifications/NotificationCard.qml:183`; `modules/bar/ColorPickContent.qml:344`; `modules/osd/OsdSlider.qml:217`; `modules/bar/RailAppList.qml:33`; `RailDeviceCell.qml:72`; `BarPopouts.qml:333,348`; `SoundPopoutContent.qml:57`; `MenuRow.qml:42,59`; `BatteryPopoutContent.qml:119,258`; `RailEntry.qml:78`; `NetworkPopoutContent.qml:375,424`; previews `FoundationPreview.qml:173`, `PaletteCard.qml:42`; and composed local `Capsule.qml:47`, `IconButton.qml:30`, `ResultRow.qml:137`, `SearchField.qml:72`, `PopoutRow.qml:91,112` | Image + `MultiEffect`; resolves `assets/icons/<name>.svg` through `Quickshell.shellPath` and colorizes (`SvgIcon.qml:10-38`). The many roots include panel, bar, OSD, notification, session, scene, and previews. | Public API is the same `name`, `size`, `color` surface (`qmldir:20`; qsm-shell `SvgIcon.qml:11-13`); explicit desktop name/size/color bindings remain consumer-owned, while the shared type resolves against its own bundled assets. The two repositories have an exact 79-filename SVG set. **style, asset/icon resolution**; eligible after the Style backend. |
| `AppIcon.qml` — `modules/bar/RailAppList.qml:127`; `modules/panel/WorkspacesTab.qml:118`; composed by `ResultRow.qml:115` | `IconImage` resolves class → `DesktopEntries` → declared icon → `Quickshell.iconPath`, with application fallback (`AppIcon.qml:12-29`). Roots are rail/workspaces and launcher/clipboard result rows. | Public `AppIcon` accepts consumer-resolved `sourceUrl` and `fallbackSource` (`qmldir:4`; qsm-shell `AppIcon.qml:6-7`). **Not a drop-in**: local owns DesktopEntries/icon resolution while shared expects the consumer to resolve it. **asset/icon resolution, service**; excluded until adapter exists. |
| `StateLayer.qml` — direct consumers `modules/session/SessionButton.qml:74`; `modules/launcher/ThemeCard.qml:82`; `modules/panel/PanelSurface.qml:161`; `modules/bar/BatteryPopoutContent.qml:265`; `ColorPickContent.qml:141,356`; `RailAppList.qml:169`; `Rail.qml:156`; `MenuRow.qml:68`; `RailEntry.qml:113`; `modules/notifications/NotificationCard.qml:304`; plus composed `IconButton.qml:38`, `ResultRow.qml:223`, `Capsule.qml:72`, `PopoutRow.qml:73` | Hover/press handlers, target transform, response and click (`StateLayer.qml:18-45,47-71`). Roots span all interactive bar/panel/session/notification/launcher controls. | Public API matches (`qmldir:2`; qsm-shell `StateLayer.qml:8-15`). **Close**, but all visual timing/color token access is Style/Motion and callbacks stay consumer-owned. **style, state**; interaction cohort. |
| `Capsule.qml` — `modules/bar/BluetoothPopoutContent.qml:31,43,90`; `NetworkPopoutContent.qml:257,272,548`; `SoundPopoutContent.qml:104`; `modules/panel/DashboardTab.qml:124`; `MediaTab.qml:259`; `NotificationCenterTab.qml:158,165`; previews `FoundationPreview.qml:73,92,93,95,96,97,98,206,207,208` | Extends local Card; row with local SvgIcon/Text/detail and local StateLayer (`Capsule.qml:5-15,40-79`). Roots are popout/panel/notification surfaces and preview. | Public API matches (`qmldir:19`; qsm-shell `Capsule.qml:9-17`). **Close**, but nested shared Card/Icon/StateLayer and dynamic Style backend are prerequisites. **style, state, service**; interaction cohort, after Card. |
| `fuzzy.js` — imports `modules/cheatsheet/CheatSheetSurface.qml:7`; `modules/clipboard/ClipboardSurface.qml:9`; `modules/launcher/LauncherSurface.qml:10` (calls at cheatsheet `70`, clipboard `75`, launcher `119,253,266,278,294,319`) | `.pragma library` fuzzy subsequence scorer with optional `maxSpan` (`fuzzy.js:1-38`); roots are cheatsheet, clipboard, launcher filtering. | qsm-shell ships `Components/fuzzy.js` internally, but it is **not a public qmldir type** (`qsm-shell/.../fuzzy.js:1-3`, public list below). Keep local; no public API. **none** (algorithm is consumer-local and has no desktop backend). |

`Card`'s `screen/EdgeScene` mention is a comment, not a consumer; all other
entries above are instantiations/imports found by the search described below.

## Public qsm-shell set: all 22 types

The complete non-module set is `../qsm-shell/qml/QsmShell/Components/qmldir:2-23`.
The 12 names that have local counterparts are mapped above. The remaining
public types are deliberately distinguished from migration work:

| Public type (qmldir line) | Desktop counterpart/consumer and API comparison |
|---|---|
| `OsdSlider` (`:9`) | Feature counterpart `shell/modules/osd/OsdSlider.qml:203-224`; it is a vertical service-bound slider with icon/readout and scene surface context, not a local `LevelBar` drop-in. **No current local-component counterpart; not migration work.** |
| `NotificationCard` (`:10`) | Feature counterpart `shell/modules/notifications/NotificationCard.qml:183,304`; desktop card owns notification data, dismissal and urgency state. Shared API is title/body/source/icon/accent/danger/selected/expanded (`qsm-shell/.../NotificationCard.qml:17-28`), so same-name feature code is not a drop-in. **No local counterpart; not migration work.** |
| `SessionButton` (`:11`) | Feature counterpart `shell/modules/session/SessionButton.qml:56,74`; shared has confirmation/armed/selected API (`qsm-shell/.../SessionButton.qml:10-26`) while feature code owns session actions. **No local counterpart; not migration work.** |
| `Menu` (`:12`) | No current `Menu` consumer or counterpart (desktop has `modules/bar/MenuRow.qml:42-68`, which is not the shared model/delegate/keyboard `Menu` API). **No counterpart/consumer.** |
| `MenuRowItem` (`:13`) | No current `MenuRowItem`; `modules/bar/MenuRow.qml` is a different component and is not a drop-in. **No counterpart/consumer.** |
| `TabStrip` (`:14`) | No current `TabStrip`; panel tabs are individually composed in `DashboardTab.qml`, `MediaTab.qml`, and `NotificationCenterTab.qml`. Shared requires `labels/currentIndex` (`qsm-shell/.../TabStrip.qml:9-12`), so there is no proven counterpart. **No counterpart/consumer.** |
| `StatRing` (`:15`) | Feature counterpart `shell/modules/panel/StatRing.qml:70`; shared is value/color/label/reading/size (`qsm-shell/.../StatRing.qml:6-10`) while the feature component includes desktop metric composition. **Not a drop-in; no local counterpart.** |
| `Divider` (`:16`) | No current `Divider` type consumer; local separators are inline `Rectangle`s (for example `ResultRow.qml:198-220`). **No counterpart/consumer.** |
| `EmptyState` (`:17`) | No current `EmptyState` type consumer; no feature module counterpart found. **No counterpart/consumer.** |
| `KeyValueRow` (`:18`) | No current `KeyValueRow` type consumer; no feature module counterpart found. **No counterpart/consumer.** |

The public module also includes `qs.QsmShell.Style`: its singleton/backend
surface is documented at `../qsm-shell/qml/QsmShell/Style/Style.qml:8-44`.
It is a prerequisite API, not a replacement for qsm-desktop's dynamic
`Theme`/`ShellState` ownership.

`ModalHost`, `Rollout`, and `fuzzy.js` are intentionally not public QML types:
the first two are absent from `qmldir`, while the last is internal library
support and absent from the public type list. They are therefore locked local
unless a future public contract is proposed.

## Locked migration cohorts

Membership is intentionally small and dependency ordered. Every cohort retains
the local file so rollback is an import reversal; no redesign is implied.

1. **Leaf presentation (first, reversible): `Card`, `SectionLabel`.**
   Prerequisites: Style backend wired to the active `Theme` values (including
   dynamic theme changes), import projection smoke, and visual parity for the
   listed preview/card/label consumers. Exclusions: all nested/interactive
   types, `AppIcon`, and scene-bound types. `Card` is the concrete first leaf;
   one consumer at a time is eligible, with local imports immediately
   restorable.
2. **Icon leaf, after cohort 1: `SvgIcon`.** Prerequisites: the same Style
   backend plus proven `assets/icons` resolution under the shared import root.
   The public API and all 79 bundled asset filenames match, so static and
   dynamic final-name consumers are in one reversible cohort. Exclusion:
   `AppIcon` (its DesktopEntries ownership is incompatible).
3. **Interaction primitives: `StateLayer`, `IconButton`, `Capsule`, `LevelBar`.**
   Prerequisites: cohorts 1–2, token/motion parity, and explicit callback
   tests for service-owned values. Exclusions: `SearchField`, `ResultRow`,
   `AppIcon`, `MonthCalendar`, `PopoutRow` until their list/asset/state
   mappings are complete.
4. **Lists/controls (only per completed mapping): `PopoutRow`, then
   `MonthCalendar`.** Prerequisites: interaction cohort, service callback
   ownership, and date/keyboard contract comparison. Exclusions: local
   `SearchField` and `ResultRow` (centralized keyboard/selection mismatch),
   plus all public feature-only types with no desktop consumer.
5. **Deferred adapters, not currently eligible: `SearchField`, `ResultRow`,
   `AppIcon`, `ModalHost`, `Rollout`.** They require a new explicit keyboard,
   asset-resolution, or scene/rollout adapter contract. No cohort silently
   treats them as drop-ins. `fuzzy.js` remains local outside the cohorts.

Thus public-only `OsdSlider`, `NotificationCard`, `SessionButton`, `Menu`,
`MenuRowItem`, `TabStrip`, `StatRing`, `Divider`, `EmptyState`, and
`KeyValueRow` are not migration tasks merely because qsm-shell publishes them;
there is no current local consumer mapping that qualifies them.

## Completeness and verification

- Observed local set: **15 direct entries = 14 `.qml` + 1 `fuzzy.js`**. It was
  obtained with `glob 'shell/components/*'`, then compared name-for-name with
  the table above.
- Observed public set: **22 QML types**, from every non-`module` line in
  `qsm-shell/qml/QsmShell/Components/qmldir:2-23`; compared with the 22 rows/
  mappings above (12 local counterparts + 10 shared-only).
- Direct consumers were rechecked with exact-name `rg` searches over
  `shell/**/*.qml` and `shell/**/*.js`, followed by instantiation/import
  filtering; composition is separately cited so comments are not counted.
- Required gate: `openspec validate consume-qsm-shell-components --type change --strict --no-interactive`.
- This artifact changes planning evidence only; no production QML or scripts
  are changed and no production tests are required for this chunk.
