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
- Everything is plain Markdown, living under `~/work/data` — back it up
  however you like (this instance does it automatically; see "Backups" below).

A note on *where* commands run: `sandbox` and `workon` drive Docker, so they run
on the **host**. The capture commands (`workreminder` / `workitem`),
`worktree`, and the skills just operate on vault files and work anywhere the
vault is mounted — host or inside a session.

Every `work*` command takes `-h/--help`, `-v/--verbose`, and `-d/--debug`.

## A typical day

1. **Start the box once** (usually already running from login):
   `sandbox status` to check, `sandbox up` if needed.
2. **Pick up work:** `workon nagios` → a Claude session opens in that item's
   folder (with any worktrees attached), resuming the last session if there was one.
3. **Quick thing outside a session?** `workitem log` — captured without
   ceremony, either into an existing item's `log/` or as a new completed
   item if there isn't one.
4. **Something to not lose?** `workreminder create check the threshold held overnight`.
5. **New piece of work?** `workitem create Rework the cache host info`.
6. **What should I be doing?** Run the `dashboard` skill — it ranks in-flight
   work and rewrites [[index]].
7. **End of day / standup:** run the `retrospective` skill (`today`,
   `since monday`, etc.) for what moved.

You never touch [[index]] by hand and never worry that it looks stale — it's a
generated snapshot. Update the *item*, then re-run `dashboard`.

## Capturing things

Two commands, matched to two weights of work. When in doubt: a fact about
*what you did* is a log entry; a *follow-up* is a reminder; a *thing to work
on* is an item.

### `workitem log` — record work done outside a session

For work that never gets a session: quick fixes, hallway debugging, "Kate
flagged X and I sorted it." Writes into an existing item's `log/` if one
applies, or creates a new, already-completed item to hold the note if not.

```bash
workitem log nagios              # existing item, by slug — then prompts for the note
workitem log -r Ansible           # attach repo's latest commit, then asks or creates
workitem log                      # no context at all — asks interactively
```

