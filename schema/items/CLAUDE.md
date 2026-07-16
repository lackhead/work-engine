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
  `workitem block <slug>` / `workitem unblock <slug>` do it.
- **`items/backlog/` — `proposed` + `deferred`.** Candidates and
  intentionally-paused work; consulted occasionally when planning further out.
- **`items/archived/` — out of active circulation.** Always `completed` /
  `cancelled` — set by `workitem complete <slug>` / `workitem cancel <slug>`,
  which also stamps the `completed:` date. The frontmatter status stays
  canonical; the `archived/` location is the separate "not turning this
  over right now" signal.

The directory encodes the zone; the *precise* status (active vs. blocked,
proposed vs. deferred, completed vs. cancelled) stays in frontmatter. Files
move between zones only at deliberate transitions:

- commit a candidate: `backlog → top`, `status: active` — `workitem activate <slug>`
- pause: `top → backlog`, `status: deferred` — `workitem defer <slug>`
- resume: `backlog → top`, `status: active` — `workitem activate <slug>`
- toggle in place: `active ↔ blocked`, no move — `workitem block <slug>` /
  `workitem unblock <slug>`
- finish: `top → archived/`, `status: completed` and the `completed:`
  date — `workitem complete <slug>`
- abandon: `top → archived/`, `status: cancelled` and the
  `completed:` date — `workitem cancel <slug>`
