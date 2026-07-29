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
brew install git fish fzf jq
brew install --cask docker
mkdir -p ~/work
```

`git`, `fish`, and Docker Desktop are required. `fzf` and `jq` are recommended
but optional: `fzf` drives the interactive item picker in `workitem log` and
`workreminder` (both fall back to a numbered menu without it), and `jq` speeds
up the session breadcrumb's JSON parsing (a `sed` fallback covers its absence).

`~/work` is just the default — any directory works as long as `$WORK_ROOT`
points at it (see `~/work/engine/schema/CLAUDE.md`). The rest of this doc
assumes the default.

Dotfiles (shell config, `PATH` wiring for `~/work/engine/bin`) should already
be deployed before starting below — `workon`/`worktree`/`sandbox` aren't
resolvable by bare name until they are. (Claude Code's in-sandbox settings —
the statusline and the `SessionStart` catch-up hook — are seeded into the
container by the image itself, not from host dotfiles; see step 5.)

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

Creates `~/work/{repos,worktrees,keys}` and `data/{items,reminders,docs,
retrospectives,.claude}` if missing, and the two symlinks
(`data/CLAUDE.md`, `data/.claude/skills`) into `engine/`. `keys/` is created
mode `700` — it's where the next step puts the sandbox's SSH credentials.
Never overwrites unexpected state — it flags anything odd instead (exit code
`2`) so you can resolve it by hand. Safe to re-run any time, including just to
verify nothing has drifted (a clean second run is the idempotency check).

## 4. Set up the sandbox's SSH keys and config

The sandbox container needs its own dedicated SSH key(s), separate from your
host's regular ones, and a `~/.ssh/config` mapping each git endpoint to the
right key. Neither lives in any repo — engine or vault — so each instance can
have its own without an engine change or a leak into another instance's copy.
Both live in `~/work/keys/` (created mode `700` by the previous step):

```bash
ssh-keygen -t ed25519 -f ~/work/keys/sandbox_github -C "sandbox — github"
```

Add the public key to GitHub (or wherever) as normal, generating one such
key per endpoint the sandbox needs to reach. Then copy the config template
and edit it for this instance:

```bash
cp ~/work/engine/sandbox/home/ssh_config.example ~/work/keys/ssh_config
```

`~/work/keys/` is already covered by the sandbox's `~/work` bind-mount, so
edits here take effect immediately in any session already running — no
`sandbox recreate`, let alone a rebuild. Skipping this step isn't fatal;
sessions just can't push/pull over SSH from inside the sandbox until it's
done.

## 5. Set up the long-lived auth token

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
it up after the container already exists, `sandbox recreate` to pick it up
(no image rebuild needed; `sandbox restart` won't do it — see `sandbox
help`). Skipping this step isn't fatal; sessions just fall back to an
interactive login inside the container instead.

## 6. Build the sandbox

The engine's Dockerfile is a base image only (Claude, `gh`, the base shell
tooling — common to every instance). If this instance needs its own extra
packages — e.g. a work instance's Ansible/pre-commit toolchain that a
personal instance doesn't want — add them *before* building, in
`data/sandbox/Dockerfile.local` (tracked in the vault, since it's an
instance preference, not a secret). Copy the shape from
`~/work/engine/sandbox/Dockerfile.local.example`:

```dockerfile
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER clake
RUN pipx install pre-commit \
    && pipx install --include-deps ansible \
    && pipx install ansible-lint
USER root
```

`sandbox build` picks this up automatically and layers it on top of the
base image — no engine change needed, ever, just for adding a package.
Skip this file entirely if this instance needs nothing beyond the base.

```bash
sandbox build      # ~5–10 min the first time
sandbox up
```

Confirm with `sandbox status`. The container auto-starts on future logins
(`--restart unless-stopped` + Docker Desktop "start at login").

## 7. Verify end to end

```bash
workon <any-active-item>    # drops into a containerized Claude session
```

From inside that session, confirm `dashboard` and `retrospective` show up as
available skills, and that ending the session writes a breadcrumb into that
item's own `log/`. If you restored an existing vault, also run `dashboard`
once to regenerate `index.md` against the current host.

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
