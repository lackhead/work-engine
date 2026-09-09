---
title: Work system — architecture
created: 2026-06-30
tags: [work-system, architecture, reference]
---

# Work system — architecture

This document explains what `~/work` is, why it's built the way it is, and how
the pieces fit together. It's the conceptual map; for the precise schema of any
one piece, read that area's `CLAUDE.md`, and for day-to-day commands see
`~/work/engine/docs/work-system-usage.md`.

Audience: both me (already living in it) and someone new who might adopt the
pattern. Where a choice isn't obvious, the "why" is called out.

## What this is

`~/work` is a **work-management system**: a single, structured place that tracks
the lifecycle of work I take on, work on, and deliver — planning, work-item
tracking, reminders, and a dated activity log.

It is deliberately **not** a knowledge base or a wiki. The organizing question
is always *"what work is happening, and where is it in its lifecycle?"* — not
*"where do I file this fact?"* That single constraint is what keeps the tree
from sprawling into a junk drawer.

Three properties define the whole design:

1. **Work-lifecycle curation, not knowledge curation.** Everything tracks work
   in motion. Arbitrary reference information doesn't live here.
2. **Self-describing.** The schema lives *inside* the tree, as `CLAUDE.md` files
   at the root and in each major subdirectory. To understand the system you read
   those files; nothing external is required. This document is a narrative on
   top of them, not a replacement.
3. **Tool-agnostic.** It's just Markdown + YAML frontmatter in a directory, so
   it's equally usable from Claude Code, from Obsidian (the tree is a vault),
   and by hand. No application owns it.

The whole tree is informally called "the vault" — an Obsidian term, but it fits:
it's the durable store of work state.

## The mental model

Two ideas carry most of the system.

### Status lives in frontmatter; location encodes lifecycle stage

Every actionable thing has a canonical **status** in its YAML frontmatter. Its
**location** in the directory tree is a separate, coarser signal — a fast
filesystem glance at "what stage is this in" without parsing anything. The two
usually change together at a transition but are conceptually distinct acts.

How location encodes stage differs by type:

- **Work items** (`items/`) sit in one of three attention zones: top level
  (in-flight), `backlog/` (candidates / paused), `archived/` (out of
  circulation). The zone is the coarse signal; the exact `status:` is in
  frontmatter.
- **Reminders** (`reminders/`) use a simpler two-way split — top level (active)
  vs. `archived/` — and here status and location are *coupled*: archiving sets
  the `status:` to *why* (`completed` / `cancelled`) in the same move.
- **Documents** (`docs/`) carry no status field at all; presence in `docs/` vs.
  `docs/archived/` (vs. promoted into an item) is the entire signal.

Nothing that represents actual work is deleted; archiving preserves the body
as historical record. Deletion exists only where there's demonstrably no body
to preserve — a freshly-created item that accumulated nothing, a rejected
backlog candidate, a mistaken reminder — and each case is enumerated in the
root [[CLAUDE]]'s principle 5.

### Two actionable types, split on one question

There are exactly two things you *act on*, and the line between them is
operational, not about size:

- **Work item** — something you sit down and work in a dedicated session. Lives
  in `items/` as a directory (front door `<slug>/<slug>.md`), accreting
  `plan.md` and a `log/` as it earns the scaffolding.
- **Reminder** — an atomic "do this / check this / don't lose this" note you
  action or flip *without* a work session. Lives in `reminders/`. Usually
  frontmatter-only, with the filename as the description.

*Does it get its own working session?* Yes → work item. No → reminder. A
reminder that grows enough to earn a session graduates into a work item.

## The content types

Four kinds of content, each with its own `CLAUDE.md` defining filenames,
frontmatter, and lifecycle:

| Type | Lives in | What it is | Schema |
|------|----------|-----------|--------|
| **Work items** | `data/items/` | Work you sit down and do (or an instant record of already-done work) | `engine/schema/items/CLAUDE.md` |
| **Reminders** | `data/reminders/` | Atomic follow-ups, no session | `engine/schema/reminders/CLAUDE.md` |
| **Documents** | `data/docs/` | Standalone writing not yet tied to an item | `engine/schema/docs/CLAUDE.md` |
| **Retrospectives** | `data/retrospectives/` | Window roll-ups of every item's activity | `engine/schema/retrospectives/CLAUDE.md` |

Each item's own `log/` and `retrospectives/` are kept distinct on purpose: an
item's `log/` is the raw, auto-populated activity stream, and retrospectives
are the curated consolidations *derived* from it. Keeping the raw record
separate from its summaries means each stays easy to read on its own.

The curated front page is [[index]] — a generated snapshot of current state, not
a hand-maintained file (see "Skills" below).