With `-r <repo>` (or when run from inside one of an item's worktrees) it
offers to attach the latest commit alongside the note.

### `workreminder create` — capture a follow-up

An atomic "don't lose this." Creates `reminders/<slug>.md` with
`status: active` (no date prefix — the date lives in `created:`).

```bash
workreminder create Check nagios alert thresholds after the deploy
workreminder create -i nagios Follow up with the team on the alert runbook
workreminder create           # no description — full interactive flow instead
```

`-i <slug>` attributes it to a work item. Given a description on the command
line it fires immediately, no prompts; with none, it prompts for the
description, whether to attach an existing item (picked interactively), and
a slug to confirm. If a "reminder" actually needs a working session,
`workreminder promote <name>` turns it into a work item and archives the
reminder in one step.

### `workitem` — create, list, and manage work items

Every item is a directory (front door `<slug>/<slug>.md`); `plan.md` and the
`log/` come later — `plan.md` when the item earns it, `log/` automatically on
the first session or logged note.

```bash
workitem create Update nagios push notifications   # title only — non-interactive
workitem create -b Investigate the new vendor API  # into backlog/ (status proposed)
```

`create` is non-interactive: it takes the title, sets `status: active`
top-level (or `proposed` in `backlog/` with `-b`), and stamps `made:`. Optional
frontmatter (`to:`, `due:`, a description) is added afterward — by hand or by
asking Claude. Beyond create/list/complete/cancel there are also `show`,
`log`, `activate`, `defer`, `block`, `unblock`, and `delete`; see
[[items/CLAUDE]].

`workitem list` is a quick terminal-native glance — slug, status, due,
last-updated — no LLM session needed:

```bash
workitem list                    # top-level (active + blocked)
workitem list --backlog
workitem list --all --status blocked
```

`workitem complete <slug>` / `workitem cancel <slug>` close one out — set
`status:` (`completed`/`cancelled`) and the `completed:` date, move it to
`items/archived/`, and remove its worktree(s) if any:

```bash
workitem complete nagios
```

## Working on an item

### `workon` — open a session

```bash
workon nagios                            # opens the item folder; attaches any worktrees
workon ad-upgrade -r Ansible             # ensure/attach the Ansible worktree, then open
workon new-idea -r Ansible -r Internal   # multi-repo: attach both
```

What it does:

- Resolves the item (must be an **active, top-level** item — not `backlog/` or
  `archived/`; offers to create it if the slug doesn't exist).
- Opens the session with the **item's own folder** as the working directory —
  always, never a specific repo's worktree.
- Attaches **every** worktree the item has via `--add-dir`, all equally
  reachable (there's no "pick one"). `-r/--repo` (repeatable) ensures a worktree
  exists for a repo — creating it if missing — and attaches it.
- Runs a **branch-drift check** per attached repo against the integration
  branch and offers to rebase/merge if you're behind.
- **Resumes** the last session for that directory if one exists, else starts
  fresh — all inside the `work-sandbox` container, auto-starting the box if
  it's down.

The item folder is the session's home and carries cross-repo context; a
multi-repo item is one session with several worktrees attached, not several
sessions.

### `worktree` — manage per-item worktrees

A work item that touches code gets a git worktree per repo under
`worktrees/<slug>/<repo>/`, branched off the canonical clone in `repos/<repo>/`.

```bash
worktree add nagios Ansible feature/nagios-pushover   # branch is explicit…
worktree add my-item Internal                         # …or defaults to the slug
worktree list                  # all worktrees, with branch, clean/dirty, and commits ahead (unmerged)
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

It reads breadcrumbs, logged notes, status entries, and *your own* git commits
across the worktrees, writes a dated file to `retrospectives/`, and **proposes**
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
- **Finish:** `workitem complete <slug>` / `workitem cancel <slug>` — sets
  `status:` and the `completed:` date, moves to `items/archived/`, and
  removes its worktree(s) if any, all in one step.

Reminders archive as a single coupled move: `workreminder complete <name>` /
`workreminder cancel <name>` set `status:` to `completed` or `cancelled` *and*
move the file to `reminders/archived/` together. Documents archive by moving
to `docs/archived/` (no status field).

You can ask Claude to do any of these ("mark nagios blocked", "complete that
reminder, it's done") — it follows the same schema.

## The sandbox

The container is the box Claude runs inside; `sandbox` manages its lifecycle
(runs on the host — it drives Docker).

```bash
sandbox up        # create or start the persistent container (builds if needed)
sandbox status    # image / container / volume state
sandbox shell     # drop into a fish shell inside the box
sandbox down      # stop it (keeps the container + the claude-home volume)
sandbox restart   # stop then start — no rebuild (e.g. a hung container)
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

### Getting files into a session

Dragging a file onto the terminal (or pasting from Finder) only inserts a
*host* path the container can't read — the Mac filesystem isn't mounted in the
box, except `~/work`. So to hand a file (a screenshot, a PDF, an export) to a
session, drop it in **`~/work/incoming/`** and tell Claude it's there:

```
> I dropped foo.png in incoming
```

Because `~/work` is bind-mounted at the same path inside the box, Claude reads
it directly and can move it into the relevant item
(`items/<slug>/artifacts/` or `docs/`) if it's worth keeping. `incoming/` is
scratch, not storage — ungit'd, never backed up, and the sandbox auto-purges
anything older than a week on start. (Clipboard *image* paste still won't
work — there's no clipboard bridge into the container — so the
drop-in-`incoming` path is the way.)

## Backups

`~/work/data` is the only thing that needs backing up (`engine/` is a clone
of its own GitHub remote; `repos/`/`worktrees/` are regenerable) — back it up
however suits you. This instance does it **automatically**: a launchd job
runs `work-backup` every 4 hours, committing any vault changes and pushing
them offsite. You don't have to do anything day to day.

```bash
work-backup                              # force a commit + push right now
tail -5 ~/Library/Logs/work-backup.log   # check the last runs
```

Full details of this instance's backup setup — the git remote, the launchd
job, restoring on a new machine — are in
`~/work/data/docs/work-data-backup.md`. For setting up a *new* instance from
scratch (engine clone, PATH wiring, `workinit`, sandbox build), see
`~/work/engine/docs/work-system-setup.md`.

## Command cheat sheet

| Command | Does | Runs on |
|---------|------|---------|
| `workitem log [-r\|--repo <repo>] [item-slug]` | Log ad-hoc work outside a session | vault |
| `workreminder create [-i\|--item <slug>] [desc...]` | Capture a follow-up reminder | vault |
| `workreminder promote <name> [workitem create args...]` | Turn a reminder into a work item | vault |
| `workitem create [title...]` | Create a work item | vault |
| `workitem list [--backlog\|--archived\|--all] [--status <v>]` | Quick glance at items | vault |
| `workitem complete <slug>` / `workitem cancel <slug>` | Close out an item | vault |
| `workon <slug> [-r <repo>]...` | Open a Claude session for an item | host → container |
| `worktree add/rm/list/refresh` | Manage per-item git worktrees | vault/repos |
| `sandbox up/down/restart/status/shell/rebuild` | Container lifecycle | host |
| `work-backup` | Commit + push the vault offsite now | host |
| `dashboard` (skill) | Rank in-flight work, regenerate `index.md` | vault |
| `retrospective [window]` (skill) | Recap a window, propose Current state write-backs | vault |

All commands accept `-h/--help`; the `work*` family and `worktree`/`sandbox`
also take `-v/--verbose` and `-d/--debug`.

## Where to go next

- **Why it's built this way:** `~/work/engine/docs/work-system-architecture.md`.
- **The precise rules for a content type:** that area's `CLAUDE.md` under
  `~/work/engine/schema/` (`items/`, `reminders/`, `docs/`, `retrospectives/`).
- **Setting up a new host/instance:** `~/work/engine/docs/work-system-setup.md`.
- **This instance's backup + recovery:** `~/work/data/docs/work-data-backup.md`.
