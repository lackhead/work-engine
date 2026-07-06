---
title: Coding standards for work-engine bin scripts
created: 2026-06-30
tags: [standards, tooling]
---

# Coding standards for work-engine bin scripts

Conventions for scripts in `~/work/engine/bin/` — the engine tooling for this
work-management system (`workon`, `worktree`, `workinit`, `sandbox`, `workjot`,
`workitem`, `workreminder`, and any future scripts). The goal is a
consistent experience: the same help format, the same color-coded output,
the same option flags, regardless of which script you're using.

These patterns were established by cross-referencing the
`~/work/repos/Ansible/roles/secure_host/files/account-mgmt/` scripts
(`account-create`, `account-info`, etc.), which use the same conventions.
Both sets of scripts share the same `print_*` pattern and `usage` heredoc
shape — no dependency link, just a shared style.

---

## Script structure

Every script follows this order:

1. Shebang + file-header comment block
2. `set -u`
3. Constants (WORK root, script-specific vars)
4. Output functions
5. Usage heredoc
6. Helper functions
7. Subcommand functions (if applicable)
8. Argument parsing and dispatch

---

## Shebang and shell flags

```bash
#!/usr/bin/env bash
```

Use `#!/usr/bin/env bash`, not `#!/bin/bash`. The scripts run on the host
Mac and inside the Debian sandbox container; `env bash` finds the right
binary in both. The Ansible scripts use `/bin/bash` because they run on
known Linux hosts — the work scripts have broader target environments.

Always open with `set -u` (uninitialized variable detection). Do **not**
use `set -e`: it interacts poorly with the `[ cond ] && cmd` idiom and
requires wrapping every call that may return non-zero. Check return codes
explicitly where it matters.

---

## Work root

```bash
WORK="${WORK_ROOT:-$HOME/work}"
```

Honor `$WORK_ROOT` so a second instance of the vault can coexist without
collisions. Most scripts set this as a plain variable. Scripts with
subcommands (like `worktree`) use a function instead so the override is
visible in every context:

```bash
work_root() { echo "${WORK_ROOT:-$HOME/work}"; }
```

---

## Output functions

Paste this block verbatim at the top of every user-facing script. These
are the canonical six functions — don't add, rename, or remove without
updating all scripts.

```bash
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
```

Usage guide:

| Function | Prefix | Stream | When to use |
|---|---|---|---|
| `print_status` | `[INFO]` blue | stdout | In-progress steps always shown ("Building image…", "Fetching…") |
| `print_success` | `[SUCCESS]` green | stdout | Completion of a significant action ("Container up", "Created → …") |
| `print_warning` | `[WARNING]` yellow | stderr | Non-fatal problems the user should know about |
| `print_error` | `[ERROR]` red | stderr | Fatal errors; always follow with `exit 1` |
| `print_verbose` | `[VERBOSE]` blue | stderr | Context for operators who want to follow along (`-v` or `-d`) |
| `print_debug` | `[DEBUG]` blue | stderr | Diagnostic internals for troubleshooters (`-d` only) |

### Verbose vs. debug

The distinction is about the *audience* and *purpose* of the output:

- **`-v/--verbose`** (`print_verbose`): "I want to see what is going on for
  context's sake." The kind of output that's reassuring during a slow
  operation or useful when a command does something non-obvious. Examples:
  which SSH keys are being mounted, which directory Claude will open in,
  which container is being checked.

- **`-d/--debug`** (`print_debug`): "Something is going wrong and I need to
  pinpoint it." Lower-level internals that are noise in normal use — exact
  flag values, encoded path strings, raw return codes, gate calculations.

**`-d` implies `-v`**: setting `DEBUG=true` also sets `VERBOSE=true`. A
troubleshooter always wants the context layer too. The implementation:

```bash
-v|--verbose) VERBOSE=true ;;
-d|--debug)   DEBUG=true; VERBOSE=true ;;
```

`print_verbose` and `print_debug` both use `|| true` to ensure the
function always exits 0 — `[ cond ] && cmd` exits 1 if the condition
is false, which can confuse callers in some contexts.

There is no `print_quiet` or `QUIET` flag in these scripts. If quiet mode
becomes useful, add it then (and add it to all scripts at once).