## The engine

Content is inert Markdown; the **engine** is the tooling that captures, opens,
and summarizes it. It splits into two halves.

### Shell tooling — `~/work/engine/bin/`

Shell-agnostic `bash` executables on `PATH`, tracked in the `work-engine` repo
(deployed to `~/work/engine/`, never hand-edited in place — see "How it's all
tracked" below). These are the verbs of the system:

- **`workreminder`** — capture a reminder.
- **`workitem`** — create, list, and manage work items. See `workitem --help`
  for the verb roster rather than a copy of it here; the lifecycle *semantics*
  live in `schema/items/CLAUDE.md`.
- **`workon`** — open a Claude Code session for an item, in the right place (its
  worktree, or its folder), resume-aware.
- **`worktree`** — create/relocate/list/remove the per-item git worktrees, plus
  clone refresh and stale-branch pruning.
- **`workinit`** — idempotently materialize or verify an instance's `~/work`
  skeleton (the `data/` subdirectories, `repos/`, `worktrees/`,
  `keys/`, and the two symlinks into `engine/`).
- **`sandbox`** — lifecycle for the container Claude runs inside.
- **`work-backup`** — commit the vault (`~/work/data`) and push it offsite (run
  by launchd).
- **`work-session-breadcrumb`** — writes a factual breadcrumb to an item's own
  `log/` when a session ends. Not a Claude Code hook: it was a `SessionEnd`
  hook originally, but that fired unreliably on some exit paths (a long
  session ended by a hard exit could leave no breadcrumb at all), so `workon`
  invokes it deterministically host-side once the session returns. It still
  reads its payload on stdin, so it can be run by hand for recovery.
- **`work-session-catchup`** — the one genuine Claude Code hook
  (`SessionStart`), surfacing any `workitem log` note newer than the item's
  last session breadcrumb so a fresh session picks it up unprompted.
- **`hooks/commit-msg`** — a git `commit-msg` hook template; `worktree`
  installs it into each canonical clone so every commit made in one of that
  repo's worktrees is stamped `Work-Item: <slug>`, independent of the item's
  own files.

Capture is **manual and deliberate** — you run a `work*` command to record
something. Nothing scrapes Slack or your calendar. The system only ever reflects
what you chose to put in it; that intentionality is what keeps it curated rather
than noisy. (Coding conventions for these scripts:
`~/work/engine/docs/bin-coding-standards.md`.)

### Skills — `~/work/engine/skills/`

Three LLM skills do the work that needs judgment rather than a fixed script:

- **`dashboard`** — reads items, reminders, breadcrumbs, and git, ranks
  in-flight work, and regenerates [[index]]. It's read-derived: it ranks and
  presents what's captured, never invents state. (It owns most of `index.md` but
  leaves the hand-written "Notes / current focus" block and the retrospective
  pointer alone.)
- **`retrospective`** — rolls up a time window (day, week, month, quarter,
  range) from breadcrumbs, logged notes, and your own git commits; writes a
  dated retrospective and *proposes* a refreshed `## Current state` for items
  that saw real progress (never writing without confirmation).
- **`complete-item`** — closes out a finished item: drafts a permanent
  `## Retrospective` and a final `## Current state` from the item's whole
  history, writes them, then hands off to `workitem complete`/`cancel`. The
  one item-scoped retrospective that's persisted, because the item is leaving
  circulation for good.

The division of labor is deliberate: the **breadcrumb writer is dumb** (records
git/session facts only), the **skills are smart** (frame and curate), and the
two never overlap. A breadcrumb says "a session happened on item X"; the
retrospective is where that becomes "here's what moved."

## The sandbox — isolated Claude workspace

Claude Code runs inside a disposable Docker container rather than directly on the
laptop. The motivation: day-to-day use generates constant permission prompts,
most of which get approved anyway — friction without much signal. The clean fix
is to relax permissions *inside an isolated environment* instead of on the host,
so a mistaken or runaway action can't damage the host or reach production.

