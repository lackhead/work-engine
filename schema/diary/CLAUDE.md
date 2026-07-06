# Diary (per-directory schema)

The diary is the running stream of dated activity in this system —
what got worked on, what got decided, what got said, day by day.
Unlike the curated overview at [[index]], the diary captures events
as they happen and accretes; past entries are not rewritten.

The diary holds several file types, all produced automatically rather
than written by hand: **session breadcrumbs** are written by the
`SessionEnd` hook when a Claude Code session ends, while **daily
summaries** and **standup notes** are produced by their skills. (A legacy
**session capture** type, hand/skill-written, is being retired in favour
of breadcrumbs — see below.) Authoring diary files by hand is unusual;
the hook and skills handle file naming, frontmatter, output paths, and
any downstream side effects (Slack post, [[index]] update).

Vault-wide conventions live in [[CLAUDE]]. This file specifies how
those apply to the diary and the conventions specific to each diary
file type.

## Directory layout

```
~/work/data/diary/
└── YYYY/
    └── MM/
        └── DD/
            ├── <YYYY-MM-DD>.<slug>.session.<NN>.md  # session breadcrumb (hook-written)
            ├── <YYYY-MM-DD>.log.md                   # ad-hoc jot log (one per day, workjot-written)
            └── <YYYY-MM-DD>.<slug>.<NN>.md           # session capture (legacy, not written anymore)
```

(The former `<date>.daily-summary.md` and `<date>.standup.md` types are retired —
see "Daily summaries & standups (retired)" below. **Retrospectives no longer live
in the diary** — they moved to their own top-level [[retrospectives/CLAUDE|`~/work/data/retrospectives/`]]
directory, keeping the raw activity stream separate from its consolidations.)

- One folder per day. Empty days have no folder — the tree only
  contains days that produced at least one entry.
- Years and months are zero-padded (`2026/04/29`, not `2026/4/29`).
- The day folder may contain any combination of these file types.

## File types

The file types are distinguishable by their dot-separated filename structure.
Session breadcrumbs carry a literal `session` part
(`<date>.<slug>.session.<NN>.md`, five parts); legacy session captures have four
(`<date>.<slug>.<NN>.md`); the ad-hoc jot log has three (`<date>.log.md`).

### Session breadcrumbs

**Filename:** `<YYYY-MM-DD>.<slug>.session.<NN>.md`

Written automatically by the `SessionEnd` hook
(`~/.claude/hooks/work-session-breadcrumb`) when a Claude Code session
ends. The hook is user-global, so it fires for every session; it writes a
breadcrumb only when the session's working directory is inside `~/work`
(a worktree under `worktrees/<slug>/`, or an item folder under
`items/<slug>/`), and silently does nothing otherwise. The `<slug>` is
derived from that path. Multiple sessions for one slug in a day stack as
`01`, `02`, ….

Breadcrumbs are **factual and machine-written** — git and session facts
only, no interpretation. Curated, human-framed progress is written
separately (by the retrospective skill, or an explicit "update item X"),
never by the hook, and breadcrumbs are **not** mirrored into an item's
`status/`. A worktree session records the repo, branch, dirty state,
commits authored during the session window, and files changed; an
item-folder (planning) session records just the session facts.

**Frontmatter:**

| Field | Notes |
|-------|-------|
| `type` | Always `session-breadcrumb` |
| `slug` | Derived from the session's cwd |
| `session-id` | Claude Code session UUID |
| `session-num` | Quoted per-day sequence (`"01"`, `"02"`, …) |
| `start` | ISO 8601 — first transcript-line timestamp (session window start) |
| `end` | ISO 8601 — session end |
| `repo` | Worktree's repo; omitted for item-folder sessions |
| `branch` | Current branch; omitted when not a git worktree |
| `dirty` | `true`/`false`; omitted when not a git worktree |
| `commits` | Count of commits authored in the window |
| `files-changed` | Count of files changed in the window |
| `reason` | The `SessionEnd` reason (`clear` / `logout` / `prompt_input_exit` / `other`) |
| `transcript` | Path to the session JSONL transcript |

**Body:** a one-line human-readable summary, then optional `## Commits`
and `## Files changed` lists. No curated prose — that's the
retrospective's job. Breadcrumbs are **not regenerable**: each session
writes one and it persists.

### Ad-hoc jot log

**Filename:** `<YYYY-MM-DD>.log.md` (one per day)

An append-only stream of timestamped one-liners recording **ad-hoc work** —
quick fixes, hallway debugging, "Kate flagged X and I sorted it": activity that
never gets a Claude Code session and so leaves no breadcrumb. Written by the
`workjot` command (and, in future, by ingesting the `#chad-log` Slack channel);
not authored by hand as a rule.

