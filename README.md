# WIP Bubblewrap Sandbox

A lightweight **sandbox environment** for development using [Bubblewrap (bwrap)](https://github.com/containers/bubblewrap).  
Provides isolation from the host system while still supporting Nix builds, graphical applications (X11/GLX), and your development directories.

I am still toying with different settings, mounts and CI integrations. Your needs may differ.

This script is an adaptation from [Joachim Breitner's dev script](https://www.joachim-breitner.de/blog/812-Convenient_sandboxed_development_environment). 

---

## Features

- Isolated environment using `--unshare-all`.
- Supports running graphical apps (Foot, Neovim GUI).
- Optional project directory mirroring (`$PWD` is mounted if inside dev paths).
- Preserves user configs: `~/.config/nvim`, `~/.config/alacritty`, `~/.bin`.
- Works with Nix builds (`/nix` and nix-daemon socket accessible).
- Customizable commands (default: bash shell).

---

## Usage

### Run a shell in the sandbox

```bash
./sandbox.sh
```

### Run a specific command in the sandbox

```bash
./sandbox.sh nvim
./sandbox.sh make
./sandbox.sh ./my_script.sh
```

---

## Configuration

- **Dev directories**: modify the `DEV_PATHS` array in the script to automatically bind `$PWD` when inside certain paths.
- **User home**: `DEV_HOME` can be customized to point to your persistent development files.
- **Environment variables**: DISPLAY, container, and other env variables are set automatically.

---

## Integration with Devenv

- Add the sandbox script to your `.devenv` folder.
- Define tasks in `.devenv/tasks/` to run commands inside the sandbox:

```yaml
name: Sandbox Shell
description: Start a shell inside the bubblewrap sandbox
command: ./.dev/sandbox.sh
```

- Optional: set as default shell in `devenv.json`:

```json
{
  "shell": "./.dev/sandbox.sh"
}
```

---

## Security Notes

- **Not a full security sandbox**: X11 access and Nix daemon socket are exposed.
- Good for **trusted development workflows**.
- For running untrusted code, consider a stricter setup with `--unshare-net`, temporary `$HOME`, and minimal binds.

---

## Requirements

- [Bubblewrap](https://github.com/containers/bubblewrap)
- Linux with X11 (or modify for Wayland)
- Nix (optional, for Nix builds)

