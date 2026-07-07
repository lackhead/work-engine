# Work items (per-directory schema)

Work items are the unit of work I sit down and *do* in this system — anything
that gets (or will get) its own working session. Each lives under
`~/work/data/items/`. This type is the merge of what used to be split across
`projects/` (multi-week, directory-scaffolded efforts) and `tasks/` (small,
single-file items): operationally they were the same thing — a piece of work
that gets a dedicated session — differing only in how much tracking
scaffolding they carry. That difference is *weight*, not *type*, so they're
one type now, with structure that scales.

Work items are distinct from **reminders** (`reminders/`). The dividing line
is operational: *does this get its own work session?* If yes, it's a work
item; if it's just an atomic "do this / check this / don't lose this" note you
action or flip without sitting down to work it, it's a reminder. A reminder
can graduate into a work item when it earns a session — see
`reminders/CLAUDE.md`.

Vault-wide conventions (markdown style, frontmatter rules, linking, file
naming) live in [[CLAUDE]]. This file specifies how those apply to work items
and the structure each carries.

## Lifecycle

A work item has two axes: **status** (what the item is doing) lives in
frontmatter, and **attention zone** (where it sits in the directory tree)
encodes the coarse lifecycle stage. They're related but not identical — see
"Attention zones." Transitions are conscious decisions; nothing changes
status automatically as a side effect of other edits.

### Status values

The `status:` field is required and takes one of:

- **`proposed`** — captured but not yet committed to. Default for a new item.
- **`active`** — currently in flight or queued to be worked.
- **`blocked`** — active work that can't progress because of an external
  dependency (a person, a vendor, an upstream change). Involuntary.
- **`deferred`** — committed work intentionally paused. Voluntary. Distinct
  from `blocked`.
- **`completed`** — done as intended.
- **`cancelled`** — was `proposed` or `active` and won't be done. Distinct
  from `completed`: abandoned without delivering.

### Attention zones

`items/` is split into three directories by coarse attention zone, so a plain
`ls` or the Obsidian folder tree answers "what's on my plate" without running
a skill:

- **`items/` (top level) — in-flight: `active` + `blocked`.** The daily /
  weekly glance. `active ↔ blocked` is a frontmatter edit only, **no move** —
  both live here — so the most frequent transition costs nothing.
- **`items/backlog/` — `proposed` + `deferred`.** Candidates and
  intentionally-paused work; consulted occasionally when planning further out.
- **`items/archived/` — out of active circulation.** Normally `completed` /
  `cancelled`, but archival is its own decision: an item deliberately set
  aside long-term may live here carrying any status. The frontmatter status
  stays canonical; the `archived/` location is the separate "not turning this
  over right now" signal.

The directory encodes the zone; the *precise* status (active vs. blocked,
proposed vs. deferred, completed vs. cancelled) stays in frontmatter. Files
move between zones only at deliberate transitions:

- commit a candidate: `backlog → top` (set `status: active`)
- pause: `top → backlog` (set `status: deferred`)
- resume: `backlog → top` (set `status: active`)
- finish or abandon: `top|backlog → archived/` (set `completed` / `cancelled`
  and the `completed:` date)

Status edit and zone move usually happen together at these transitions, but
they remain conceptually separate acts (you can, e.g., mark something
`cancelled` and archive it in two steps). Nothing is ever deleted; finished
work moves to `archived/`, preserving the body as historical record.

## Structure

Every work item is a **directory**, created as one from the start — there's
no lighter-weight form and no promotion step. What scales with how much
scaffolding an item earns is what's *inside* the directory, not whether it
has one:

```
items/<name>/
├── <name>.md      # the front door (see naming note below) — always present
├── plan.md        # forward-looking: phases, decisions, success/rollback criteria
└── status/        # dated snapshots: YYYY-MM-DD.md, append-only
```

Only `<name>.md` is created up front; `plan.md` and `status/` are added later,
only if and when the item earns them (a phased rollout, a status log worth
keeping). Many items never grow past the front door alone, and that's fine —
it's still a directory, just a small one.

The front-door file is named **`<name>.md`** (matching the directory), *not*
`README.md`. This is deliberate: it makes the item linkable as a bare
`[[<name>]]` regardless of how much else the directory holds (see Linking).

