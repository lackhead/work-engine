---
author: Chad Lake
date: MMMM dd, YYYY
paging: Slide %d / %d
---

# The Work Engine
A tour of the system I built to track work — for me, and for Claude

---

## The problem
- Work status/context lived in multiple places —  apps, Slack, sticky notes, git history, my head. Checking status meant hunting across all of them, and things fell through the cracks
- A Claude Code session had zero memory of "where did I leave this?" — every session started from scratch meant re-explaining context I'd already established, or worse, working off stale assumptions
- I often did work manually separately and looped Claude in when needed— which meant Claude rarely had full context, and catching it up with reality was its own manual chore

---

## The problem, continued
- "What did I actually do this week?" meant scrolling everywhere context lived and hoping I could find everything— no way to self-review, spot a stalled item, or write a standup update without real archaeology
- Every AI session on my laptop meant a wall of permission prompts — wasted time, cognitive overload, and a real risk of missing something that mattered in the noise. Worse: the "not another prompt" reflex nudged toward granting *broader* permissions than the task needs, just to make it stop

---

## Why not just use an existing tool?
- I wanted something Claude could read and write directly — no API, no sync, no export step
- Portability- I wanted everything to be readable without any special tools — plain files a text editor opens fine. Claude Code, Obsidian, glow, etc...all work, but nothing specific is required
- I wanted isolation:
	- git is the *only* interface the agent has to my actual work environment: if it's not in git, it's something I did by hand. 
	- the sandbox protects the *dev machine* (where this system runs) from the agent itself

So: Markdown for content, **YAML frontmatter** for structured fields — human-readable and machine-parseable, no separate database, git tracks everything

---

## Quick definitions
- **slug** — the lowercase-kebab-case identifier for an item or task; also its directory/file name (`nagios`, `ad-upgrade`)
- **vault** — `~/work/data/` — my private content: items, tasks, docs, retrospectives, etc
- **sandbox** — the isolated Docker container every Claude Code session actually runs inside
- **work item** — something you sit down and work on in a dedicated session
- **work task** — an atomic note you action or flip, no session needed

---

## Sandbox: Claude runs in a container
- Motivation: permission-prompt fatigue — most prompts get approved anyway, pure friction
- The fix: relax permissions *inside an isolated container*, not on the host — blast radius is whatever the sandbox can authenticate to, not my whole laptop
- One persistent container; every session `docker exec`s into it; `~/work` is bind-mounted at the same absolute path, no path translation, ever
- Claude Code's own state — login, session transcripts — lives on a separate named Docker volume, not baked into the container
- Fully disposable: destroy and rebuild the container any time — the vault, git history, and Claude's own login/transcripts all live outside it, untouched

---

## Sandbox: lifecycle & shell access
| Command            | Does                                                   |
| ------------------ | ------------------------------------------------------ |
| `sandbox up`       | Start it, or create it the first time                  |
| `sandbox status`   | Check image / container / volume state                 |
| `sandbox restart`  | Stop + start, no rebuild — e.g. a hung container       |
| `sandbox recreate` | Picked up a new env-file or host timezone change       |
| `sandbox rebuild`  | Dockerfile changed — rebuild image, then recreate      |
| `sandbox shell`    | Drop into an interactive fish shell, no Claude session |

---

## Sandbox: mounts and files

| Host                  | Container            | What                                                   |
| --------------------- | -------------------- | ------------------------------------------------------ |
| `~/work`              | `~/work` (same path) | Everything — engine, vault, repos, worktrees, keys     |
| `claude-home` volume  | `~/.claude`          | Claude Code's own login + session transcripts          |
| `claude-cache` volume | `~/.cache`           | Regenerable caches (e.g. pre-commit hook environments) |
- SSH credentials live at `~/work/keys/` (mode 700, never in a repo) — already covered by the `~/work` mount, so a key added there works in any running session immediately, no recreate needed
- The container restarts itself and `workon` starts it if it's not already up — day to day there's no sandbox management at all, just an occasional `sandbox rebuild` when packages need refreshing

---

