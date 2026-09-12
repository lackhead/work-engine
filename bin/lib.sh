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

# Emit $1 as a YAML scalar safe to write into frontmatter: double-quoted and
# escaped when the plain form would be misparsed, bare otherwise.
#
# The root CLAUDE.md's Frontmatter section already requires quoting values YAML
# would coerce; this is that rule made mechanical, so a caller can't forget it.
# The case that motivated it: a title containing ": " (e.g. "Docs schema:
# imported artifacts") is a YAML *parse error* as a plain scalar, not a
# coercion -- every downstream reader (workitem list, dashboard, retrospective,
# Obsidian) then chokes on the file.
#
# Deliberately conservative: quotes on anything that could change meaning
# unquoted, including bare numbers and YAML's bool/null keywords, so a title
# like "2026" or "No" round-trips as the string it was. Quoting when it wasn't
# strictly needed is harmless; failing to quote is not.
yaml_scalar() {
    local s=$1 needs=0
    case "$s" in
        '')            needs=1 ;;   # empty -> would read as null
        *': '*|*:)     needs=1 ;;   # key/value ambiguity -- the parse error
        *' #'*)        needs=1 ;;   # trailing comment
        [[:space:]]*|*[[:space:]]) needs=1 ;;
    esac
    # Leading indicator characters, checked one at a time rather than as a
    # bracket expression -- ']' and '-' inside a case-pattern bracket are a
    # portability minefield.
    case "${s:0:1}" in
        -|'?'|:|,|'['|']'|'{'|'}'|'#'|'&'|'*'|'!'|'|'|'>'|"'"|'"'|'%'|'@'|'`') needs=1 ;;
    esac
    case "$s" in
        [Tt]rue|TRUE|[Ff]alse|FALSE|[Yy]es|YES|[Nn]o|NO|[Oo]n|ON|[Oo]ff|OFF|[Nn]ull|NULL|'~') needs=1 ;;
    esac
    # Bare integers/decimals (YAML would hand back a number, not a string).
    case "$s" in
        *[!0-9]*) : ;;
        ?*)       needs=1 ;;
    esac
    case "$s" in
        [+-][0-9]*|[0-9]*.[0-9]*) case "$s" in *[!0-9.+-]*) : ;; *) needs=1 ;; esac ;;
    esac

    if [ "$needs" -eq 1 ]; then
        s=${s//\\/\\\\}
        s=${s//\"/\\\"}
        printf '"%s"' "$s"
    else
        printf '%s' "$s"
    fi
}

# Resolve $1 to a bare YYYY-MM-DD date. Passes a literal YYYY-MM-DD straight
# through; otherwise accepts a small set of relative forms, case-insensitive:
# "today", "tomorrow", and weekday names (full or 3-letter, "monday"/"mon")
# resolving to the next occurrence of that weekday with today itself
# counting (naming today's own weekday resolves to today, not a week out).
# Echoes the resolved date and returns 0; returns 1 with nothing echoed for
# anything else, leaving the error message to the caller.
#
# Epoch arithmetic (not `date -d`/`date -v` relative parsing) so this works
# unchanged on both GNU (Linux sandbox) and BSD (host Mac) date -- see
# docs/bin-coding-standards.md's shebang note on the two target
# environments. `date -r <epoch>` (BSD: epoch -> date) is tried first and
# falls back to `date -d "@<epoch>"` (GNU) when it fails, since GNU's `-r`
# means something else entirely (a file's mtime).
resolve_date() {
    local in=$1 lc offset target_dow today_dow epoch
    [[ "$in" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && { printf '%s' "$in"; return 0; }

    lc=$(printf '%s' "$in" | tr '[:upper:]' '[:lower:]')
    case "$lc" in
        today)         offset=0 ;;
        tomorrow)      offset=1 ;;
        mon|monday)    target_dow=1 ;;
        tue|tuesday)   target_dow=2 ;;
        wed|wednesday) target_dow=3 ;;
        thu|thursday)  target_dow=4 ;;
        fri|friday)    target_dow=5 ;;
        sat|saturday)  target_dow=6 ;;
        sun|sunday)    target_dow=7 ;;
        *) return 1 ;;
    esac

    if [ -n "${target_dow:-}" ]; then
        today_dow=$(date +%u)
        offset=$(( (target_dow - today_dow + 7) % 7 ))
    fi

    epoch=$(( $(date +%s) + offset * 86400 ))
    date -r "$epoch" +%F 2>/dev/null || date -d "@$epoch" +%F
}