- **`<name>.md`** — short, living, rewritten in place: what the item is,
  current state, what's next, links to the item's other files. This is what's
  read first when scoped to the item.
- **`plan.md`** — phases, goals, decisions made (and why), considered-and-
  rejected alternatives, success criteria, rollback criteria. Edited in place
  as the plan evolves.
- **`status/`** — dated snapshots (`YYYY-MM-DD.md`, or `YYYY-MM-DD-HHMM.md`
  for the rare multi-snapshot day). Append-only; each captures what moved,
  what's blocked, what's next. Weekly-ish cadence, not daily (that's the
  diary's job).

Optional, added only when earned: **`docs/`** (item-specific documentation —
not a duplicate of repo docs), **`artifacts/`** (diagrams, exports, binaries),
**`bin/`** (item-scoped tooling), **`CLAUDE.md`** (per-item conventions for
complex items), **`risks.md`** (formal risk tracking).

(Directory-only creation is a 2026-07-07 schema change: a single-file item
with no worktree had no directory `workon` could open a session in at all,
forcing manual promotion before you could even start planning it. Existing
items were migrated to match; nothing should create a bare `items/<name>.md`
file anymore.)

## Frontmatter

Required:

| Field | Notes |
|-------|-------|
| `title` | Human-readable name; matches the `#` heading. |
| `status` | One of the six status values above. New items default to `proposed`. |
| `made` | `YYYY-MM-DD` when the item was first captured. |

Optional:

| Field | Notes |
|-------|-------|
| `to` | Person, team, or `self`. Who the work is promised to. `self` for self-directed or unpromised work. Omit if not meaningful. |
| `due` | `YYYY-MM-DD` deadline. Omit when there isn't one. |
| `due-type` | `hard` (must hit) or `soft` (target). Only meaningful with `due:`. |
| `completed` | `YYYY-MM-DD` when status became `completed` or `cancelled`. The name stays `completed:` even for `cancelled`. |
| `related-repos` | Inline list of bare repo names under `~/work/repos/`, e.g. `[Ansible, Internal]`. |
| `related-items` | Inline list of bare item wikilinks, e.g. `[[ad-upgrade]]`, for items that are adjacent without one containing the other. |
| `priority` | Optional ordering hint for the dashboard (`high` / `med` / `low`, or a number). Never required — absence means "let the dashboard derive ranking from due + status + staleness." `high` can lift an item a bucket; `low` marks deliberately best-effort / when-I-get-around-to-it work and **exempts the item from the at-risk staleness nudge** (it sinks to the bottom of `active` but is never flagged stale). |
| `tags` | Inline list of short kebab-case tags. |

## Worktrees

Work items that touch code get a git worktree per repo they touch, in a
unified top-level area: `~/work/worktrees/<name>/<repo>/`, checked out to the
item's working branch off the canonical clone in `~/work/repos/<repo>/`.
Created when the item goes active, removed when it's finished. The worktree
location keys off the item's `<name>` (slug), which is stable across zone
moves, so the worktree doesn't care which zone the item is in. Worktrees are
team code — reference them by backticked path, never wikilink.

Manage them with the `worktree` command rather than raw `git worktree` (it
enforces the `worktrees/<slug>/<repo>/` layout and resolves branches
consistently). The command is a `bash` executable at `~/work/engine/bin/worktree`
(on PATH) — shell-agnostic, so it works from any shell and inside the sandbox
container; fish tab-completion lives at
`~/work/engine/bin/completions/worktree.fish`, symlinked into
`~/.config/fish/completions/`:

```
worktree add  <slug> <repo> [branch]   # branch defaults to <slug>; an existing
                                       # local or remote branch is checked out,
                                       # else a new branch is created off HEAD
worktree rm   <slug> [repo]            # remove the item's worktree(s); branch + history kept
worktree list [slug]                   # show worktrees with branch + clean/dirty state
worktree refresh [repo] [--if-stale]   # fast-forward the canonical clone's integration
                                       # branch (all repos, or one); --if-stale skips
                                       # clones fetched within the last 48h
```

Most items reuse an existing feature branch, so pass the branch name
explicitly — e.g. `worktree add nagios Ansible feature/nagios-pushover`. An
item touching several repos gets one worktree per repo under the same slug
(`worktrees/<slug>/Ansible/`, `worktrees/<slug>/Internal/`); `worktree rm
<slug>` clears them all at once on completion.

## Naming conventions

- **Item names:** lowercase, hyphenated, concise, descriptive at a glance —
  `ad-upgrade`, `rocky-linux-build`, `repo-deployment-strategy-proposal`. No
  version numbers or dates in names (those go in frontmatter or `plan.md`).
- **Front-door file:** `<name>.md`, matching the directory name. Never
  `README.md`.
- **No dates in item names** — `made:` and `due:` carry dates.

## Linking and cross-references

The item name (slug) is the basename and is **stable across zone moves**, so
item links never include the zone:

- **A work item:** bare `[[<name>]]` — resolves to the directory front door
  `items/.../<name>/<name>.md` wherever it sits. This is the canonical link
  form and survives zone changes.
- **A sub-file of a directory item** (status entry, plan, internal doc): use
  the item-name-prefixed suffix form, `[[<name>/plan]]`,
  `[[<name>/status/2026-05-04]]` — also zone-independent.
- **Never put the zone in a link** (`[[items/backlog/foo]]` would rot when foo
  moves). Don't write `[[items/...]]` paths at all; the bare/suffix forms
  resolve regardless of zone.
- **Reminders:** `[[reminders/<YYYY-MM-DD-name>]]`. **Diary:** full path,
  e.g. `[[diary/2026/04/29/2026-04-29.daily-summary]]`. **Documents:**
  `[[docs/<name>]]`. **Repos:** backticked paths, never wikilinks.

## How Claude should engage with work items

### Adding an item

`workitem create` prompts for title, a one/two-sentence description,
placement (active top-level vs. backlog), and optionally `to`/`due` —
creates the item's directory with its front-door file,
`items/<name>/<name>.md`. When creating one conversationally instead, follow
the same shape: `status: proposed` by default, `made:` today, ask for
missing required fields and for `to:` if a promise is implied, ask hard vs.
soft when a `due:` is set. Add `plan.md` and `status/` later, only when the
item earns them — most items never do.

### Surfacing items

Read `items/**` and surface by `status:` from frontmatter. The zone gives the
fast filesystem glance; for precise queries, read frontmatter. Default
surfacing of "what needs attention" = top-level (`active` + `blocked`), sorted
by `due:` ascending (undated last), with `blocked` flagged. `backlog/`
(`proposed` + `deferred`) is surfaced separately as "candidates / paused."
`archived/` is excluded unless asked.

### Changing status

Update the `status:` line. If the change crosses a zone boundary (see
"Attention zones"), move the file/directory to the new zone in the same act.
`active ↔ blocked` is frontmatter-only — no move. When moving to `completed` /
`cancelled`, set `completed:` to today and move to `archived/`.

### Archiving

Moving to `items/archived/` takes an item out of active circulation. Usually
paired with a `completed` / `cancelled` status, but an item set aside
long-term may be archived carrying any status. The body is preserved; archived
content is read-only by convention (fix outright errors only).

`workitem archive <slug> [--completed|--cancelled]` automates the common
case: sets `status:` and `completed:`, moves the item to `items/archived/`,
and removes its worktree(s) if any. For the "set aside carrying any other
status" case, do the move by hand (or ask Claude to).

### Promoting a reminder into an item

When a reminder earns a session, create the item
(`items/<name>/<name>.md`), set the reminder's `status: addressed`, and
optionally archive the reminder. See `reminders/CLAUDE.md`.

## Template

### Item front door (`<name>.md`)

```markdown
---
title: AD Domain-Controller Upgrade
status: active
made: 2026-04-15
related-repos: [Ansible]
tags: [active-directory, infrastructure]
---

# AD Domain-Controller Upgrade

One or two sentences on what this is.

## Current state

What's true right now.

## What's next

The immediate pointed-at work.

## Item files

- [[ad-upgrade/plan]] — phased rollout, decisions, rollback criteria.
- `status/` — dated snapshots; latest: [[ad-upgrade/status/2026-04-26]].
```