## How it's all laid out in the directory
```
~/work/
├── engine/     schema + tooling + skills (shared, versioned, `git pull`)
├── data/       my vault — items, tasks, docs (private, per-instance)
├── repos/      canonical clones of team code
├── worktrees/  one git worktree per item per repo it touches
└── keys/       this instance's sandbox SSH keys (never in a repo)
```
- `engine` and `data` are separate, sibling git repos:
	- `engine/` lives on GitHub, shared across every instance
	- `data/` is its own private repo, never shared
- `data/CLAUDE.md` is a symlink into `engine/` — schema and skills always in sync
- The vault is meant to be human-*readable*, not human-*edited* — Claude owns writing to it; hand-editing a file should be rare, ideally never

---

## Two things you ever act on
- **A work item** — something you sit down and work in a dedicated Claude Code session
  - `workitem create Rework the nagios push notifications`
- **A task** — an atomic note you action or flip *without* a session — "don't lose this"
  - `worktask create Call John back about the firewall exception`
- The split is operational, not about size: *does it get a session?* Yes → item. No → task
- Everything else in the system exists to support one of these two

---

## Inside the vault
```
data/
├── items/            work items — top level (active/blocked),
│                     backlog/, archived/
├── tasks/            atomic follow-ups — top level, archived/
├── docs/             standalone documents, not yet tied to an item
├── retrospectives/   window roll-ups (dated, cross-item)
└── index.md          generated snapshot — never hand-edited
```
- Tasks follow the same zone pattern as items, just simpler — two-way (active / archived) instead of three
- `index.md` and everything under `retrospectives/` are both produced by skills — covered in "Claude skills: dashboard and retrospective"

---

## Work Items: creation
- `workitem create <title>` — new item, top-level, status `active`
- `workon <new-slug> -c` — create-and-open in one step, for a named item
- Every item is a directory, from the start — no lighter-weight form:
```
items/<slug>/
├── <slug>.md   front door — always present
├── plan.md     added only if the item earns it
├── log/        auto-populated — first session or note
└── incoming/   raw file drops, created only when used
```

---

## Work Items: keeping them up to date
- `## Current state` in the front door — the *one* living narrative, rewritten in place as things move, not a dated history
- `log/` underneath it — the raw record: automatic session breadcrumbs (git facts — commits, files touched) plus hand-written `workitem log` notes
- Every commit made in the item's worktree is stamped `Work-Item: <slug>` automatically — provenance with no extra step
- Claude keeps `<slug>.md` current as part of ending a session — no manual "go update the ticket" step, and no expectation that I hand-edit `Current state` or `log/` myself

---

## Work Items: statuses & zones
```
backlog/ (proposed, deferred)
   │  workitem activate
   ▼
top level (active ⇄ blocked)      workitem block / unblock
   │  workitem complete / cancel
   ▼
archived/ (done, out of circulation)
```
- Three zones by directory; `status:` in frontmatter is the precise value
- The most frequent toggle — `active ⇄ blocked` — is frontmatter-only, no directory move
- `backlog/` sits outside the everyday view on purpose — plain `workitem list`, `complete`/`cancel` tab-completion, and the empty-item sweep all skip it. That's the real distinction from `blocked`: blocked stays fully visible and actionable, just paused; backlog is deliberately out of sight until activated

---

## Work Items: finishing them up
- `workitem complete <slug>` / `workitem cancel <slug>` — set status, stamp the date, move to `archived/`, clean up the item's worktree
- For anything with real history behind it: run the `complete-item` skill first — it drafts a permanent `## Retrospective` from the item's whole log, then hands off to `complete`/`cancel` itself
- A trivial or `--quick` item skips the ceremony — straight to `workitem complete`, nothing to draft

---

