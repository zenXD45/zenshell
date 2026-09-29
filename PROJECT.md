# Project Status & Direction

## Decision (2026-09-29)

**Omarchy is the daily driver. HyprZen is a maintained, portable config for future use.**

The maintainer runs Omarchy as their actual desktop environment. HyprZen is
kept in a working, installable state so it can be:

- used on a non-Omarchy Arch machine,
- used as a reference for Omarchy customizations,
- forked or audited by others.

### Consequences for this repo

- **This repo is self-contained.** It must install and run on a clean Arch
  install without depending on anything from the maintainer's live machine.
- **Do not assume the live `~/.config` matches this repo.** Edits here do not
  affect a running Omarchy session until the config is installed.
- **Install correctness is a hard requirement.** A fresh `./install.sh` must
  produce a booting, working desktop. Every keybind must resolve to a binary
  the installer actually ships.
- **A theme must visibly change the desktop.** Theme variables that are defined
  but never consumed are treated as bugs, not as placeholders.

## Definition of done

A change is complete when:

1. `./install.sh` succeeds on a clean Arch install.
2. The installer's own verification pass reports zero missing dependencies.
3. Every keybind in `keybinds.lua` resolves to an installed binary.
4. Switching themes changes window geometry and decoration, not just border color.
5. `hyprctl reload` produces no entries in `hyprctl configerrors`.