- reject a candidate: `backlog → gone`, no archive — `workitem delete <slug>
  --force` (see "Quick items and the empty-item sweep" and the root
  `CLAUDE.md`'s deletion exception)

`complete`/`cancel` only apply to top-level items — a `backlog` item
(`proposed`/`deferred`) never became active work, so there's nothing to
complete or cancel; it's either promoted with `activate` first, or rejected
outright with `delete`. Status edit and zone move usually happen together at
these transitions, but they remain conceptually separate acts (you can, e.g.,
mark something `cancelled` and archive it in two steps). Nothing genuinely
worked is ever deleted; finished work moves to `archived/`, preserving the
body as historical record — `delete` is reserved for candidates and
placeholders that never became anything.

## Structure

Every work item is a **directory**, created as one from the start — there's
no lighter-weight form and no promotion step. What scales with how much
scaffolding an item earns is what's *inside* the directory, not whether it
has one:

```
items/<name>/
├── <name>.md      # the front door (see naming note below) — always present
├── plan.md        # forward-looking: phases, decisions, success/rollback criteria
└── log/           # dated session-by-session record, auto-populated
```

Only `<name>.md` is created up front; `plan.md` is added later, only if and
when the item earns it (a phased rollout worth writing decisions down for).
`log/` isn't "earned" the same way — it appears automatically the first
time a session or a tagged jot happens for the item, with no deliberate
add-this step. Many items never grow past the front door alone, and that's
fine — it's still a directory, just a small one.

The front-door file is named **`<name>.md`** (matching the directory), *not*
`README.md`. This is deliberate: it makes the item linkable as a bare
`[[<name>]]` regardless of how much else the directory holds (see Linking).

- **`<name>.md`** — short, living, rewritten in place: what the item is,
  current state, what's next, links to the item's other files. This is what's
  read first when scoped to the item. Its `## Current state` is the *only*
  living narrative for the item — there's no separate dated-snapshot history
  alongside it (see "Session log" below for why). At completion, one more,
  one-time section is added — `## Retrospective`, a permanent closing
  narrative distinct from `Current state`'s living summary — see "Completing
  an item" below.
- **`plan.md`** — phases, goals, decisions made (and why), considered-and-
  rejected alternatives, success criteria, rollback criteria. Edited in place
  as the plan evolves.
- **`log/`** — the raw, auto-populated record: session breadcrumbs and
  logged notes, dated, one file per event. See "Session log" below.

Optional, added only when earned: **`docs/`** (item-specific documentation —
not a duplicate of repo docs), **`artifacts/`** (diagrams, exports, binaries),
**`bin/`** (item-scoped tooling), **`CLAUDE.md`** (per-item conventions for
complex items), **`risks.md`** (formal risk tracking).

## Session log (`log/`)

Every event that pertains to an item — a real Claude Code session *and* an
out-of-band note recorded against this item — lands in `log/` as a dated
per-event file, one unified timeline running from rich (a full session
breadcrumb) to sparse (a one-line logged note), rather than two separate
mechanisms. `log/` is **raw and machine/tool-written**, never hand-authored
prose — it's the factual layer underneath the front door's curated
`## Current state`.

`type:` in a `log/` entry's frontmatter is a **provenance** field, not a
fidelity field — it names which of the mechanisms below wrote the entry, and
that alone tells a reader how much detail to expect. Filename shapes,
distinguished by their dot-separated parts (same convention as the old diary
breadcrumbs):

- **`<YYYY-MM-DD>.<name>.session.NN.md`** — a session breadcrumb, written by
  `work-session-breadcrumb`, which `workon` invokes host-side once a session
  against this item ends (a worktree session or an item-folder planning
  session). Frontmatter: `type: session-breadcrumb`, `slug`, `session-num`
  (quoted, `"01"`, `"02"`, ...), `start`/`end` (this run's span, stamped by
  `workon` in local time), `repos` (inline list of the worktrees touched;
  per-repo branch and counts live in the body),
  `dirty`/`commits`/`files-changed` (aggregated across those worktrees), and
  `item-files-changed` (count of files touched in the item's own folder this
  session, excluding `log/`). Body: a one-line summary, optional per-repo
  `## <repo>` sections (`### Commits` / `### Files changed`) and an
  `## Item-folder files touched` list. No interpretation — that's the front
  door's job. The filename date is the local date of `end`. Multiple sessions
  for the item in a day stack as `01`, `02`, ….
- **`<YYYY-MM-DD>.<name>.log.NN.md`** — an out-of-band note recorded directly
  against this item via `workitem log`, for work done outside a Claude Code
  session (a phone, a hallway conversation, another terminal). Frontmatter:
  `type: workitem-log`, `slug`, `time`, optional `commit`. Body: a one-line
  hand-written note. The `SessionStart` hook (`work-session-catchup`)
  surfaces any entry here newer than the item's last known session
  breadcrumb, so a fresh session picks it up as context unprompted — see
  that script's header comment.

Historical items may still carry a `<YYYY-MM-DD>.<name>.jot.NN.md` file
(`type: jot`) — the shape `workjot`'s now-retired item-attribution path used
to write. Nothing writes that shape anymore; existing ones are left exactly
as they are (archived-adjacent content is read-only by convention), and
anything reading `log/` should keep recognizing it alongside `.session.` and
`.log.` files rather than assuming only the current two shapes exist.

**Lifecycle:** everything in `log/` is immutable once written, across every
shape above. A typo in a `log/` entry is corrected by hand, same as a
session breadcrumb would be (rare, and not tooled).

There is no `status/` directory. A prior schema kept dated, curated
snapshots there, written by the `retrospective` skill after confirmation —
dropped because nothing downstream ever read them back (`dashboard` never
did, and `retrospective`'s own long-window strategy composes from other
retrospectives, not `status/`). The one thing it offered — a per-item
narrative without cross-referencing retrospectives — wasn't worth the
write-and-confirm overhead for something effectively never revisited.
`retrospective` now proposes a refreshed `## Current state` paragraph
instead of a dated write-back.

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
worktree list [slug]                   # show worktrees with branch, clean/dirty state, commits
                                       # not merged into the clone's branch, and commits not
                                       # pushed to origin (the actual "could this be lost" signal)
worktree refresh [repo] [--if-stale]   # fast-forward the canonical clone's integration
                                       # branch (all repos, or one); --if-stale skips
                                       # clones fetched within the last 48h
```

Most items reuse an existing feature branch, so pass the branch name
explicitly — e.g. `worktree add nagios Ansible feature/nagios-pushover`. An
item touching several repos gets one worktree per repo under the same slug
(`worktrees/<slug>/Ansible/`, `worktrees/<slug>/Internal/`); `worktree rm
<slug>` clears them all at once on completion.

`workon` always starts a session with the item's own folder as the working
directory — never inside a specific repo's worktree. Every worktree the item
has (zero, one, or several) is attached alongside it, each as its own
`--add-dir`, all equally reachable; there's no "pick one to open." Plenty of
items have no repo at all (document drafting, data analysis, planning-only
work) — for those, a repo was never the point, and this model reflects that
directly: a repo is a purely optional attachment to an item, not something
every item is implicitly built around. `-r/--repo` on `workon` (repeatable)
ensures a worktree exists for a repo — creates it if missing, reuses it if
already there — and attaches it.

Mid-session, Claude can do the same thing itself: run `worktree add <slug>
<repo>` (already on `PATH` in the sandbox, which already runs under
`bypassPermissions`) and then the CLI's `/add-dir` command to attach it to
the *live* session, with no restart and no lost context. This is the expected,
encouraged way to handle "I need to touch one more repo" mid-conversation —
e.g. realizing the best fix is a new fish function in dotfiles while working
a different repo's item — not something to ask permission for first.

## Quick items and the empty-item sweep

`workon --quick` (or `-q`) creates a throwaway item for work too small to
warrant even typing a slug — a fix expected to take under 15–90 minutes, or a
repo-less session just to run a skill (`dashboard`, `retrospective`) or
answer a question. It's a normal item in every structural sense (same
directory, same frontmatter, same `worktree` machinery); the only difference
is `workitem create --quick` skips every prompt (title is generated from a
timestamp if none is given, status is always `active`/top-level).

Whether an item is swept at session end has nothing to do with `--quick`
specifically — it's keyed on whether *this* `workon` invocation is the one
that created the item, which is just as true of a plain `workon <newslug> -c`
on a name that didn't exist yet. Git cleanliness alone never triggers a
sweep, and neither does emptiness alone: an item that already existed before
this invocation is never touched, no matter how uneventful the session, so a
normal planning session on an established item is always left untouched.
Only an item born in this exact invocation is a candidate, and only based on
what's cumulatively true of it right now.

`workon` makes this call itself, host-side, once its `docker exec` into the
session returns (deliberately not `exec`'d into it — see `bin/workon`'s
header comment): if nothing ever landed — no commits unique to the branch in
any attached worktree, no uncommitted changes, nothing added to the item
folder beyond its front-door file (its auto-written `log/` breadcrumb doesn't
count), and no notes written into the front-door file's own content — it runs
`workitem delete <slug> --force` on it: worktree(s) removed, item directory
gone outright, no `archived/` copy. There's nothing to preserve for a
placeholder that was never used, which is why this is deletion and not
archiving — see the root `CLAUDE.md`'s note on that exception. If real work
happened — a commit or uncommitted changes in any attached repo, files added
to the item folder, or prose written into the front door itself — the item
is left exactly as any other active item would be; nothing about it is
special after that point, including whether it's ever archived.

Detecting "notes written into the front door itself" needs more than a file
listing, since `<slug>.md` is always present and can't be told apart from its
own initial template by *existing* — only by its *content* having changed.
Rather than parse or diff that content directly, the sweep reuses a number
`work-session-breadcrumb` already computed moments earlier: the breadcrumb it
writes to `log/` on every session records `item-files-changed`, a count of
files in the item folder (front door included) whose mtime moved since
session start. The sweep greps that field back out of the just-written
breadcrumb file rather than re-deriving it — the marker file the breadcrumb
used for its own `find -newer` check is already gone by the time the sweep
runs, and re-extending its lifetime just for this would entangle two
otherwise-independent mechanisms.

Either way, `workon` prints one line reporting what it decided before
exiting. The "nothing landed" check is cumulative (commits unique to the
branch versus its integration branch), not limited to a single moment in the
session, so nothing here depends on ordering beyond "the breadcrumb for this
session is written before the sweep reads it" — already guaranteed, since
`workon` writes the breadcrumb itself immediately before running the sweep.

## Naming conventions

- **Item names:** lowercase, hyphenated, concise, descriptive at a glance —
  `ad-upgrade`, `rocky-linux-build`. No version numbers or dates in names
  (those go in frontmatter or `plan.md`).
- **Front-door file:** `<name>.md`, matching the directory name. Never
  `README.md`.
- **No dates in item names** — `made:` and `due:` carry dates.
- **Auto-derived and capped at 30 characters.** `workitem create` kebab-cases
  the title into the slug, truncated at a word boundary (never mid-word) so
  a long title doesn't produce an unwieldy directory name. `-s/--slug` gives
  a deliberate short name instead when truncation wouldn't land on a good
  one. Either way, a collision with an existing slug appends `-2`, `-3`, ...
  rather than refusing — expected once slugs are short, not an error.

## Linking and cross-references

The item name (slug) is the basename and is **stable across zone moves**, so
item links never include the zone:

- **A work item:** bare `[[<name>]]` — resolves to the directory front door
  `items/.../<name>/<name>.md` wherever it sits. This is the canonical link
  form and survives zone changes.
- **A sub-file of a directory item** (a `log/` entry, plan, internal doc): use
  the item-name-prefixed suffix form, `[[<name>/plan]]`,
  `[[<name>/log/2026-05-04.<name>.session.01]]` — also zone-independent.
- **Never put the zone in a link** (`[[items/backlog/foo]]` would rot when foo
  moves). Don't write `[[items/...]]` paths at all; the bare/suffix forms
  resolve regardless of zone.
- **Reminders:** `[[reminders/<name>]]`. **Documents:**
  `[[docs/<name>]]`. **Repos:** backticked paths, never wikilinks.

## How Claude should engage with work items

### Adding an item

`workitem create <title...>` is non-interactive: title only, no prompts.
It always creates `items/<name>/<name>.md` with `status: active`, top-level,
`made:` today. Description, `to`, `due`, and any other optional frontmatter
are not collected by `create` at all. When an item's frontmatter is missing
those optional fields — most noticeably right after it was just created —
ask the user conversationally and edit the file directly: is there a
one/two-sentence description worth capturing, is this promised to someone
(`to:`) or self-directed, is there a `due:` and is it hard or soft. There's
no special signal for "this was just created" beyond the fields being empty —
missing optional fields is the whole trigger. Add `plan.md` later, only when
the item earns it — most items never do. `log/` needs no adding; it appears
on its own the first time a session or tagged jot happens.

### Surfacing items

Read `items/**` and surface by `status:` from frontmatter. The zone gives the
fast filesystem glance; for precise queries, read frontmatter. Default
surfacing of "what needs attention" = top-level (`active` + `blocked`), sorted
by `due:` ascending (undated last), with `blocked` flagged. `backlog/`
(`proposed` + `deferred`) is surfaced separately as "candidates / paused."
`archived/` is excluded unless asked.

### Recording out-of-band work

`workitem log [-r|--repo <repo>] [item-slug]` records a note for work that
happened outside a Claude Code session — no need to open one just to leave a
breadcrumb. Repo/commit context (from `-r/--repo`, or the current directory's
repo) and target-item resolution are independent: whichever commit is found
gets offered for recording regardless of where the note ends up. The target
item resolves, in order: the explicit `item-slug` if given (top-level or
backlog only — never `archived/`, since an archived item is closed and
anything after that point is an operational fix, not a log entry); else, if
the current directory is one of that item's worktrees, the item it belongs
to; else an interactive prompt asking whether the note belongs to an existing
top-level item (picked via `fzf` or a numbered fallback) or should become a
new, already-`completed` item created just to hold it (`log-<timestamp>`
slug, no `log/` of its own — the note is the entire content). The
`SessionStart` catch-up hook surfaces any `type: workitem-log` entry newer
than an item's last known session the next time a session starts there, so
nothing logged this way goes unseen.

### Changing status

Use the tooled transitions: `workitem activate`, `workitem defer`,
`workitem block`, `workitem unblock`, and `workitem complete`/`workitem
cancel` (see "Attention zones" above; see "Completing an item" below for the
recommended way to reach `completed` on anything substantial). Each updates
`status:` and, where the transition crosses a zone boundary, moves the
file/directory to the new zone in the same act — `active ↔ blocked` is the
one frontmatter-only case, no move. Fall back to a manual edit only for a
status change that isn't one of these named transitions.

### Completing an item

Before archiving something genuinely finished, run the `complete-item`
skill (`~/work/engine/skills/complete-item/`) from inside a session on that
item. It drafts a permanent `## Retrospective` section (the item's closing
narrative, read from its full `log/` history) and a final `## Current
state` paragraph, confirms both with you, writes them, then runs `workitem
complete` itself to stamp `status: completed`/`completed:` and move the
directory — no separate step to remember. Trivial or `--quick` items can
skip the ceremony and go straight to `workitem complete <slug>`, which sets
`status: completed` and moves it without drafting a retrospective.
Cancellations skip it too — see "Archiving" below.

### Archiving

Moving to `items/archived/` takes an item out of active circulation. Every
archived item carries `completed` or `cancelled` status — there is no other
valid status once in `archived/`. The body is preserved; archived content is
read-only by convention (fix outright errors only).

`workitem complete <slug>` and `workitem cancel <slug>` are the only
supported paths — each sets the respective status, stamps `completed:` with
today, moves the item to `items/archived/<slug>/`, and removes its
worktree(s), if any. There's no bare "archive, decide later" verb: the verb
itself is the status decision, made explicitly every time. Both apply to
top-level items only; a `backlog` candidate that's being rejected is
`workitem delete`d instead, not completed/cancelled — see "Attention zones."

### Promoting a reminder into an item

When a reminder earns a session, create the item
(`items/<name>/<name>.md`), set the reminder's `status: completed`, and
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
- `log/` — session-by-session record (auto-populated).
```

### Retrospective section (added at completion)

Written once, by the `complete-item` skill, directly after `## Current
state` and before `## Item files` — `## What's next` is dropped at this
point, since nothing is next once an item is done:

```markdown
## Current state

**Complete.** One or two sentences summarizing the outcome.

## Retrospective

*2026-07-13 → 07-14 · 5 sessions · ~15 commits.* One or two sentences
framing the arc, then bullets by theme:

- **Theme A:** what happened, what it fixed or delivered.
- **Theme B:** ...

*Process note:* anything learned worth remembering next time (optional).

## Item files
```
