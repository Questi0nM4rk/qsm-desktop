---
name: develop-surface
description: Use when asked to build, redesign, finish or fix one qsm-desktop surface (rail, top panel, notifications, OSD, launcher, session, frame), including "fix this popout", "the hover feels wrong", "redo the notifications" and "the colours are dull". Revise that same surface with the owner until accepted. Tests, captures and skill evaluations require an explicit request. A control that does not exist yet is a qsm-shell library task (develop-component).
---

# Develop a desktop surface

The owner repeats the same corrections every session because rulings lived only in chat. This
skill keeps the desktop's rulings where they are loaded when a surface changes. It serves one
developer who tests and judges by eye on the live shell. Surfaces are rollouts of one edge band,
so the visible rules are `spec/` (start at `spec/00-overview.md`, the surface's own file) and
`spec/13-implementation.md`; this skill adds the cases and the order, and repeats neither.
General UI rules are in `qsm-uix` (qml-ui, ui-design, ux-audit, ui-audit); library rules in
qsm-shell's `develop-component`.

## The loop

1. Choose one surface. Read its spec file and `AGENTS.md`. Say what the person finishes there.
2. Search the library before drawing anything. Everything visible comes from the qsm-shell
   library (`vendor/qsm-shell`, through `shell/QsmShell`). A missing control is a library task:
   name it and stop, never a local copy. A type named after its place (`PopoutRow`, `OsdSlider`)
   is a copy. The OSD slider is the library `Slider` wrapped; check what exists before agreeing
   something is missing.
3. Change the surface. Work lands on main, in small commits.
4. Hand over: which surface, its purpose, the states to try. Do not run tests, validation,
   captures or desktop input unless asked. Never write "fixed" or "works" for pointer, hover,
   drag, focus or animation behaviour you did not see live; write "not verified live" and list
   what the owner should try. Lint proves syntax.
5. Revise the same surface until the owner accepts. Before saying done: committed, each finding
   fixed or in `docs/BACKLOG.md`.

## Rulings that bind every surface

- **Chat beats spec.** The owner's chat ruling beats an older spec line. Edit that line in
  place in the same change and quote the owner. Never record your own call as the owner's.
- **Hover surface** (rail popouts, handles, top panel): opens on entry, stays open in the union
  of trigger, panel and the path between, closes 180 ms after leaving. Hit zones never equal the
  painted shape: the 4-dot top handle needed pixel-perfect aim. Name the state `hovered`.
- **Scrolling list** (notifications, clipboard, launcher results): the wheel always scrolls the
  list. An expandable row expands by click on its leading part, the rest of the row is its
  action. No hover-expand inside a scrolled list.
- **Repeated items** (notifications): each item has its own body, a surface step, with a slight
  shadow. A single joined divider line between items looked bad.
- **Frame edge** (`spec/01-frame.md`): not a glow line. Slight full colour exactly at the edge,
  then a gradient fading inward into the band colour, even on all sides, corners and the corners
  of an open rollout.
- **Token or colour pass**: values only. It never deletes a layout piece; list the visible
  pieces (dividers, handles, readouts) before and after. Dividers were lost this way.
- **Colours** are pastel but alive, never grey or dull. Numbers come from the owner's pick or a
  reference; show two candidates live when there is none.
- **Delegation**: the shell is UI only. Hyprlock, Hypridle, NetworkManager, BlueZ, PipeWire stay
  untouched.

## Red flags

- When a new QML file draws a `Rectangle`, `MouseArea` and `Text` for something the library
  catalog has, stop: use the library type, or file the library task.
- When you cite a spec line to remove something the screen shows, stop and ask the owner: the
  line may be older than his ruling.
- When a timer opens a surface or keeps it open, or a state is named `held`, replace it with
  the hover rule above.
- When the owner names a file (plugin, PDF, spec), open it before the first edit.

## Say it in the reply

Which surface, what changed in plain words (no internal type names without a plain phrase), what
is "not verified live" with the exact things to try, and any library task or backlog entry made.
