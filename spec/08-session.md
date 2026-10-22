# 08 — Session / power

Reference: `references/session-panel-right.png`.

- **RATIFIED (2026-08-16, amended 2026-08-21)**: right-edge rollout, single column of action
  buttons, opened from the rail's power entry. Set top→bottom, grouped by consequence: lock,
  hibernate (the session survives), then log out, restart, shut down (the session ends), the
  two groups a full step (16px) apart — mapping: hyprlock; systemctl hibernate; hyprland exit;
  systemctl reboot / poweroff. Hibernate REPLACED suspend (owner 2026-08-21): this machine hibernates rather
  than sleeps, and one path to one feature means suspend is gone, not kept beside it.
- **RATIFIED (2026-08-16)**: while open, everything else FADES BACK — desktop and windows dim
  and blur; only the rolled-out buttons stay in focus. Closing restores instantly. Opened by a
  key or the IPC, the column, the dim and the rail's fade are all at full depth in one frame (the
  compositor's blur follows a frame later); opened from the power cell they take the rollout's
  motion (10-motion).
- **RATIFIED (2026-08-16)**: destructive actions (shutdown/reboot/logout) CONFIRM: first
  click arms the button (visual shift), second click fires.
- **RATIFIED (2026-08-16)**: backdrop = the library's scrim (`scrimOpacity`) over a background
  genuinely blurred by the compositor (Hyprland layerrule blur on the overlay surface); buttons stay sharp above it.
- **RATIFIED (2026-08-16)**: buttons **96px** wide; Escape and click-outside both close.
- **RATIFIED (2026-08-24, owner)**: the column is KEYBOARD-DRIVEN as well as pointer-driven.
  Up/Down move the selection, Enter or Space activates it, Escape closes. Activation runs the
  SAME arm-then-fire as a click, so a destructive action costs two presses exactly as it
  costs two clicks (09 one-path: keyboard and pointer driving one control is one path).
  Hover WRITES the same selection, so one mark is on screen rather than a hover highlight
  racing a keyboard highlight. Opening always selects **Lock** with nothing armed — a power
  column that reopens on shutdown is one stray Enter from a very bad afternoon — and moving
  the selection off an armed button disarms it, the same as the cursor leaving does.
- **RATIFIED (2026-08-24, amended 2026-10-16, owner)**: the selected button reads in `primary`
  (glyph and label in `textOnPrimary`), distinct from both the resting `surface` tile and the
  `danger` an ARMED button takes. Each state changes the same three marks together (fill,
  glyph, label) so the button is never read twice, and armed outranks selected: what happens
  next matters more than what is picked.
- **DEFAULT (2026-08-16)**: buttons 96×72px, 8px spacing, column vertically centered on the
  right edge; icons LIVE-TUNE against `references/session-panel-right.png`.
- **RULED (2026-10-22, owner)**: placement is measured from the monitor, never from the frame
  band beside it. The body runs to the monitor's right edge (`Rollout.edgeInset: 0`) and is
  112 wide (`tileWidth` + 2 x `Theme.edgeGutter`), so the tiles sit 8px from the monitor and
  8px from the silhouette's other edge, and 8px from its top and bottom.
- **DEFAULT (2026-08-16)**: an armed destructive button disarms after 3s or when the cursor
  leaves it.
  The armed tile names its next press: its label is the verb with a question mark ("Shut
  down?") while armed. Fill alone separated armed from selected by hue only. The arm is the library's `ArmedAction`, one per tile.
- **RATIFIED (2026-10-16, owner)**: resting tiles fill with `surface` on the rollout's `band`.
  Shut down, the last and least reversible action, draws its glyph and label in `danger` at
  rest.
