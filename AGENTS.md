# qsm-desktop agent rules (essentials)

- The owner leads the implementation loop: choose one item, think/design/build/prepare it, then report readiness with its purpose and supported states. The owner reviews it and directs revisions to that same item until acceptance. Never self-approve or advance automatically.
- **Work lands on main.** One agent, one local tree: the next item is implemented directly on the main branch and committed there. A worktree is for genuinely parallel or throwaway work only; whatever comes out of one is reviewed by the agent and merged into main before the owner ever sees it. Never hand over work that exists only in a scratch directory.
- Every UI or UX change is validated on the live composed desktop with the qsm-compuse instruments (`drive`: capture, real-frame recording, item-tree geometry equations, rendered contrast) before the owner sees it; a change no instrument can show is blocked and the instrument comes first (marketplace epic `qsm-j480`). The measurement is evidence, never acceptance: the owner judges the result. Desktop input runs on workspace 10 only. A subagent measures the desktop only in an isolated slot (`drive slot`, the shell under `dbus-run-session` with its own `XDG_STATE_HOME`), never on the owner's session: a screencopy an agent cut short there crashed Hyprland with SIGBUS and took the whole session down. Only the main agent captures the live desktop, with `DRIVE_LIVE=1`.
- A fix ships visible behaviour with before/after numbers, not a record.
- Nothing is called done from a slot capture. Before the owner hears "done", the main agent takes one live shot of the changed surface and checks the whole composed surface from the live item tree: every item on its axis, no two items overlapping, every divider between items. A rail change measured alone in a slot squeezed the top group off its axis and the owner found it first.
- The owner's words are design input, read literally and without adding use the owner did not ask for. "Scrolling" or "ring buffer" for a view means it follows the current item by itself; interaction is secondary. On a tiling window manager the rail's window list is an indicator, so keep it minimal.
- Use `openai/gpt-6-luna` at medium effort for small tasks; high effort for complex research. Keep read-only research and implementation agents narrowly scoped; the validation of a UI change is part of that change, not a separate request.
- Operate on workspace 10 only when the owner asks the agent to operate. Do not drive the pointer while the owner reviews. After review finishes, clean up only windows the agent opened; never close the owner's review window prematurely.
- Keep useful findings in the relevant spec or `docs/BACKLOG.md`. Specs describe current truth; edit existing sections in place rather than keeping decision history.
- A finding left unfixed needs a `docs/BACKLOG.md` entry with the reason it was left; a finding fixed needs none.
- Use installed `qsm-workbench --provider <desktop-root>` and `qsm-workbench session`, not sibling checkout scripts. Attach by explicit PID and confirm provider and required story through `describe`; never reuse a stale session blindly.
- **One definition, the library's.** `Theme` answers only the colour roles, fonts, mode flags, size-table presets it adds by name, and this desktop's own layout and policy. Every other number is read from `QsmShellStyle.Style`, never typed again and never read from `Tokens`; `scripts/check-theme-contract` fails when one is.
- For requested recordings, capture actual frames at 25–60 fps according to motion complexity: roughly 25 fps is enough for simple content/fades; deep, difficult animation requires genuine 60 fps. A 60-fps CFR encode with duplicated frames does not prove 60-fps capture.

## Measured platform facts

- A defaulted function parameter takes no type annotation: `function f(n: int = 0)` passes `scripts/qml-lint` but the Quickshell runtime rejects it with `Type annotations are not supported (yet)` and the shell loops on reload. Annotate only parameters without a default.
- Quickshell's hot reload can fail where a fresh start loads: a changed inline component in the library read "`Ring` is not a type" on reload, and the shell silently kept the old generation. After a library merge, read the live reload log; when it failed, restart with `scripts/qsm-run --stop` and `systemctl --user start qsm-desktop` and read the log again.
- A `ShaderEffect` renders nothing under `QT_QPA_PLATFORM=offscreen`; silhouette questions are answered from `qsm status`'s `sceneBulgeDump` and the live window.
- Hyprland's `cursor.hide_on_key_press` stays disabled (its global hide leaves the pointer visible on the external monitor and then warps it), and Hyprland has no general cursor-warp IPC.

## Essential links

- End-to-end contract + defect review: `spec/13-implementation.md`
- Interaction contract (workbench): `../qsm-workbench/docs/interaction-contract.md`
- Desktop ideology: `docs/desktop-ideology.md`
- UIX audit of the desktop, after the library: `qsd-zbo`; method and library status
  `../qsm-shell/docs/UIX-AUDIT.md`
