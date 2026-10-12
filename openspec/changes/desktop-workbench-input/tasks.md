## 1. Shared scene and isolated inputs

Implementation is integrated and the three real-provider flows pass offscreen. The owner accepted the rollout in live review. Follow-up workbench feedback covers resize scaling, copying events and missing event display metadata; those UI revisions await owner review.

- [x] 1.1 Extract RailPopoutStack and use it from EdgeScene without changing production policy or IPC.
- [x] 1.2 Replace provider state symlink with in-memory state and add deterministic service resets/fullscreen state.

## 2. Real provider input

- [x] 2.1 Replace adapter lifecycle with shared stack, expose actual control targets and native input controls/actions, environment controls and transition observables.
- [x] 2.2 Replace the three rail flows with user-outcome native-input scenarios covering nested travel/re-entry, warmth, picker, retention, suppression and reset.

## 3. Integrate and prepare owner review

- [x] 3.0 Restore live Pointer controls through the native driver and complete the existing flows with grace re-entry and interrupted-opening scenarios. No new stories or flow engine.

- [x] 3.1 Run the three real-provider flows offscreen, correct integration failures within the slice, and review production wiring. No system cursor or production restart.
- [x] 3.2 Update the short workbench usage contract and record verification limits; validate change artifacts and prepare the single rail story for owner review.

Verification: sibling workbench suite 57/57; rail-popouts-flow 61 steps, rail-popout-dismissal-flow 49 steps, rail-popout-retention-flow 64 steps, all passing. Logs: `/tmp/opencode/desktop-input/final-workbench-tests.log` and `final-rail-*.log`. Read-only final review found no blocking issue. Offscreen checks cover native Qt input and production wiring, not Wayland masks, cross-window focus or visual acceptance.

Execution is sequential. Rollout review is accepted; workbench UI follow-up review remains pending. Existing unrelated changes/worktrees remain intact. No commits unless requested.