## Work Items: commands quick reference
| Command | Does |
|---|---|
| `create [title]` | New item (`-q` quick, `-b` backlog, `-s <slug>`) |
| `list` | List items (`--backlog`/`--archived`/`--all`, `--status`) |
| `show <slug>` | Print an item |
| `log [slug]` | Record work done outside a session |
| `add <slug> <path>...` | Copy files into the item's `incoming/` |
| `activate <slug>` | `backlog/` → top level |
| `defer <slug>` | top level → `backlog/` |
| `block` / `unblock <slug>` | Toggle blocked — frontmatter only, no move |
| `complete` / `cancel <slug>` | Done / abandoned → `archived/` |
| `rename <slug> <new-slug>` | Rename, history preserved |
| `delete <slug> --force` | Reject a `backlog/` candidate outright |

---

## Work Items: `workon -q` and `workitem log`
- `workon -q [title]` — quick/throwaway item, generated slug, opens a session immediately. If nothing durable lands by session end (no commits, no files, no notes), it's swept away automatically rather than left as clutter
- `workitem log [slug]` — record work done *outside* a session: a fix made by hand, a quick note, an investigation — one line, no Claude session required
- Both exist for the same reason: not everything worth capturing deserves the ceremony of a full session or a deliberate `workitem create`

---

## The philosophy behind it
- **Status lives in frontmatter.** Directory location (top-level / `backlog/` / `archived/`) is just a coarse, at-a-glance signal — never the source of truth
- **Generated views, never hand-maintained.** The vault's curated overview and its window roll-ups are both derived, not authored — see "Claude skills: dashboard and retrospective" for where they live and how they're built
- **Persistence over deletion.** Archiving preserves the full body — commits, files, prose. Real deletion is a narrow, explicit exception (an empty quick item swept at session end, a rejected backlog candidate) — never the default
- **Self-describing.** The schema lives *in* the tree, not in someone's head
- **Schemas evolve, but never silently** — a field is added to `CLAUDE.md` before it's added to content
- The same shape could serve a personal vault, or anything with a work lifecycle

---

## Work Tasks: lifecycle
- `worktask create <description>` — fire-and-forget, one line, status `active`
- `-i <slug>` attaches it to a work item; otherwise it stands alone
- Only two states: `active` (circulating) or archived — and archiving always records *why*: `completed` (followed up) or `cancelled` (turned out not to matter)
- `worktask log <name> [note]` — appends a timestamped progress note, no session needed
- `worktask promote <name>` — graduates a task into a full work item when it earns a session, archiving the task in the same step

---

## Work Tasks:  command quick reference
| Command             | Does                                              |
| ------------------- | ------------------------------------------------- |
| `create [desc]`     | New task (`-i <slug>` attaches it to an item)     |
| `list`              | Active tasks (`--archived`/`--all`)               |
| `show <name>`       | Print a task                                      |
| `log <name> [note]` | Append a timestamped progress note                |
| `complete <name>`   | Followed up → `archived/`                         |
| `cancel <name>`     | Turned out not to matter → `archived/`            |
| `due <name> [date]` | Set or clear the due date                         |
| `promote <name>`    | Graduate into a work item, in one step            |
| `delete <name>`     | Remove outright                                   |

---

## Claude skills: dashboard and retrospective
- `dashboard` — regenerates `index.md` (vault root — see "Inside the vault"): ranked active/blocked items, backlog, due tasks, a suggested focus. Preserves the hand-owned "Notes" block
- `retrospective [item] <window>` — rolls up a window (`today`, `this week`, `since Tuesday`, a quarter) cross-item or scoped to a single item; cross-item runs save a dated file under `data/retrospectives/`, plus a proposed refreshed `## Current state` for items with real movement — never written without confirmation
- Both run *inside* a Claude Code session, not as standalone scripts — and both are **read-derived**: they rank and summarize what's already captured in `log/`, commits, and frontmatter, never inventing state

---

