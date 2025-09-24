#!/usr/bin/env bash
#
# sandbox.sh — Start a sandboxed shell or command inside bubblewrap (bwrap).
#
# Features:
# - Mostly isolated environment with selective host mounts
# - Preserves dev directories when inside certain paths
# - Supports graphical/X11 apps (Foot, Neovim GUI)
#
# Caveats:
# - Grants access to /etc and /nix (needed for Nix)
# - Access to nix-daemon socket is required
# - Exposes X11 display

set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
DEV_HOME="$HOME/.dev-home"

# Directories where sandbox mirrors current working directory
DEV_PATHS=(
  "$HOME/build"
  "$HOME/projekte/programming"
)

# -----------------------------------------------------------------------------
# DETERMINE EXTRA BINDINGS
# -----------------------------------------------------------------------------
extra=()
for path in "${DEV_PATHS[@]}"; do
  if [[ "$PWD" == "$path"* ]]; then
    extra+=(--bind "$PWD" "$PWD" --chdir "$PWD")
    break
  fi
done

# -----------------------------------------------------------------------------
# DETERMINE COMMAND
# -----------------------------------------------------------------------------
if [[ $# -gt 0 ]]; then
  cmd=( "$@" )
else
  cmd=( bash )
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
  --ro-bind /sys/dev/char /sys/dev/char
  --ro-bind /sys/devices/pci0000:00 /sys/devices/pci0000:00
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
  --bind "$DEV_HOME" "$HOME"
  --ro-bind ~/.config/foot ~/.config/foot
  --ro-bind ~/.config/nvim ~/.config/nvim
  --ro-bind ~/.local/share/nvim ~/.local/share/nvim
  # --ro-bind ~/.bin ~/.bin
)

# X11 access
x11_opts=(
  --bind /tmp/.X11-unix/X0 /tmp/.X11-unix/X0
  --bind ~/.Xauthority ~/.Xauthority
  --setenv DISPLAY :0
)

# -----------------------------------------------------------------------------
# RUN BUBBLEWRAP
# -----------------------------------------------------------------------------
exec bwrap \
  --unshare-all \
  "${base_opts[@]}" \
  "${graphics_opts[@]}" \
  "${system_opts[@]}" \
  "${user_opts[@]}" \
  "${x11_opts[@]}" \
  --setenv container dev \
  "${extra[@]}" \
  -- \
  "${cmd[@]}"

