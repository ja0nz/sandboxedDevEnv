#!/usr/bin/env bash
#
# sandbox.sh — Start a sandboxed shell or command inside bubblewrap (bwrap).
#
# Features:
# - Mostly isolated environment with selective host mounts
# - Preserves dev directories when inside certain paths
#
# Caveats:
# - Grants access to /etc and /nix (needed for Nix)
# - Access to nix-daemon socket is required

set -euo pipefail

# -----------------------------------------------------------------------------
# DETERMINE EXTRA BINDINGS BASED ON DIRENV
# -----------------------------------------------------------------------------
# This block handles project-specific .config overlays when running inside
# a directory allowed by direnv. It ensures:
#   1. The project .config exists.
#   2. Global configs (foot, fish, helix) are synced into the project .config.
#   3. The project .config is bind-mounted into the sandbox home.
extra=()

# List of global configs to sync and mount read-only
GLOBAL_CONFIGS=(foot fish helix)

if command -v direnv >/dev/null 2>&1; then
    if [[ $(direnv status | grep "Loaded RC allowed" | awk '{print $4}') -eq 0 ]]; then
        # Bind current directory and set working directory
        extra+=(--bind "$PWD" "$PWD" --chdir "$PWD")

        # Ensure project .config / .local exists
        [[ -d "$PWD/.config" ]] || mkdir -p "$PWD/.config"
        [[ -d "$PWD/.local" ]] || mkdir -p "$PWD/.local"

        # Sync global configs into project .config (only if missing)
        for cfg in "${GLOBAL_CONFIGS[@]}"; do
            src="$HOME/.config/$cfg"
            dst="$PWD/.config/$cfg"
            if [[ -d "$src" && ! -e "$dst" ]]; then
                cp -a "$src" "$dst"
            fi
        done

        # Bind project .config / .local into sandbox home
        extra+=(--bind "$PWD/.config" "$HOME/.config")
        extra+=(--bind "$PWD/.local" "$HOME/.local")
    fi
fi

# -----------------------------------------------------------------------------
# DETERMINE COMMAND
# -----------------------------------------------------------------------------
# Default to 'fish' if no command is supplied
if [[ $# -gt 0 ]]; then
    cmd=( "$@" )
else
    cmd=( fish )
fi

# -----------------------------------------------------------------------------
# OPTION GROUPS
# -----------------------------------------------------------------------------

# Base system mounts
base_opts=(
    --share-net
    --proc /proc
    --dev /dev
    --tmpfs /tmp
    --tmpfs /run/user/1000
)

# Graphics support for GLX apps (e.g., Alacritty)
graphics_opts=(
    --dev-bind /dev/dri /dev/dri
    --ro-bind /run/opengl-driver /run/opengl-driver
)

# System binaries + Nix
system_opts=(
    --ro-bind /bin /bin
    --ro-bind /usr /usr
    --ro-bind /run/current-system /run/current-system
    --ro-bind /nix /nix
    --ro-bind /etc /etc
    --ro-bind /run/systemd/resolve/stub-resolv.conf /run/systemd/resolve/stub-resolv.conf
)

# User environment
user_opts=(
    --tmpfs "$HOME"
    --ro-bind ~/.nix-profile ~/.nix-profile
    --ro-bind ~/.local/share/direnv ~/.local/share/direnv
    --ro-bind ~/bin ~/bin
)

# Mount global configs read-only in home
for cfg in "${GLOBAL_CONFIGS[@]}"; do
    src="$HOME/.config/$cfg"
    dst="$HOME/.config/$cfg"
    [[ -d "$src" ]] && user_opts+=(--ro-bind "$src" "$dst")
done

# -----------------------------------------------------------------------------
# RUN BUBBLEWRAP
# -----------------------------------------------------------------------------
exec bwrap \
    --unshare-all \
    "${base_opts[@]}" \
    "${graphics_opts[@]}" \
    "${system_opts[@]}" \
    "${user_opts[@]}" \
    --setenv container dev \
    "${extra[@]}" \
    -- \
    "${cmd[@]}"
