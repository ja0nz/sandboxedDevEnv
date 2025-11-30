# WIP Bubblewrap Sandbox

`sandbox.sh` is a lightweight shell script to start a **sandboxed shell or command** inside [Bubblewrap (bwrap)](https://github.com/containers/bubblewrap).  
It is designed for development environments with selective isolation while still allowing access to essential system resources, Nix, and user configurations.

I am still toying with different settings, mounts and CI integrations. Your needs may differ.

This script is an adaptation from [Joachim Breitner's dev script](https://www.joachim-breitner.de/blog/812-Convenient_sandboxed_development_environment). 

---

## Features

- Mostly isolated environment with selective host mounts
- Preserves development directories when inside specific projects
- Supports **Wayland/GLX applications** (e.g., Alacritty, Foot)
- Integrates seamlessly with **direnv** for project-specific overrides
- Allows mixing global and project `.config` entries

---

## How it Works

- **Home Directory (`$HOME`)**: Temporarily isolated via `--tmpfs`, with global configs (`fish`, `foot`, `helix`) mounted read-only.
- **Project Configs**: If inside a `direnv`-allowed directory, any `.config` in the project is synced with global configs and mounted into the sandbox.
- **System Access**: Provides read-only access to `/nix`, `/bin`, `/usr`, `/etc` and `/run/current-system`.
- **Graphics**: Mounts `/dev/dri` and `/run/opengl-driver` for GUI/Wayland support.

---

## Direnv Integration

When you are in a **direnv-allowed directory**:

1. The script automatically detects the allowed `.envrc`.
2. It binds the current working directory into the sandbox.
3. It ensures `$PWD/.config` exists and **syncs global configs** (`fish`, `foot`, `helix`) into it.
4. The project `.config` is then mounted into the sandbox, giving you a flat `$HOME/.config` containing both global and project-specific configurations.

---

## Usage

### Run sandbox in a directory of you choice

If in a direnv directory, you will drop into a **read and write** allowed sandboxed environment
If not in a direnv directory, you will drop in a **read only** sandboxed environment

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

- GLOBAL_CONFIGS:
```bash
GLOBAL_CONFIGS=(foot fish helix)
```

List of global .config directories that are synced and mounted read-only into the sandbox.

- Command:
Any command passed to sandbox.sh will be executed inside the sandbox.
Defaults to fish if no command is provided.

---

## Security Notes

- **Not a full security sandbox**: Nix daemon socket are exposed.
- Good for **trusted development workflows**.
- For running untrusted code, consider a stricter setup with `--unshare-net` and minimal binds. See [Bubblewrap man pages](https://manpages.debian.org/experimental/bubblewrap/bwrap.1.en.html)

---

## Requirements

- [Bubblewrap](https://github.com/containers/bubblewrap)
- Linux
- Nix (optional, for Nix builds)
