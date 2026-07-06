---
title: Work system — usage
created: 2026-06-30
tags: [work-system, usage, reference]
---

# Work system — usage

How to actually use `~/work` day to day: capture things, work on them, and see
where everything stands. For *why* the system is shaped this way, read
[[docs/work-system-architecture|the architecture doc]]; this is the hands-on
companion.

Audience: both me and someone new. If you're new, start with "The mental model"
and "A typical day," then dip into the task sections as needed.

## The mental model in one minute

- You **capture** things by running a `work*` command — nothing is scraped
  automatically, so the system only holds what you deliberately put in it.
- Things you'll *sit down and work on* are **work items**; atomic
  *follow-ups* you don't need a session for are **reminders**. (Did it earn a
  session? Item. Otherwise? Reminder.)
- You **work** on an item by running `workon <slug>`, which drops you into a
  Claude Code session in the right directory — inside an isolated container.
- You **see where things stand** by running the `dashboard` skill; you **recap
  what you did** with the `retrospective` skill.
- Everything is plain Markdown, auto-backed-up offsite every 4 hours.

A note on *where* commands run: `sandbox` and `workon` drive Docker, so they run
on the **host**. The capture commands (`workjot` / `workreminder` / `workitem`),
`worktree`, and the skills just operate on vault files and work anywhere the
vault is mounted — host or inside a session.

Every `work*` command takes `-h/--help`, `-v/--verbose`, and `-d/--debug`.

## A typical day

1. **Start the box once** (usually already running from login):
   `sandbox status` to check, `sandbox up` if needed.
2. **Pick up work:** `workon nagios` → a Claude session opens in that item's
   worktree, resuming the last session if there was one.
3. **Quick thing outside a session?** `workjot "bumped the alert threshold,
   restarted nagios"` — captured to today's log without ceremony.
4. **Something to not lose?** `workreminder "check the threshold held overnight"`.
5. **New piece of work?** `workitem Rework the cache host info`.
6. **What should I be doing?** Run the `dashboard` skill — it ranks in-flight
   work and rewrites [[index]].
7. **End of day / standup:** run the `retrospective` skill (`today`,
   `since monday`, etc.) for what moved.

You never touch [[index]] by hand and never worry that it looks stale — it's a
generated snapshot. Update the *item*, then re-run `dashboard`.

## Capturing things

Three commands, matched to three weights of work. When in doubt: a fact about
*what you did* is a jot; a *follow-up* is a reminder; a *thing to work on* is an
item.

### `workjot` — record ad-hoc work

For work that never gets a session: quick fixes, hallway debugging, "Kate
flagged X and I sorted it." Appends a timestamped line to today's jot log
(`diary/YYYY/MM/DD/<date>.log.md`).

```bash
workjot Restarted the stuck backup job on paris
workjot -r Ansible Fixed the hostname template typo   # attach repo's latest commit
```