### No shared library

The functions are duplicated in each script by design. A sourced
`common.sh` would introduce a runtime dependency that can fail (wrong
`$WORK`, wrong container path, scripts copied outside the tree). The block
is only ~10 lines; inline duplication is the right call here. If the
functions ever grow substantially, revisit.

---

## Usage heredoc

Use the `IFS='' read -r -d ''` heredoc pattern — the same as the
account-mgmt scripts — so the usage text is a variable that can be echoed
from the `-h` case and also from an unrecognized subcommand or "no args"
fallback.

```bash
IFS='' read -r -d '' usage <<"EOF"

script-name: short one-line description

Usage:
   script-name [ -h|--help ]
   script-name [ -d|--debug ] <required-arg> [optional-arg]

Arguments:
   -h|--help         Show what you are seeing right now
   -d|--debug        Enable verbose output
   <required-arg>    What it is
   [optional-arg]    What it is (default: X)

Description:
   Two to four lines describing what the script does, constraints,
   and any non-obvious behavior. Avoid repeating the Arguments table.

Examples:
   script-name foo
   script-name -d foo bar

EOF
```

Emit it with `printf '%s\n' "$usage"` (not `echo "$usage"`) to avoid
surprises with echo flag interpretation.

Section order: Usage, Arguments, Description, Examples. Keep each section
short — if Description is growing, the script is probably trying to do too
much. The Examples section is the highest-value part; don't skip it.

---

## Argument parsing

Three patterns cover all current scripts.

### Pattern 1: global-flag scripts (workon, workitem, workjot, workreminder)

No subcommands. Parse everything in one while/case loop. Collect
positional arguments as you go:

```bash
slug=''
repo_arg=''
while [ $# -gt 0 ]; do
    case "$1" in
        -v|--verbose) VERBOSE=true ;;
        -d|--debug)   DEBUG=true; VERBOSE=true ;;
        -h|--help|help) printf '%s\n' "$usage"; exit 0 ;;
        -r|--repo) shift; repo_opt=${1:-} ;;
        --repo=*)  repo_opt=${1#--repo=} ;;
        -*) print_error "Unknown option: $1"; exit 1 ;;
        *)
            if [ -z "$slug" ]; then slug=$1
            elif [ -z "$repo_arg" ]; then repo_arg=$1
            else print_error "Too many arguments."; exit 1
            fi ;;
    esac
    shift
done
```

### Pattern 2: subcommand scripts (sandbox, worktree)

Parse global flags first with a `while` that `break`s at the first
non-flag token, then dispatch to subcommand functions with the remaining
`"$@"`:

```bash
# Parse global options before the subcommand so `sandbox -d up` works.
while [ $# -gt 0 ]; do
    case "$1" in
        -v|--verbose) VERBOSE=true; shift ;;
        -d|--debug)   DEBUG=true; VERBOSE=true; shift ;;
        -h|--help|help) printf '%s\n' "$usage"; exit 0 ;;
        *) break ;;
    esac
done

cmd="${1:-}"
[ "$#" -gt 0 ] && shift
case "$cmd" in
    add)    subcmd_add "$@" ;;
    rm)     subcmd_rm "$@" ;;
    '')     printf '%s\n' "$usage" ;;
    *)      print_error "Unknown command '$cmd' (try: script-name help)"; exit 1 ;;
esac
```

Subcommand functions then do their own positional parsing internally. They
do not re-parse `-d/--debug` (the global `DEBUG` variable is already set).

### Error handling in arg parsing

```bash
# Option requires an argument:
-r|--repo)
    [ -z "${2:-}" ] && { print_error "Option -r/--repo requires an argument"; exit 1; }
    shift; repo_opt=$1 ;;

# Unknown option (always the last case before positionals):
-*) print_error "Unknown option: $1"; exit 1 ;;
```

Never silently ignore unknown options. Always check for missing required
arguments before dereferencing `$2`.

---

## Common helpers

Two small functions appear in multiple scripts. Paste them where needed —
don't import from a shared file.

```bash
# Strip leading/trailing whitespace from $1.
trim()  { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# Lowercase-kebab-case from $1 (for slugs and filenames).
kebab() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'; }
```

