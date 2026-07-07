---
title: Work system — setup
created: 2026-07-06
tags: [work-system, setup, reference]
---

# Work system — setup

How to get the work system running on a new host — a wiped machine, a fresh
laptop, or a brand-new instance (e.g. a personal vault on a second machine).
This is engine-generic: it doesn't care which vault you're pointing at or how
that vault backs itself up. For *this* job instance's specific backup/restore
details (the git remote, the launchd job), see
`~/work/data/docs/work-data-backup.md`. For day-to-day usage once it's
running, see `~/work/engine/docs/work-system-usage.md`.

Estimated time: 15–20 minutes on a clean machine, plus however long restoring
your data takes.

## Prerequisites

Assumes Homebrew is already installed.

```bash
brew install git fish
brew install --cask docker
mkdir -p ~/work
```

`~/work` is just the default — any directory works as long as `$WORK_ROOT`
points at it (see `~/work/engine/schema/CLAUDE.md`). The rest of this doc
assumes the default.

Dotfiles (shell config, `PATH` wiring for `~/work/engine/bin`) should already
be deployed before starting below — `workon`/`worktree`/`sandbox` aren't
resolvable by bare name until they are, and the global `SessionEnd` hook +
statusline entries in `~/.claude/settings.json` come from there too.

## 1. Clone the engine

```bash
git clone git@github.com:lackhead/work-engine ~/work/engine
```

This deployed copy is what `PATH` points at — never hand-edit it; refresh
it later with a plain `git pull`.

Working *on* the engine itself (not just using it) needs a second, editable
clone — not required just to run the system:

```bash
git clone git@github.com:lackhead/work-engine ~/work/repos/work-engine
```

Edit through a worktree, same as any other repo (`worktree add <slug>
work-engine`), never by hand-editing the deployed `~/work/engine/` copy —
pull the merged result into it with a plain `git pull` (see
`~/work/engine/schema/CLAUDE.md` principle 10).

## 2. Get your data

Either restore an existing vault, or start a fresh one:

```bash
# Restoring an existing instance (this job's vault — see work-data-backup.md
# for the actual remote/credentials):
git clone <your-vault-remote> ~/work/data

# Starting a brand-new instance: nothing to do here — workinit (next step)
# creates an empty data/ tree. git-ifying it for backups is a later, optional
# step whenever you're ready — see work-data-backup.md.
```

## 3. Materialize the skeleton

```bash
workinit -v
```

Creates `~/work/{repos,worktrees}` and `data/{items,reminders,docs,diary,
retrospectives,.claude}` if missing, and the two symlinks
(`data/CLAUDE.md`, `data/.claude/skills`) into `engine/`. Never overwrites
unexpected state — it flags anything odd instead (exit code `2`) so you can
resolve it by hand. Safe to re-run any time, including just to verify nothing
has drifted (a clean second run is the idempotency check).

## 4. Set up the long-lived auth token

Sessions inside the sandbox authenticate via a long-lived OAuth token rather
than an interactive browser login. Generate one on the host (assumes
Claude Code is already installed and logged in there — separate from this
setup):

```bash
claude setup-token
```

Save the result to `~/.config/claude-sandbox.env` (path overridable with
`$SANDBOX_ENV`):

```
CLAUDE_CODE_OAUTH_TOKEN=<token>
```

Then lock down its permissions — it's a live credential:

```bash
chmod 600 ~/.config/claude-sandbox.env
```

This file is gitignored and never baked into the image. It's only read at
container *creation* (`sandbox up` injects it via `--env-file`) — if you set
it up after the container already exists, `sandbox rebuild` to pick it up.
Skipping this step isn't fatal; sessions just fall back to an interactive
login inside the container instead.

## 5. Build the sandbox

```bash
sandbox build      # ~5–10 min the first time
sandbox up
```

Confirm with `sandbox status`. The container auto-starts on future logins
(`--restart unless-stopped` + Docker Desktop "start at login").

## 6. Verify end to end

```bash
workon <any-active-item>    # drops into a containerized Claude session
```

From inside that session, confirm `dashboard` and `retrospective` show up as
available skills, and that ending the session writes a breadcrumb into
`data/diary/`. If you restored an existing vault, also run `dashboard` once
to regenerate `index.md` against the current host.

## Team-code repos

Any code repos you work on through this system (Ansible, internal tooling,
etc.) get cloned the same way as `work-engine`'s optional edit clone — into
`~/work/repos/<repo>/` — and worked through `worktree add <slug> <repo>`.
Not part of engine setup itself; clone them as you pick up items that touch
them.

## Where to go next

- **Day-to-day usage:** `~/work/engine/docs/work-system-usage.md`.
- **Why it's built this way:** `~/work/engine/docs/work-system-architecture.md`.
- **This instance's backup + recovery specifics:**
  `~/work/data/docs/work-data-backup.md`.
