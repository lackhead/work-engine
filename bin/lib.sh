#!/usr/bin/env bash
#
# lib.sh — shared boilerplate for the work-engine user-facing bin scripts.
#
# Sourced (never executed) via:
#     source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# which resolves to this file in the script's own bin/ dir regardless of how the
# script was invoked — bare name on $PATH, an explicit path, host or sandbox
# container — because lib.sh always ships alongside the scripts (same repo, same
# `git pull`). Provides the WORK root, the canonical output functions, and the
# small shared helpers.
#
# NOT sourced by the hooks (work-session-breadcrumb/-catchup), work-backup, or
# claude-statusline: those run in constrained contexts, deliberately don't use
# the print_* block, and stay fully self-contained. See docs/bin-coding-standards.md.

# Vault root: honor $WORK_ROOT if set, else default to ~/work.
# shellcheck disable=SC2034  # consumed by the scripts that source this file
WORK="${WORK_ROOT:-$HOME/work}"

###
### Output functions
###
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NORMAL='\033[0m'
VERBOSE=false
DEBUG=false

print_status()  { echo -e "${BLUE}[INFO]${NORMAL} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NORMAL} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NORMAL} $1" >&2; }
print_error()   { echo -e "${RED}[ERROR]${NORMAL} $1" >&2; }
print_verbose() { [ "$VERBOSE" = true ] && echo -e "${BLUE}[VERBOSE]${NORMAL} $1" >&2 || true; }
print_debug()   { [ "$DEBUG" = true ] && echo -e "${BLUE}[DEBUG]${NORMAL} $1" >&2 || true; }

###
### Common helpers
###

# Strip leading/trailing whitespace from $1.
trim()  { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# ISO 8601 timestamp with a colon in the TZ offset (matches the vault convention).
iso_now() {
    local t
    t="$(date +%Y-%m-%dT%H:%M:%S%z)"
    printf '%s' "$t" | sed -E 's/([0-9]{2})([0-9]{2})$/\1:\2/'
}

# Kebab-case $1, truncated to at most $2 characters (default 30). Truncation
# snaps back to the last complete word boundary that fits rather than
# cutting mid-word -- a long title should still read as words, not a
# ragged fragment. (A single first word longer than the cap is the one
# case that still gets a hard cut -- nothing left to snap back to.)
kebab() {
    local s max cut
    s=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
    max=${2:-30}
    if [ ${#s} -le "$max" ]; then
        printf '%s' "$s"
        return
    fi
    cut="${s:0:$max}"
    [[ "$cut" == *-* ]] && cut="${cut%-*}"
    printf '%s' "$cut"
}

# Truncate to at most $2 chars, marking truncation with a trailing '..'
# (plain ASCII, not a unicode ellipsis, to avoid locale-dependent character
# counting in ${#s} throwing the width off). Keeps table columns aligned
# regardless of how long a slug is.
trunc() {
    local s=$1 max=$2
    if [ ${#s} -le "$max" ]; then
        printf '%s' "$s"
    else
        printf '%s..' "${s:0:$((max - 2))}"
    fi
}
