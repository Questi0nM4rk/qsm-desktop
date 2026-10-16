# 08 — Session / power

Reference: `references/session-panel-right.png`.

- **RATIFIED (2026-08-16, amended 2026-08-21)**: right-edge rollout, single column of action
  buttons, opened from the rail's power entry. Set top→bottom: lock, logout, hibernate,
  reboot, shutdown — mapping: hyprlock; hyprland exit; systemctl hibernate / reboot /
  poweroff. Hibernate REPLACED suspend (owner 2026-08-21): this machine hibernates rather
  than sleeps, and one path to one feature means suspend is gone, not kept beside it.
- **RATIFIED (2026-08-16)**: while open, everything else FADES BACK — desktop and windows dim
  and blur; only the rolled-out buttons stay in focus. Closing restores instantly.
- **RATIFIED (2026-08-16)**: destructive actions (shutdown/reboot/logout) CONFIRM: first
  click arms the button (visual shift), second click fires.
- **RATIFIED (2026-08-16)**: backdrop = **35%** dim overlay, genuinely blurred by the
  compositor (Hyprland layerrule blur on the overlay surface); buttons stay sharp above it.
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
  (glyph and label in `onPrimary`), distinct from both the resting `surface` tile and the
  `danger` an ARMED button takes. Each state changes the same three marks together (fill,
  glyph, label) so the button is never read twice, and armed outranks selected: what happens
  next matters more than what is picked.
- **DEFAULT (2026-08-16)**: buttons 96×72px, 8px spacing, column vertically centered on the
  right edge; icons LIVE-TUNE against `references/session-panel-right.png`.
- **DEFAULT (2026-08-16)**: an armed destructive button disarms after 3s or when the cursor
  leaves it.
- **RATIFIED (2026-10-16, owner)**: resting tiles fill with `surface` on the rollout's `band`.
  Shut down, the one destructive action, is set apart from the other four by 16 px and its
  glyph and label draw in `danger`, separated and named.
