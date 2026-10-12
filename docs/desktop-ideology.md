# Desktop Ideology

QSM is a calm, keyboard-led desktop shell. It should make control available
without interrupting the focused application.

## Interaction

- The action picker is the main route into desktop control: `Super+A` then
  `>action`. Do not create parallel global shortcuts for panels or controls.
- A direct destination opens on the first Enter. A detail view exists only for
  multiple real choices or an intentional safety confirmation.
- Desktop views are frontends over reusable backend queries and commands.
  The immediate goal is easy keyboard control through the action picker and
  reachable navigation, not a backend overhaul. Reusing the same service function
  or external command is sufficient; a second Wi-Fi listing caller may invoke the
  existing command. Extract shared operation code only when another caller needs
  it, without requiring every presentation filter to become a backend API.
- Every interactive operation has a keyboard route. Components render host-owned
  state and report intent; their local interaction functions are not the backend
  API. Desktop services own execution, query results and operation outcomes. The
  action picker reuses them for network items/Wi-Fi setup, Keep awake, Night light
  and other desktop capabilities, independently of their pointer frontends.
- Lists with a focused search field preserve literal typing. Use arrow keys to
  move their selection, Enter to reveal or confirm, Delete to dismiss, Escape
  to retreat or close, and Tab only to enter visible child actions.
- On non-text surfaces, Colemak-DH Vim motions are the default vocabulary:
  `n` left, `e` down, `i` up, `o` right.

## Focus And Pointer

- Keyboard input owns selection until actual pointer movement or a deliberate
  pointer click. A resting cursor must never steal list selection.
- Transient notifications inform; they never take keyboard focus. Important
  notifications are read and managed through the searchable notification centre.
- Do not use compositor cursor hiding until it is reliable across all monitors.

## Surfaces And Motion

- Attached edge surfaces are `Rollout`. The fullscreen OSD is the explicit
  exception: a genuine `DataCapsule`, sharing the same channel content and desktop
  lifetime with its normal rollout. The canonical rollout owns extrusion,
  clipping, edge attachment, fullscreen suppression, hit regions, and shared
  entrance/retract motion.
- A rollout is one object with different content and dimensions, not a family
  of locally animated lookalikes. New rollout behavior belongs in
  `components/Rollout.qml`.
- Shared motion values belong in `theme/Motion.qml`. Local hard-coded entrance
  values are regressions.
- Motion is slight, eased, and functional: it confirms selection, reveals
  hierarchy, or explains spatial change. If it flickers, competes with reading,
  or makes a list less stable, remove it.

## Visual Language

- Use the shared spacing, type, icon, radius, and motion tokens. Do not invent
  one-off values to solve a local layout problem.
- Icons, selection marks, and spacing carry hierarchy before colour or surface
  chrome. Avoid decorative cards, hover-only discovery, and background washes.
- Prefer responsive selection feedback to ornamental animation.

## Engineering Practice

- Build the smallest viable change, show it to the owner, then iterate.
- Verify with the smallest relevant check. Reserve full validation for changes
  that justify its cost.
- Record accepted rules, rejected experiments, and newly found ideas in the
  project documentation so later work does not rediscover decisions.
