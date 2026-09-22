# Work — Personal Work-Management System (root schema)

`~/work/` is a structured directory for managing my work life: planning,
work-item tracking, tasks, and daily logging. It tracks the lifecycle of
work I take on, work on, and deliver. It is not a knowledge base or wiki — the
focus is on **work**, not on arbitrary information.

The system is self-contained, self-describing, and tool-agnostic (usable
from Claude Code, Cowork, and Obsidian). [[index]] is the curated front
page; this file is the schema that teaches Claude how to engage with the
tree. The pattern is portable in spirit — a structurally similar system
may later be created for personal life, an HOA, etc. — so design choices
here should not assume work context is the only context this shape will
ever serve.

## Design principles

1. **Work-lifecycle curation, not knowledge curation.** Content tracks
   work, not arbitrary information.
2. **Self-describing directory.** Schema lives inside the tree, in
   `CLAUDE.md` files at the root and in each major subdirectory. To
   understand the system, read these files; nothing else is required.
3. **One level of depth at the root.** This file points at per-directory
   schemas for the specifics; subdirectory rules don't get repeated here.
4. **An item's own directory is its complete raw record; retrospectives and
   the index are the layers around it.** Every work item owns its full
   session-by-session history in `items/<name>/log/` — dated entries running
   from rich (an auto-written session breadcrumb, git facts only) to sparse
   (a hand-written `workitem log` entry), one unified timeline, no separate
   "curated" layer living apart from it. Genuinely itemless activity — work
   with no existing item to attach to — isn't a separate tree either: it's
   just an item whose entire lifecycle (born, worked, done) collapsed into
   one instant, created directly into `items/archived/`, born already
   `completed` (see `workitem log`'s "no existing item" path in
   `items/CLAUDE.md`). The `retrospective` skill reads across every item's
   `log/`, recognizing these instant-archived items as their own "ad-hoc"
   category, to produce window consolidations, which live separately under
   `retrospectives/` (kept apart from the raw activity so each is easy to
   read on its own); it can also scope to a single item, in which case it
   reads only that item's own `log/`. The index is the curated overview of
   current state, *generated* by the `dashboard` skill (it leaves the
   hand-owned focus block and the retrospective pointer untouched).
5. **Status lives in frontmatter; location encodes lifecycle stage.** The
   canonical state of a work item or task is the `status:` field in its
   frontmatter. Location is a separate, coarser signal that differs by type:
   - **Work items** (`items/`) sit in one of three attention zones by
     directory — top level (in-flight: `active`/`blocked`), `backlog/`
     (`proposed`/`deferred`), and `archived/` (out of circulation). The
     directory is the coarse zone; frontmatter holds the precise status. A
     status edit and a zone move usually happen together at a transition but
     are conceptually separate acts; the frequent `active ↔ blocked` toggle is
     frontmatter-only (no move), tooled via `workitem block`/`workitem
     unblock`. See `items/CLAUDE.md` for the full set of tooled transitions
     (`activate`/`defer`/`block`/`unblock`/`complete`/`cancel`).
   - **Tasks** (`tasks/`) use the simpler two-way split: in active
     circulation at the top, moved out under `archived/`. Here status and
     location are *coupled*, not independent: a task is either `active`
     (in circulation, top level) or archived, and the `status:` value records
     *why* it was archived — `completed` (followed up / resolved) or
     `cancelled` (turned out not to need follow-up). `completed`/`cancelled`
     therefore imply the file lives under `archived/`; there is no
     completed-but-still-circulating limbo.
   - **Documents** (`docs/`) carry no `status:` field, so location alone is
     the signal: present in `docs/`, archived in `docs/archived/`, or promoted
     into a work item (gone from `docs/` entirely).
   Nothing that represents actual work is deleted; archiving preserves the
   body, and transitions are deliberate, not automatic. Deletion exists, but
   only where there is demonstrably no body to preserve, and each case is
   explicit rather than incidental:
   - **The empty-item sweep** — an item that `workon` created *this* session
     (via `--quick` or a plain create-on-the-fly) and that never accumulated
     anything at all — no commits, no uncommitted changes, no files added to
     its folder, no notes written into the front door itself — is deleted at
     session end rather than archived. An item that already existed before
     the session is never subject to this. See `items/CLAUDE.md`'s "Quick
     items and the empty-item sweep".
   - **Rejecting a candidate** — `workitem delete <slug> --force` on a
     `backlog/` item that isn't going anywhere. It also works on a top-level
     item, and **refuses `archived/` outright**: once something has been
     completed or cancelled it is preserved work, not a candidate.
   - **Discarding a mistaken task** — `worktask delete <name>`, which
     prompts, and requires `--force` non-interactively.
   Everything else archives. Anything that has accumulated real content —
   commits, files, prose — has a body worth keeping, and there is no tooled
   path that throws one away.
