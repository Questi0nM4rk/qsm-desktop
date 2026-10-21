# 10 — Motion

## Rollout expansion

The attached contract is defined in `02-rollouts.md` and the library's normative
`docs/12-mechanism.md`. All attached callers use shared expansion in source;
there is no style selector or surface-owned reveal trajectory. This source
migration is loaded by the owner-requested desktop restart. The owner accepts
the appearance and smooth motion of all attached production surfaces; this does
not establish correctness of their service or input routes.

- Reveal uses cubic-bezier **(0.05, 0.7) / (0.1, 1.0)**; retract uses
  **(0.3, 0) / (0.2, 1)**. Neither progress curve overshoots.
- Shared library `Motion` owns LARGE **500ms**, SMALL **250ms** and existing
  reduced reveal/morph durations (**120ms**). Desktop motion vocabulary does not
  implement another Rollout trajectory.
- Attached reveal changes aperture depth around stationary full-size content.
  Free radii follow current aperture dimensions. No attached goo, independent
  content scale/fade, travelling panel or source-border sink is part of the target.
- Retract takes 80 percent of the reveal duration (`Motion.exit`): 200ms small, 400ms large.
- A surface reached by a key, the IPC or a service event (the launcher, the clipboard, the cheat
  sheet, the session column, the top panel, a level shown by the OSD) is at full depth in one frame;
  the pointer's routes (the power cell, the bell, the panel's dots, the OSD handle) keep the motion. A key-opened
  modal also leaves in one frame, and the OSD, shown at once, leaves at the exit pace when its
  timer ends. `ShellState.modalByPointer` says how the open modal was reached.
- OSD and rail popouts use the small tier. Outgoing content and dimensions survive
  close while retired actions disable immediately; hidden completion unloads them.
- One size-animation owner: target-size morph is shared **250ms**; already animated
  child extents pass through without another Rollout morph. Notification row
  entrance/eviction remains separate and is not duplicated.
- At hidden depth, the slot is neutral before removal. No parking motion, late
  border return or visibility timer follows closure. Reversal retargets current
  progress rather than restarting it.
- Reduced motion shortens the existing one-shot duration; it does not accelerate
  a loop. Detached fullscreen capsules retain their separate motion contract.

## Secondary tokens

- Popout entry-to-entry morph glide: **250ms**, `emphasizedEasing`.
- Micro-interactions (hover states, tick fades, icon swaps): **130ms**, standard
  decelerate, with their own reduced-motion durations.
- PRESS response: **80ms**, standard decelerate; RELEASE returns on the micro tier.
  Hover growth and press push remain distinct control states, not container motion.