Key design decisions (full rationale in [[isolated-claude-workspace/plan|the
item's plan]]):

- **A container, not a VM.** Isolation is process-level, which suits the threat
  model — *the agent making mistakes*, not hostile code. Whole-disk snapshots
  aren't needed because every artifact is git-backed.
- **`~/work` is bind-mounted at the same absolute path** inside the container as
  on the host, and the container's `$HOME` mirrors the host's. So every path —
  the vault, transcripts, `--add-dir`, the item and worktree paths the
  breadcrumb writer resolves — is identical inside and out, with no
  translation. The host keeps Obsidian and the backup job.
- **One persistent, shared container.** Every session `docker exec`s into a
  single long-lived box (`work-sandbox`), auto-started at login (`--restart
  unless-stopped` + Docker Desktop start-at-login). `workon X` just works.
- **The image bakes no secrets and is disposable.** The vault is a runtime
  bind-mount; login + transcripts live on the `claude-home` named volume
  (surviving container/image rebuilds); credentials are injected at runtime.
  Tearing down and recreating the container loses zero work. The image is
  rebuilt per machine from the recipe in `~/work/engine/sandbox/`, never shared.
- **Safety = scoped credentials + network, not the box alone.** The blast radius
  equals whatever the sandbox can authenticate to and reach. The only channels
  out to the group's systems are git and ssh, both scoped so the worst realistic
  outcome is a cheap rollback.

`workon` is the entry point: it resolves the item, picks the worktree, runs a
branch-drift check, then `docker exec`s Claude into the container at the right
directory — so the per-item terminal workflow is unchanged; only the Claude
process now runs in the box.

## Backup

`~/work/data` is the only thing that needs backing up — the engine is a
GitHub clone, `repos/`/`worktrees/` are regenerable — for the same reason
the sibling-repos split above keeps each piece's provenance separate. See
`~/work/engine/docs/work-system-usage.md`'s "Backups" for the day-to-day
commands, and `~/work/data/docs/work-data-backup.md` for this instance's
actual remote and launchd job.

## How it's all tracked — sibling repos, not one tree

`~/work` itself is a **plain directory, not a git repo** — it's a container for
independent repos and scratch space, each owning a distinct subtree so no two
tools ever contend for the same path:

1. **`data/`** (`items/`, `reminders/`, `docs/`, `retrospectives/`,
   `index.md`) → the vault git repo, pushed to `work-vault.git` offsite. This
   is the backup described above. Private, per-instance — never shared between
   a job vault and a personal one.
2. **`engine/`** (`bin/`, `sandbox/`, `schema/` — including the root
   `CLAUDE.md` this document describes — and `skills/`) → the **`work-engine`**
   repo, its own GitHub remote, deployed here and refreshed with a plain
   `git pull`. Shared and versioned identically across every instance; never
   hand-edited in place (edit through `repos/work-engine/` + a worktree, same
   as any other repo).
3. **`repos/` and `worktrees/`** → canonical clones and per-item worktrees for
   team code (plus `repos/work-engine`, the editable clone for #2). Ungit'd
   scratch space, conceptually separate from both the vault and the engine —
   referenced by backticked path, never wikilinked.

`data/CLAUDE.md` and `data/.claude/skills` are symlinks into `engine/`, which is
why this document and the skills are reachable from inside the vault without
physically living there. (One consequence worth knowing: because `data/` is a
git repo, a bare `git` run from inside an item folder resolves *up* to the
vault — the engine tools that infer a repo from the current directory are
written to detect and skip that, comparing toplevel against `$WORK/data`, not
`$WORK`. See `~/work/engine/docs/bin-coding-standards.md` § "The vault is a git
repo".)

This is a deliberate change from an earlier design that nested the vault's
repo inside the dotfiles repo's own work-tree (`~/.dotconf`, bare-repo-as-
`$HOME`) — that nesting caused real incidents (silently drifted tracked files,
phantom merge conflicts) because two repos claimed overlapping paths. Making
`engine/` and `data/` siblings under a non-repo `~/work` means no repo's
work-tree is ever an ancestor of another's root.

## Conventions in brief

- **Cross-references inside the tree** use Obsidian wikilinks
  (`[[ad-upgrade]]`, `[[docs/index]]`). Work items link by bare name so
  the link survives zone moves. External URLs use Markdown links; repos and code
  paths use backticked paths.
- **Frontmatter** is the canonical home for structured metadata — lowercase
  kebab-case keys, ISO 8601 timestamps.
- **Schemas evolve, but not silently.** If content needs a field the schema
  doesn't describe, the `CLAUDE.md` is revised *first*, then the field is added.

The authoritative statement of all of this is the root [[CLAUDE]]; the
per-directory `CLAUDE.md` files own the specifics for their areas.

## Where to go next

- **To *use* the system day to day:** `~/work/engine/docs/work-system-usage.md`.
- **The precise schema:** `~/work/engine/schema/CLAUDE.md` (root) and each
  area's `CLAUDE.md`.
- **Setting up a new host/instance:** `~/work/engine/docs/work-system-setup.md`.
- **This instance's backup + recovery:** `~/work/data/docs/work-data-backup.md`.
- **Writing engine tooling:** `~/work/engine/docs/bin-coding-standards.md`.
