#!/usr/bin/env bash
#
# entrypoint.sh — PID 1 for the isolated Claude workspace container.
#
# Runs as root so it can take ownership of the freshly-mounted ~/.claude volume
# and refresh the settings seed, then keeps the container alive — sessions attach
# via `docker exec --user clake` (see ~/work/engine/bin/sandbox and workon). Part
# of the work-system sandbox recipe; design at
# ~/work/data/items/archived/isolated-claude-workspace/.
#
# Invoked as `bash entrypoint.sh` from the Dockerfile ENTRYPOINT, so it needs no
# execute bit. $HOME is set to the host's HOME by the image's ENV, so it resolves
# correctly even though PID 1 is root.
set -eu

USER_NAME=clake

# The ~/.claude named volume holds login + transcripts and persists across
# container/image rebuilds. A fresh volume inherits the image dir's ownership,
# but guard against a pre-existing root-owned volume so the user can write to it.
mkdir -p "$HOME/.claude"
chown "$USER_NAME:$USER_NAME" "$HOME/.claude"

# Settings come from the image (the recipe is authoritative): refresh on every
# start so the box reflects the committed seed. Login (.credentials.json) and
# transcripts (projects/) on the volume are left untouched.
install -o "$USER_NAME" -g "$USER_NAME" -m 0644 \
    /opt/sandbox/claude-settings.json "$HOME/.claude/settings.json"

# Keep PID 1 alive; `docker exec` attaches the actual sessions.
exec "$@"
