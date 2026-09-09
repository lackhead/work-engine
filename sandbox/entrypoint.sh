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

# The ~/.cache named volume persists regenerable caches — notably pre-commit's
# per-hook environments (~/.cache/pre-commit) — across container recreates, so a
# rebuild doesn't force every hook env to re-download. Same ownership guard.
mkdir -p "$HOME/.cache"
chown "$USER_NAME:$USER_NAME" "$HOME/.cache"

# Settings come from the image (the recipe is authoritative): refresh on every
# start so the box reflects the committed seed. Login (.credentials.json) and
# transcripts (projects/) on the volume are left untouched.
install -o "$USER_NAME" -g "$USER_NAME" -m 0644 \
    /opt/sandbox/claude-settings.json "$HOME/.claude/settings.json"

# hasCompletedOnboarding lives in ~/.claude.json (NOT settings.json — Claude
# reads onboarding state only from here). Without it, the theme/welcome
# onboarding runs on launch and masquerades as an auth prompt, blocking the
# injected CLAUDE_CODE_OAUTH_TOKEN. This file lives in $HOME (not inside the
# ~/.claude volume), so a recreate resets it — but a *restart* keeps whatever
# Claude last wrote, and a flag-less file left by an earlier container slips
# past a naive "if absent" guard. So MERGE the flag on every start: preserve
# Claude's other keys when the file exists, create it minimally when it doesn't.
# Claude preserves the flag once present, so merge-on-start is sufficient.
CLAUDE_JSON="$HOME/.claude.json"
if [ -s "$CLAUDE_JSON" ] && jq -e . "$CLAUDE_JSON" >/dev/null 2>&1; then
    tmp=$(mktemp)
    if jq '.hasCompletedOnboarding = true' "$CLAUDE_JSON" > "$tmp" 2>/dev/null; then
        mv "$tmp" "$CLAUDE_JSON"
    else
        rm -f "$tmp"
    fi
else
    printf '{"hasCompletedOnboarding":true}\n' > "$CLAUDE_JSON"
fi
chown "$USER_NAME:$USER_NAME" "$CLAUDE_JSON"

# Keep PID 1 alive; `docker exec` attaches the actual sessions.
exec "$@"