Where a breadcrumb says "a session happened on item X," a jot says "I did this
ad-hoc thing." A jot may carry a `[[<slug>]]` tag attributing it to a work item
(which lets the retrospective fold it into that item's progress); untagged jots
are just dated activity. When the work involved a commit, `workjot` appends the
commit's `<repo>@<branch> <hash> "<subject>"` after confirming it.

**Frontmatter:** `type: jot-log`, `date: <YYYY-MM-DD>` — set once on the day's
first jot.

**Body:** an `# Jot log — <date>` heading, then bullet lines of the form
`- HH:MM — <note> [[<slug>]] (<repo>@<branch> <hash> "<subject>")`, where the
tag and commit clause are optional. Append-only; like all diary entries, past
days are immutable.

### Session captures (legacy)

**Filename:** `<YYYY-MM-DD>.<slug>.<NN>.md`

> **Being retired.** This hand/skill-written type is superseded by the
> hook-written session breadcrumbs above. The
> [[../.claude/skills/session-capture/SKILL|session-capture]] skill is
> kept only until the `SessionEnd` hook has soaked over a few real
> sessions; existing captures remain as historical record. Don't author
> new ones.

Generated by the session-capture skill at natural stopping points during
a working session. One file per topic per session — multiple captures
with the same slug in a day stack as `01`, `02`, ....

The slug is either a project directory name (`patching-infrastructure`)
or an ad-hoc kebab-case topic (`workspace-restructure`). When the
slug matches a project directory, the file's frontmatter sets
`project:` to the same value as an explicit linkage (separate from
the inferential slug match).

**Frontmatter:**

| Field | Notes |
|-------|-------|
| `title` | Title-case, short |
| `slug` | The chosen slug |
| `project` | Project directory name when slug matches a project; omitted otherwise |
| `start` | ISO 8601 with TZ offset |
| `end` | ISO 8601 with TZ offset |
| `session-num` | Quoted string (`"01"`, `"02"`, ...) — YAML would coerce unquoted zero-padded values |
| `repos` | Inline list of bare repo names touched, e.g. `[Ansible, Internal]` |
| `branches` | Inline list of branches touched |

**Body sections:** `## Summary`, `## Artifacts`, `## Open Issues / Next Steps`. See the session-capture skill for content rules.

### Retrospectives (moved out of the diary)

Retrospectives — the on-demand window roll-ups produced by the
[[../.claude/skills/retrospective/SKILL|retrospective]] skill — **no longer live
in the diary.** They now have their own top-level directory,
[[retrospectives/CLAUDE|`~/work/data/retrospectives/`]], so the raw dated activity
stream (this directory) stays separate from the consolidations derived from it.
See that directory's `CLAUDE.md` for filename and frontmatter rules. (A standup
is still just a retrospective window plus a dashboard glance — no separate file.)

### Daily summaries & standups (retired)

The former `<date>.daily-summary.md` (daily-summary skill) and
`<date>.standup.md` (standup-prep skill) types are **retired** — superseded by
retrospectives (local roll-ups on demand) and the dashboard (which surfaces
what's outstanding / blocked / coming due). Existing files of these names remain
as historical record; no new ones are written.

## Lifecycle and integrity

The diary is **append-only as a stream**. New entries are added every
day; old entries stay where they are. Specifically:

- **Past-day entries are immutable** except to fix outright errors
  (typo, mis-attributed person, wrong file path). The diary reflects
  what was true at the time.
- **Retrospectives are regenerable** — re-running the skill for the same
  window overwrites that file. This is fine for current-window regeneration;
  treat past-window regeneration as the same "fix outright errors only" rule.
- **Session captures are not regenerable** — once written, they're
  persistent. New session captures get new `session-num` values.
- **There is no `archived/` subdirectory.** Diary entries don't
  transition between active and archived; they accumulate.

## How Claude should engage with the diary

### Reading

- **"What was I doing recently?"** — read recent daily-summary files
  in `diary/YYYY/MM/DD/`. They roll up that day's session captures.
- **"What was the state of project X on date Y?"** — read session
  captures matching `<date>.X.*.md` in the day's folder.
- **"What was discussed at standup on date Y?"** — read
  `diary/YYYY/MM/DD/<date>.standup.md`.

### Writing

- **Don't author diary files directly.** Session breadcrumbs are written
  automatically by the `SessionEnd` hook; ad-hoc jots go in via the `workjot`
  command; `daily-summary` produces end-of-day rollups and `standup-prep` the
  standup notes. (The legacy `session-capture` skill still exists during the
  breadcrumb soak but is being retired — don't reach for it.)
- **The hook and skills handle everything downstream:** file naming,
  frontmatter, output paths, [[index]] pointer updates, Slack posts.
  Doing it by hand means hand-doing those side effects.

### Cross-references to diary entries

Use full vault-relative wikilinks pointing at specific files:

- `[[diary/2026/04/29/2026-04-29.standup]]`
- `[[diary/2026/04/29/2026-04-29.daily-summary]]`
- `[[diary/2026/04/29/2026-04-29.patching-infrastructure.01]]`

The diary directory itself isn't a wikilink target. The day folder
isn't a wikilink target either — link a specific file inside it.