## Codebases: repos and worktrees
- `repos/<repo>/` — the canonical clone, kept on the integration branch, never worked in directly
- `worktrees/<slug>/<repo>/` — one git worktree per item per repo, its own branch — parallel items never share a working tree
- Why worktrees specifically: one clone, many working directories — no re-cloning per item, no stashing to switch between items, and two items (even a teammate's) can be checked out against the same repo at once without stepping on each other
- `workon` opens a session with the item's own folder as home; every worktree it has is attached alongside it
- Every commit made inside a worktree gets the `Work-Item: <slug>` trailer stamped automatically via a commit-msg hook

---

## Vault Backups
- `~/work/data` (the vault) is the only thing that needs backing up — `engine/` is just a GitHub clone, `repos/`/`worktrees/` are regenerable
- This instance: a launchd job runs `work-backup` every 4 hours, committing any vault changes and pushing them offsite
- Nothing to do day to day; `work-backup` forces a commit + push right now if I want one

---

## What I actually use daily

**Commands**

| Command | Does |
|---|---|
| `workitem create <title>` | New work item |
| `workitem log [slug]` | Record work done outside a session |
| `worktask create <desc>` | Capture a follow-up, no session needed |
| `workon <slug> [-r repo]` | Open a Claude session for an item |
| `worktree add <slug> <repo>` | Attach a repo to an item |
| `workitem complete <slug>` | Close it out |

**Skills**

| Skill | Does |
|---|---|
| `dashboard` | What's on my plate right now |
| `retrospective [window]` | What did I actually do |

---

## Current limitations
- Shell tooling is fish-only today — `bin/` scripts themselves are portable bash, but completions and prompt integration assume fish
- Assumes a Mac laptop as the host today — Docker Desktop, launchd for backups. Porting to Linux would be straightforward (same bind-mount model, a systemd timer instead of launchd) — just hasn't been done
- No sharing/team features out of the box — the `Work-Item:` trailer and shared worktree model give provenance, but there's no shared dashboard, no notifications, no cross-person conflict handling, etc
- Single-user sandbox model — one container, one set of SSH keys per instance; not multi-tenant
- Still evolving by design — the schema expects fields and skills to change as real use finds gaps, not a finished v1.0

---

## Example: a typical day
1. First thing: `dashboard` — what's due, what's falling behind on its plan, where to actually start
2. `workon nagios` → Claude session opens, worktree attached, resumes last session. I'll often have two or three `workon` sessions going at once, switching between them while one's still thinking
3. `workitem log -r Ansible` — quick fix outside a session, one line, attaches the commit
4. `worktask create check the alert threshold held overnight`
5. End of day: `workon -q` → throwaway session just to run `retrospective today` for standup material — nothing else lands in it, so it's swept away automatically when it ends

---

## Example: a concrete walkthrough
```bash
$ workitem create -s nagios-push-notifications \
    Design, implement, and deploy push notifications for critical nagios alerts
$ worktree add nagios-push-notifications Ansible feature/nagios-pushover
$ workon nagios-push-notifications -r Ansible
# ...Claude session: edits, commits, done...
$ git log -1
    Add nagios pushover integration

    Work-Item: nagios-push-notifications
$ workitem complete nagios-push-notifications
```
- The `Work-Item: nagios-push-notifications` trailer is stamped automatically by a commit-msg hook
- "What work item touched this file?" stays answerable from git alone, forever

---

## If a team used this 
- Same engine (schema, tooling, sandbox recipe — including a shared Dockerfile) for everyone: one shared `git pull`, a consistent dev environment, and zero-fuss setup for a new team member — no personal toolchain to assemble
- Same team-code repos and worktree model — anyone can pick up anyone's item and find its context
- The `Work-Item: <slug>` trailer is readable by teammates too, not just the author — provenance survives regardless of who's using the system
- Shared `CLAUDE.md` files double as shared coding/writing standards — not just schema for the tool, but conventions every person (and every Claude session) follows the same way
- Each person still keeps their own private vault and sandbox — shared tooling, not shared state

---

## Trying it yourself
```bash
brew install git fish fzf jq
brew install --cask docker
git clone git@github.com:lackhead/work-engine ~/work/engine
workinit -v
sandbox build && sandbox up
workon <any-item>
```
- About 15–20 minutes on a clean machine
- Full walkthrough: https://github.com/lackhead/work-engine/blob/main/docs/work-system-setup.md

---

## Questions?
- Repo: https://github.com/lackhead/work-engine — docs, schema, and skills all live there
- Happy to pair on a first setup
