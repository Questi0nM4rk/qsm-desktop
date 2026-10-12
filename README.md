<div align="center">

# `qsm-desktop`

**A Quickshell desktop shell for Hyprland: a frame band and rollouts drawn as one silhouette per monitor.**

[![license](https://img.shields.io/badge/license-GPL--3.0-blue)](./LICENSE)
[![Quickshell](https://img.shields.io/badge/Quickshell-0.3.x-7e57c2)](https://quickshell.org)
[![QML](https://img.shields.io/badge/QML-Qt%206-41cd52)](https://doc.qt.io/qt-6/qmlapplications.html)
[![Hyprland](https://img.shields.io/badge/Hyprland-compositor-58e1ff)](https://hypr.land)
[![top language](https://img.shields.io/github/languages/top/Questi0nM4rk/qsm-desktop)](https://github.com/Questi0nM4rk/qsm-desktop)
[![code size](https://img.shields.io/github/languages/code-size/Questi0nM4rk/qsm-desktop)](https://github.com/Questi0nM4rk/qsm-desktop)

</div>

## Why it exists

I like building my own stuff and owning the tools I use, and the desktop is the tool I look at all day.
Ready-made shells come with a look and a config model made by someone else, so every change is a fight with their choices.
This one is written against a spec I keep, so the spec says what the desktop does and the code follows it.
It refuses to rebuild what other tools already do: Wi-Fi, Bluetooth, audio and power stay with their own programs.
It would have no reason to exist if a shell fit the way I work without changes.

## Quickstart

Requirements:

- Arch Linux with Hyprland.
- Quickshell 0.3.x and Qt 6.
- The `qsm-shell` QML library, checked out next to this repo as `../qsm-shell`. `vendor/qsm-shell` is a relative symlink to it. `qsm-shell` is not published yet, so this repo does not run on its own.
- PipeWire, NetworkManager (`nmcli`), BlueZ. The commands the shell hands work to are listed in `shell/services/Delegate.qml`.

```bash
git clone https://github.com/Questi0nM4rk/qsm-desktop && cd qsm-desktop
qs --no-duplicate --path shell
```

This starts the shell on your live session. To stop it: `qs kill --path shell`.

Check the QML without starting the shell (needs `qsm-shell` in place):

```bash
bash scripts/qml-lint
```

`scripts/validate` stops and starts the shell and changes audio and windows. Do not run it as a pre-commit check.

More setup, the keyboard helper and the Workbench are in [docs/guide.md](docs/guide.md).

## How it works

```text
spec/      what the desktop looks like and does (the authority)
shell/     the Quickshell config: shell.qml, modules/, services/, theme/, state/
workbench/ stories and flows for qsm-workbench (isolated test windows)
scripts/   check, validate, notification bus test, supervisor
```

One scene window per monitor draws a frame band and the open rollouts together, with one shader for the outline.
Surfaces sit in `shell/modules/`: rail on the left, notifications top right, OSD and session on the right edge, top panel, and a launcher at the bottom centre.
Services in `shell/services/` wrap PipeWire, NetworkManager, BlueZ, MPRIS and notifications. They call other tools and do not replace them.
A theme is one JSON file with a palette and a wallpaper. Two ship: `deep-night` and `mountain-dusk`.
Where code and spec disagree, the spec wins.

## Numbers

[![top language](https://img.shields.io/github/languages/top/Questi0nM4rk/qsm-desktop)](https://github.com/Questi0nM4rk/qsm-desktop)
[![code size](https://img.shields.io/github/languages/code-size/Questi0nM4rk/qsm-desktop)](https://github.com/Questi0nM4rk/qsm-desktop)

| What | How to measure |
| --- | --- |
| QML files and code lines in `shell/` and `workbench/` | `scc --no-cocomo --include-ext qml shell workbench` |
| Spec files in `spec/` | `ls spec/*.md \| wc -l` |

Commits include agent-authored work under my identity; design, orchestration and review are mine.

## Status

- **Works:** it runs on the author's Arch and Hyprland desktop. Rail, notifications, OSD, top panel, launcher and session surfaces exist.
- **Experimental:** most work is source-reviewed and waits for owner review on the live desktop. See [docs/BACKLOG.md](docs/BACKLOG.md).
- **Known gaps:**
  - It needs the unpublished `qsm-shell` library next to it.
  - `scripts/qml-lint` fails against its committed baseline. The baseline is out of date.
  - Spec references to screenshots point to images that are not distributed. See [spec/references/README.md](spec/references/README.md).
  - The default wallpapers are plain gradients. Put your own image in `shell/assets/wallpapers/` and set it in a theme file.
  - Tested on one machine only.

## License

[GPL-3.0](LICENSE)