---

## The vault is a git repo — don't treat it as a code repo

`~/work/data` is itself a git repo (the offsite backup — see
`~/work/data/docs/vault-recovery.md`). Any tool that runs `git` against a
*current directory* — rather than an explicit `repos/<repo>` or worktree path
— can silently resolve **up** to the vault when run from an item folder,
`data/docs/`, or the vault root, because git walks upward to the nearest
`.git`. That makes a planning session look like code work: the breadcrumb
hook would record the vault's branch and its automated `backup:` commits,
`workjot` would offer to attach them, and so on.

Guard cwd-based git detection by comparing the repo's toplevel to the vault
root (`$WORK/data`, not `$WORK` — `$WORK` is the plain outer directory that
also holds `engine/`, `repos/`, `worktrees/`) and bailing when they match:

```bash
top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)"
if [ -n "$top" ] && [ "$top" != "$WORK/data" ]; then
    # real code repo — safe to read git facts
fi
```

Worktrees are exempt for free: each has its own `.git` that shadows the vault,
so `git -C <worktree>` resolves to the worktree, not `~/work/data`. Tools that
only ever use explicit `repos/<repo>` or worktree paths (`workon`, `worktree`)
need no guard — the rule is specifically for tools that *infer* the repo from
the current directory (`work-session-breadcrumb`, `workjot`).

---

## Error handling conventions

- Always use `print_error` for fatal errors, immediately followed by
  `exit 1`. No `die()` function needed — the pair is explicit and
  readable.
- Do not use `set -e`. Check return codes explicitly where they matter:
  ```bash
  docker build -t "$IMAGE" "$RECIPE" || { print_error "Build failed."; exit 1; }
  ```
- For non-fatal problems visible to the user (offline fetch, missing
  optional file), use `print_warning` and continue.
- For non-fatal problems that should not surface at all in normal use,
  redirect to `/dev/null` and handle the exit code:
  ```bash
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || continue
  ```
- Never suppress errors silently unless the failure is genuinely
  uninteresting.

---

## Fish completions

Each script gets a companion `~/work/engine/bin/completions/<script>.fish`,
autoloaded by fish because `~/work/engine/bin/completions` is in
`$fish_complete_path`.

Conventions:

- Start with `complete -c <script> -f` to disable filename completion.
- Always include `-d/--debug` and `-h/--help` option completions.
- For subcommand scripts, use `__fish_use_subcommand` and
  `__fish_seen_subcommand_from` to scope positional completions.
- For non-option positional counting, write a `__<script>_nargs` helper
  that skips `-*` tokens — this ensures completions still work when the
  user types `workon -d <tab>`:

  ```fish
  function __workon_nargs
      set -l toks (commandline -opc)
      set -l n 0
      if test (count $toks) -ge 2
          for tok in $toks[2..-1]
              string match -q -- '-*' $tok; or set n (math $n + 1)
          end
      end
      echo $n
  end
  ```

- Helper function names are prefixed `__<script>_` to avoid namespace
  collisions between completion files.
- Use `-x` (exclusive, implies `-f`) on options that take a value, and
  supply an `-a` argument generator where completions are meaningful.

---

## Naming and style

- **Script names:** lowercase, hyphenated if multi-word (`work-session-breadcrumb`,
  not `workSessionBreadcrumb`). The `work*` capture commands are an exception
  — they intentionally run together for speed at the prompt.
- **Variable names:** `UPPER_CASE` for script-level constants and flags
  (`DEBUG`, `WORK`, `CONTAINER`). `lower_case` for local variables inside
  functions.
- **Function names:** `lower_snake_case` (`wt_add`, `run_container`,
  `print_status`). Subcommand functions are prefixed with the script's
  abbreviation (`wt_`, `run_`, etc.) to keep them distinct from utilities.
- **Constants at the top:** all script-level vars before any functions.
  The output block (`RED`/`GREEN`/etc. + `DEBUG` + `print_*`) comes
  immediately after the initial constants.
- **Comments:** only when the WHY is non-obvious — a constraint, a
  subtle invariant, a workaround. Don't narrate what the code does. The
  account-mgmt scripts set a good example here: short, purposeful comments
  at the section level, none inside obvious logic.