With `-r <repo>` (or when run from inside a repo's worktree) it offers to append
the latest commit. Tag a jot to an item by mentioning its `[[slug]]` so the
retrospective can fold it in.

### `workreminder` — capture a follow-up

An atomic "don't lose this." Creates `reminders/<date>-<desc>.md` with
`status: active`.

```bash
workreminder Check nagios alert thresholds after the deploy
workreminder -i nagios Follow up with the team on the alert runbook
```

`-i <slug>` attributes it to a work item. If a "reminder" actually needs a
working session, make it an item instead.

### `workitem` — create a work item

Creates a single-file item under `items/`. Prompts for placement (active
top-level vs. `backlog/`) and optionally `to:` / `due:`.

```bash
workitem                                # interactive
workitem Update nagios push notifications
```

Items start as a single file. Grow one into a directory (with `plan.md` and
`status/`) only when it earns a plan or a status log — see [[items/CLAUDE]].

## Working on an item

### `workon` — open a session

```bash
workon nagios                  # opens the item's worktree (or its folder)
workon ad-upgrade Ansible      # pick a specific repo's worktree directly
workon isolated-claude-workspace
```

What it does:

- Resolves the item (must be an **active, top-level** item — not `backlog/` or
  `archived/`).
- Picks the worktree: if the item has one, opens it; several → prompts; none →
  opens the item folder for planning.
- Runs a **branch-drift check** against the integration branch and offers to
  rebase/merge if you're behind.
- Adds the item folder via `--add-dir` for shared cross-repo context.
- **Resumes** the last session for that directory if one exists, else starts
  fresh — and runs it all inside the `work-sandbox` container, auto-starting the
  box if it's down.

One worktree = one session. An item touching several repos gets one worktree
(and one session) per repo; the shared item folder carries cross-repo context.

### `worktree` — manage per-item worktrees

A work item that touches code gets a git worktree per repo under
`worktrees/<slug>/<repo>/`, branched off the canonical clone in `repos/<repo>/`.

```bash
worktree add nagios Ansible feature/nagios-pushover   # branch is explicit…
worktree add my-item Internal                         # …or defaults to the slug
worktree list                  # all worktrees, with branch + clean/dirty
worktree list nagios
worktree rm nagios             # remove the item's worktree(s); branch kept
worktree refresh Ansible       # fast-forward the clone's integration branch
```

Create worktrees when an item goes active; `worktree rm <slug>` clears them all
when it finishes. The branch and history are always left intact on removal.

## Seeing where things stand

### `dashboard` skill — what's on my plate

Run the `dashboard` skill (no arguments). It ranks in-flight items
(overdue → due-soon → at-risk → active → blocked), lists the backlog,
approaching deadlines, and active reminders, suggests a focus, and regenerates
[[index]]. It only ever reflects captured state — it doesn't invent or mutate
anything.

### `retrospective` skill — what I did

Run the `retrospective` skill with a window phrase (defaults to `today`):

```
retrospective                    (today)
retrospective last week
retrospective since monday
retrospective this quarter
retrospective 2026-06-01..2026-06-15
```

It reads breadcrumbs, jots, status entries, and *your own* git commits across
the worktrees, writes a dated file to `retrospectives/`, and **proposes**
curated `status/` write-backs for items that saw real progress (writing only on
your per-item confirmation). A standup is just a retrospective over the
since-last-standup window plus a dashboard glance — no separate tool.

## Changing an item's lifecycle

These are deliberate edits, not commands (the schema is in [[items/CLAUDE]]):

- **Activate a candidate:** move `items/backlog/<x>` → `items/`, set
  `status: active`. Then `worktree add` if it touches code.
- **Pause:** move `items/<x>` → `items/backlog/`, set `status: deferred`.
- **Block/unblock:** just flip `status:` between `active` and `blocked` — *no
  move* (both live at top level), so the most frequent transition is free.
- **Finish:** set `status: completed` (or `cancelled`) and the `completed:`
  date, move to `items/archived/`, and `worktree rm <slug>`.

Reminders archive as a single coupled move: set `status:` to `addressed` or
`dismissed` *and* move the file to `reminders/archived/` together. Documents
archive by moving to `docs/archived/` (no status field).

You can ask Claude to do any of these ("mark nagios blocked", "archive that
reminder, it's done") — it follows the same schema.

## The sandbox

The container is the box Claude runs inside; `sandbox` manages its lifecycle
(runs on the host — it drives Docker).

```bash
sandbox up        # create or start the persistent container (builds if needed)
sandbox status    # image / container / volume state
sandbox shell     # drop into a fish shell inside the box
sandbox down      # stop it (keeps the container + the claude-home volume)
sandbox rebuild   # rebuild the image (--no-cache) and recreate the container
```

Day to day you rarely touch this — it auto-starts at login and `workon` starts
it if it's down. You need it mainly when:

- **You changed the recipe** (`~/work/engine/sandbox/Dockerfile`, `entrypoint.sh`,
  the settings seed): `sandbox rebuild` to bake the change in.
- **Something seems off:** `sandbox status`, then `sandbox shell` to look around
  inside.

Recreating the container loses nothing — login and transcripts live on the
`claude-home` named volume, the vault is a bind-mount.

## Backups and recovery

Backups are **automatic**: a launchd job runs `work-backup` every 4 hours,
committing any vault changes and pushing them offsite to `work-vault.git` on
`sec.sci.utah.edu`. You don't have to do anything.

```bash
work-backup                              # force a commit + push right now
tail -5 ~/Library/Logs/work-backup.log   # check the last runs
```

To **recover** the vault on a new or wiped machine — and the full fresh-machine
bootstrap (Docker, dotfiles, work-engine clone, `workinit`, ssh key, launchd,
container) — follow `~/work/data/docs/vault-recovery.md`. It's written to be
run start-to-finish and has been test-run.

## Command cheat sheet

| Command | Does | Runs on |
|---------|------|---------|
| `workjot <note>` | Log ad-hoc work to today's jot log | vault |
| `workreminder <desc>` | Capture a follow-up reminder | vault |
| `workitem <title>` | Create a work item | vault |
| `workon <slug> [repo]` | Open a Claude session for an item | host → container |
| `worktree add/rm/list/refresh` | Manage per-item git worktrees | vault/repos |
| `sandbox up/down/status/shell/rebuild` | Container lifecycle | host |
| `work-backup` | Commit + push the vault offsite now | host |
| `dashboard` (skill) | Rank in-flight work, regenerate `index.md` | vault |
| `retrospective [window]` (skill) | Recap a window, propose status write-backs | vault |

All commands accept `-h/--help`; the `work*` family and `worktree`/`sandbox`
also take `-v/--verbose` and `-d/--debug`.

## Where to go next

- **Why it's built this way:** `~/work/engine/docs/work-system-architecture.md`.
- **The precise rules for a content type:** that area's `CLAUDE.md` under
  `~/work/engine/schema/` (`items/`, `reminders/`, `docs/`, `diary/`).
- **Recovery / new machine:** `~/work/data/docs/vault-recovery.md`.