6. **Two actionable types: tasks and work items, split on whether work
   gets a session.** A task is an atomic note you action or flip without
   sitting down to work it. A work item is something you sit down and work in
   a dedicated session; it's always a directory (front door `<name>.md`,
   always present), with `plan.md` added only as it's earned and `log/`
   populated automatically the first time a session or a `workitem log`
   entry happens for it (no deliberate "add this" step the way `plan.md`
   gets one). The
   split is operational — *does it get a session?* — not about size or
   promise. Whether work is promised to another person, to oneself, or
   unpromised is a separate dimension captured in the optional `to:` field on
   a work item.
7. **Cross-references inside the tree use Obsidian wikilinks.** External
   targets (URLs, repos, code) use other forms — see Linking below.
8. **YAML frontmatter is the canonical place for structured metadata.**
   General conventions live below; per-content-type fields are defined in
   each subdirectory's `CLAUDE.md`.
9. **System-specific skills live at `~/work/engine/skills/`**, reachable from
   inside this vault via a symlink at `~/work/data/.claude/skills`. The current
   roster is `dashboard` (generates the index from items / tasks / item
   `log/` / git), `retrospective` (rolls up a window, cross-item or
   scoped to one item, and proposes a refreshed `## Current state` for items
   with material progress), and `complete-item` (closes out a finished item —
   drafts its permanent `## Retrospective` section and final `## Current
   state`, then hands off to `workitem complete`/`workitem cancel`; see
   `items/CLAUDE.md`'s "Completing an item"). Capture is manual via the
   `work*` shell commands
   (`worktask`, `workitem`) — engine tooling that lives in
   `~/work/engine/bin/` (shell-agnostic, on PATH), not skills. Coding
   conventions for these scripts (output functions, help format, argument
   parsing, completions) are documented at
   `~/work/engine/docs/bin-coding-standards.md` (a backticked path, not a
   wikilink — it lives in the `work-engine` repo, not this vault; see
   principle 10). The old `daily-summary`, `session-capture`, and
   `standup-prep` skills are retired, superseded by the session breadcrumb
   `workon` writes, `retrospective`, and the dashboard. Skills that are
   general work-practice (useful outside this tree) live in dotfiles at
   `~/.claude/skills/`.
10. **The engine (this schema, the skills, the tooling) and the data (this
    vault's actual content) are separate sibling repos under `~/work`, not one
    tree.** `~/work/data/` is this instance's private content — items,
    tasks, docs, retrospectives, `index.md` — usually its own git
    repo for offsite backup, and never shared between instances (a personal
    instance gets its own `data/`, on its own machine). `~/work/engine/` is the
    shared, versioned `work-engine` repo — this file's canonical source, the
    skills, `bin/` — deployed here and refreshed with a plain `git pull`,
    never hand-edited in place (edit it through `repos/work-engine/` and a
    worktree, same as any other repo — see principle 11). `data/CLAUDE.md` and
    `data/.claude/skills` are symlinks into `engine/`, which is why this file
    and the skills are reachable from inside `data/` without physically living
    there. `~/work/repos/` and `~/work/worktrees/` (below) are ungit'd scratch
    space, siblings of both. No repo's work-tree is ever an ancestor of
    another's root — learned the hard way from an earlier design that nested
    the vault inside the dotfiles repo's work-tree. `~/work/keys/` (below) is
    a third kind of sibling — ungit'd like `repos/`/`worktrees/`, but holding
    sandbox credentials rather than scratch space; see the Directory
    structure section.
11. **Code repositories live under `~/work/repos/`, worked through
    per-item worktrees under `~/work/worktrees/`.** `repos/<repo>/` is the
    **canonical clone** — the reference checkout, kept on the integration
    branch and not worked in directly. Each active work item that touches
    code gets a git **worktree per repo** at `~/work/worktrees/<slug>/<repo>/`,
    on its own branch off that clone, so parallel sessions never share a
    working tree. Worktrees are created/torn down with the `worktree` shell
    command (a `bash` executable in `~/work/engine/bin/`) and removed when the
    item finishes; the clone and branch history are untouched. Both clones and
    worktrees are team code, conceptually separate from the work-management
    content: cross-references to any repo or worktree path use backticked
    paths, never wikilinks. Every commit made inside a worktree is stamped
    with a `Work-Item: <slug>` git trailer (a `commit-msg` hook `worktree add`
    installs into the canonical clone) — a durable, merge-proof record of
    which item a commit belongs to that lives in the commit itself, not just
    in the item's own files. See `items/CLAUDE.md`'s "Commit provenance"
    section.
    *File modes in the sandbox:* inside the container git runs with
    `core.fileMode = false`, because the macOS→Linux bind mount doesn't report
    Unix exec bits reliably (left at the default, pre-commit sees phantom
    executable files). A consequence for **any** git work in a worktree: a
    plain `chmod +x` is invisible to git — set or clear an executable bit
    **explicitly** with `git update-index --chmod=+x <file>` (or
    `git add --chmod=+x <file>`); never rely on the container's file
    permissions to carry into a commit.
12. **Schemas evolve.** Per-directory `CLAUDE.md` files will be revised
    after real use. Persistence of content matters more than stability of
    schema — but silent schema drift is worse than either: revise the
    schema before adding fields it doesn't describe.

## Directory structure

```
~/work/                    # WORK_ROOT — a plain directory, not itself a repo
├── engine/                 # the work-engine repo — deployed copy, kept on main, `git pull` to refresh
│   ├── bin/                 # engine tooling (workon, worktree, workinit, sandbox, work*, breadcrumb, statusline); on PATH
│   │   ├── completions/     # shell completions (fish); on $fish_complete_path, not symlinked
│   │   └── hooks/           # git hook templates (commit-msg: the Work-Item trailer)
│   ├── schema/               # this file + the per-directory CLAUDE.md set (canonical source)
│   ├── skills/               # dashboard, retrospective, complete-item (canonical source)
│   ├── sandbox/              # Docker recipe for the isolated Claude workspace
│   └── docs/                 # engine-facing docs (architecture, usage, bin coding standards)
├── data/                   # this instance's private content — the vault
│   ├── CLAUDE.md             # symlink -> ../engine/schema/CLAUDE.md (this file)
│   ├── .claude/skills        # symlink -> ../../engine/skills
│   ├── index.md              # curated front page (generated by the dashboard skill)
│   ├── items/                # work items — things you sit down and work on
│   │   ├── <name>/           # every item is a directory: front door <name>.md
│   │   │                     #   (always) + plan.md (if earned) + log/ (auto-populated)
│   │   │                     #   log/ holds dated session breadcrumbs + workitem log entries
│   │   │                     #   incoming/ (raw file drops via `workitem add`, if any land)
│   │   ├── backlog/          # proposed + deferred items
│   │   └── archived/         # items out of active circulation, including instant
│   │                         #   "log-<timestamp>" items born straight to completed
│   ├── tasks/                 # atomic notes that need follow-up (no work session)
│   │   ├── <desc>.md          # created: date lives in frontmatter, not the filename
│   │   └── archived/          # tasks moved out of active circulation
│   ├── docs/                  # standalone documents not yet tied to a work item
│   │   ├── <topic-name>.md    # any document
│   │   └── archived/          # documents moved out of active circulation
│   └── retrospectives/        # window roll-ups (consolidations of every item's log/)
│       └── YYYY-MM-DD.retrospective-<N>d.md  # flat; dated by window end, <N>d = span
├── repos/                  # canonical clones — team-shared code AND repos/work-engine (edit clone)
│   └── <repo-name>/         # one per repo; kept on the integration branch, not worked in directly
├── worktrees/              # per-item git worktrees off the canonical clones
│   └── <slug>/<repo>/        # one checkout per active item per repo it touches
└── keys/                   # sandbox SSH credentials + config (mode 700, ungit'd, never in a repo)
    ├── sandbox_github         # per-instance private key(s), whatever this instance's sandbox needs
    └── ssh_config             # this instance's ~/.ssh/config content — see sandbox/home/ssh_config.example
```

`engine/` and `data/` are separate git repos (see principle 10); `repos/`,
`worktrees/`, and `keys/` are ungit'd. For each major `data/`
subdirectory, see its schema at `engine/schema/<name>/CLAUDE.md` for content
rules, filename conventions, and frontmatter fields. The root file deliberately
stops at one level of depth.

Getting a file from the host into a session goes through the item itself,
not a shared drop zone: `workitem add <slug> <path>...` copies the given
files/directories into `items/<slug>/incoming/` (created the first time
it's used — most items never grow one), then tell Claude it's there. Claude
decides what's durable — worth promoting into the item's `artifacts/`/`docs/`
— versus what can simply stay in `incoming/`; nothing there is ever deleted
automatically. Because it lives inside the item's own directory, it's part
of the vault like everything else under `items/<name>/` — tracked, backed
up, never swept on a timer.

`keys/` holds the sandbox container's SSH credentials and `~/.ssh/config` —
created (mode 700) by `workinit`, otherwise entirely hand-populated, and
**never tracked in any repo, engine or vault.** That's the point: which keys
exist and which hosts they map to varies per instance (a personal instance
has no reason to carry a job's internal deploy hosts, or vice versa), so
none of it belongs in shared, versioned content. The engine repo ships only
a generic template, `~/work/engine/sandbox/home/ssh_config.example` — copy
it to `keys/ssh_config` and edit for the instance. Because `~/work/` as a
whole is already bind-mounted into the sandbox container at the same
absolute path (see `sandbox`'s design notes), anything placed under `keys/`
is visible inside the container immediately — no `sandbox recreate` needed,
unlike the container's other creation-time-only inputs (the auth env-file,
`data/sandbox/Dockerfile.local`).

## Conventions

### Markdown

Standard CommonMark with GitHub-flavored extensions (tables, fenced code
blocks, task lists). Renders cleanly in Claude Code, Obsidian, and most
viewers. Use `#` for the document title (one per file) and `##` for
top-level sections — don't skip levels. Use inline backticks for paths,
commands, and identifiers; fenced code blocks (with a language tag where
useful) for multi-line snippets. Soft-wrap is fine; don't break code or
URLs to hit a column count.

### Frontmatter

YAML at the top of a file, delimited by `---` on its own line. General
rules:

- Lowercase, kebab-case keys (`session-num`, not `SessionNum`). Single-word
  keys are fine without separators (`slug`, `title`).
- ISO 8601 for timestamps including local timezone offset
  (`2026-04-29T14:30:00-06:00`). Plain `YYYY-MM-DD` for date-only fields.
- Quote values that YAML would otherwise coerce — notably zero-padded
  numbers like `"01"`.
- Inline arrays for short, flat lists: `repos: [Ansible, Internal]`.
- Per-content-type fields (what a work item or task file must carry) are
  defined in the relevant subdirectory's `CLAUDE.md`.

This file and `index.md` are singletons and don't carry frontmatter; their
shape is described here.

### Linking

- **Inside the tree:** Obsidian wikilinks with vault-relative paths and no
  extension:
  - `[[index]]`
  - `[[ad-upgrade]]`
  - `[[ad-upgrade/log/2026-05-04.ad-upgrade.session.01]]`

  Bare-basename wikilinks (`[[index]]`) are fine when the basename is
  unique in the vault. Otherwise use the full path — most subdirectories
  have a `CLAUDE.md`, so `[[CLAUDE]]` alone is ambiguous.
- **Work items specifically** are always linked by bare name — `[[ad-upgrade]]`
  for the item, `[[ad-upgrade/log/2026-05-04.ad-upgrade.session.01]]` for a
  sub-file. Never put
  the attention zone in the link (`[[items/backlog/foo]]`), so the link
  survives the item moving between zones. The item's front-door file is named
  `<name>.md` precisely so the bare link resolves regardless of what else the
  item's directory holds. See `~/work/engine/schema/items/CLAUDE.md`.
- **Display text:** `[[path|display]]` when the path would read poorly
  inline.
- **External URLs and web sources:** standard markdown links —
  `[Title](https://...)`.
- **Code repositories and code paths:** plain backticked paths, e.g.
  `~/work/repos/Ansible` or `Ansible/bin/update-hosts`. Repos are git
  working trees, not vault markdown content — reference them by path,
  never wikilink.
- **Engine paths** (schema source, skills source, `bin/`, engine docs):
  backticked absolute paths under `~/work/engine/`, e.g.
  `~/work/engine/docs/bin-coding-standards.md`. Same rule as repos and for
  the same reason — the engine is a separate repo from this vault, so a
  wikilink wouldn't resolve.

### File naming

- Lowercase kebab-case for general files: `plan.md`,
  `auto-update-proposal.md`.
- `CLAUDE.md` and `index.md` keep their conventional names exactly.
- An item's `log/` uses strict dated patterns; see
  `~/work/engine/schema/items/CLAUDE.md`.
- No spaces in filenames anywhere in the tree.

### External resources

- **Code repositories:** reference by absolute path under `~/work/repos/`
  (e.g. `~/work/repos/Ansible`) or by repo-relative path inside the repo
  (`Ansible/bin/update-hosts`). The `~/work/repos/` tree holds git
  working trees for team-shared code; treat each repo's contents as the
  team's property, not as personal work-management content.
- **Web sources:** standard markdown links, with the source's title as
  the link text.

## How Claude should engage with this system

### Default scope

The default scope is the whole `~/work/` tree. Treat this file as the
entry point; read subdirectory `CLAUDE.md` files as the work demands.
When focused on a single work item, that item becomes a narrower working
scope, but the root conventions still apply.

### Which schema to read when

- Always check this file first when starting fresh in `~/work/`.
- Read `<subdir>/CLAUDE.md` before authoring or restructuring content in
  that subdirectory. The per-directory file is authoritative for filenames,
  frontmatter fields, and lifecycle rules within its area.
- For a specific work item, its front door is the working context:
  `items/<name>/<name>.md` — read it first, along with `plan.md` when present
  and the most recent `log/` entries for detailed session-by-session history.
  Also check for any tasks pointing back at it — see `items/CLAUDE.md`'s
  "Related tasks". A per-item `CLAUDE.md` may exist for complex items;
  treat it as supplementary context when present.

### Adding or updating content

- A work item's state lives **in the item** — its front door's `## Current
  state` (the only living narrative — rewritten in place, not dated history)
  and its frontmatter; its `log/` is the raw, auto-populated record
  underneath, not something hand-maintained. A task's state lives in its
  own frontmatter. Update state where the work happens; that is the source of
  truth.
- **Do not hand-edit `index.md`, and don't worry when it looks out of date.**
  `index.md` is *generated* by the `dashboard` skill from items + tasks +
  breadcrumbs + git. It is a disposable snapshot, not a maintained file, so it
  is *expected* to lag reality between dashboard runs. When an item moves
  forward, update the item — never reconcile `index.md` to match. To refresh the
  view, run `dashboard`. (Its only hand-owned region is the "Notes / current
  focus" block, which the dashboard preserves; the "Latest retrospective"
  pointer is maintained by `retrospective`.)
- When a work item changes attention zone (commit `backlog → top`, pause
  `top → backlog`, finish `→ archived/`), move the file or directory to the new
  zone; the `status:` frontmatter edit is a separate act that usually
  accompanies the move. The dashboard reflects it on its next run — no index
  edit. For tasks, archiving couples the two: the `→ archived/` move and
  the `status:` edit to `completed` or `cancelled` are the same transition
  (active → archived-with-a-reason), done together.
- Documents have their own per-directory index at [[docs/index]] (not the root
  [[index]]) and carry no `status:` field, so archiving is purely a directory
  move. Otherwise they follow the same lifecycle conventions.
- An item's `log/` is immutable once written — session breadcrumbs and
  `workitem log` entries alike, from the moment they land there. Nothing in
  the tree gets rewritten after the fact; a typo is corrected by hand, same
  as any other historical record.
- If content needs a field the existing schema doesn't describe, revise
  the subdirectory's `CLAUDE.md` first, then add the content. Silent
  schema drift is worse than either changing the schema or omitting the
  field.

### Skills

System-specific skills live at `~/work/engine/skills/`, symlinked into this
vault at `~/work/data/.claude/skills`: `dashboard` (generates `index.md` from
items / tasks / item `log/` / git), `retrospective` (rolls up a
window — cross-item or scoped to a single item — and proposes a refreshed
`## Current state` for items with material progress), and `complete-item`
(closes out a finished item — drafts its permanent `## Retrospective`
section and final `## Current state`, then hands off to `workitem
complete`/`workitem cancel`).
Read a skill's `SKILL.md` before invoking it. The old `daily-summary`, `session-capture`,
and `standup-prep` skills are retired — superseded by the session breadcrumb
`workon` writes, `retrospective`, and `dashboard`. Capture is manual via the
`work*` commands (`worktask` / `workitem`) in
`~/work/engine/bin/`. General work-practice skills (useful outside this
system) also live at `~/.claude/skills/` in dotfiles, not here.
