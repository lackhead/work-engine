---
name: retrospective
description: Roll up what was accomplished over a window — day, week, month, quarter, or an explicit range — by reading session breadcrumbs, jots, item status entries, and worktree git history. Purely local and read-derived (no Slack/calendar). Saves a dated retrospective to ~/work/data/retrospectives/ and proposes curated status/ write-backs for items with material progress.
user_invocable: true
---

Summarize what got done over a requested window and save it to
`~/work/data/retrospectives/`. The
retrospective is **read-derived and local**: it reads session breadcrumbs, the
ad-hoc jot log, item `status/` entries, and git history across the worktrees —
nothing else. The system is curated by intention, so there is **no Slack or
calendar ingestion**; the retrospective recaps what's already been captured, it
doesn't go looking outside the tree.

Two jobs: (1) write a dated retrospective file recapping the window, and (2)
propose curated `status/` write-backs for items that saw material progress. The
second is propose-then-write — it never edits an item without confirmation.

This replaces the old `daily-summary`. A standup needs no separate skill: run a
retrospective over the since-last-standup window for "what I did," and glance at
the `dashboard` for what's outstanding, blocked, and coming due.

## Arguments

A free-form window phrase (defaults to `today` if omitted):

- `today`, `yesterday`
- `past N days` / `last N days`
- `this week` (Mon→now), `last week`
- `this month`, `last month`, `this quarter`, `last quarter`
- `since <weekday>` (most recent past occurrence) or `since <YYYY-MM-DD>`
- an explicit range: `<YYYY-MM-DD>..<YYYY-MM-DD>`

### 1. Resolve the window

Parse the phrase into a `[start, end]` date range (end defaults to now). Derive
two things from it:

- A **span** — `<N>d`, the duration looked back, where `N = ceil((end − start) /
  24h)` floored at `1`. This is what names the output file (step 5); any partial
  day rounds up (an end-of-day recap is `1d`, a `this week` run mid-week reflects
  its actual elapsed coverage like `5d`, a trailing week is `7d`). Always days —
  never weeks/months/quarters.
- A **window class** — `short` (≤ ~2 weeks) vs `long` (month/quarter-scale).
  This drives only the read strategy below, not the filename.

Echo the resolved range **and** the computed span so the user can see what was
interpreted before anything is written (e.g. "since last Wednesday → 2026-06-11
.. 2026-06-16 → span 6d"). The phrase vocabulary (step "Arguments") resolves
deterministically, so most runs need no confirmation — but if the phrase is
genuinely ambiguous or falls outside that vocabulary, **ask the user what they
meant** rather than guessing the range.

### 2. Choose a read strategy

- **Short windows (≤ ~2 weeks):** read raw local sources for the whole window
  (step 3). Everything is local and cheap.
- **Long windows (month/quarter-scale):** to keep the synthesis tractable,
  prefer **already-saved shorter retrospectives** that fall inside the window,
  and read raw only for the uncovered gaps. Discover saved retros in
  `~/work/data/retrospectives/` by filename (`<date>.retrospective-<N>d.md` — the
  date is the window end, `<N>d` the span it covers, i.e. it spans
  `[end − N days, end]`). Pick a **non-overlapping covering set**
  (largest-span-first, so a day inside a saved 7d retro isn't counted twice),
  then fill remaining spans from raw sources. If no shorter retros exist, read
  raw for everything. The factual layer (breadcrumbs/git) is always safe to
  re-read; reusing saved retros is purely a volume optimization, never required
  for correctness.

### 3. Gather local sources in the window

For every date in the window walk `~/work/data/diary/YYYY/MM/DD/` and collect:

- **Session breadcrumbs** — `<date>.<slug>.session.<NN>.md`. Parse frontmatter
  (`slug`, `repo`, `branch`, `commits`, `files-changed`, `start`/`end`) and the
  one-line body. These are the spine of "what was worked, when."
- **Jots** — `<date>.log.md` bullet lines. Tagged jots (`[[slug]]`) attribute to
  an item; untagged jots are loose ad-hoc activity.

Also collect, across the window:

- **Item `status/` entries** written in the range (`items/**/status/<date>.md`)
  — already-curated progress; fold in by reference, don't re-summarize.
- **Git history — the user's own commits only.** Breadcrumbs and jots are the
  *intent* layer but they're lossy: the user sometimes commits without jotting,
  so git is a primary source, not just supporting detail. The catch is that the
  repos are **shared** — `~/work/repos/<repo>` and every worktree's `main` mix
  several admins' commits, and a worktree `git log` shows the *whole* shared
  history. So **always filter by author**:

  ```
  ME=$(git -C ~/work/repos/Ansible config user.email)   # e.g. clake@lackhead.org
  git -C ~/work/repos/<repo> log --all --since=<start> --until=<end> \
      --author="$ME" --format='%h %ad %an <%ae> | %s' --date=short
  ```

  Keep **only** commits authored by the user — never credit a teammate's commit
  (e.g. `jdoe`/`J.Doe@example.org`, `asmith`/`A.Smith@example.org`) to
  the user, regardless of how the commit message reads or which slug's worktree
  it shows up in. Pull from the canonical clones (`repos/`), which see all
  branches, rather than relying on a single worktree's checked-out branch.

Group everything by **slug**. Then **cross-reference the two layers**:

- A commit (by the user) **with** a matching breadcrumb/jot/status → attribute
  to that item.
- A commit (by the user) **with no** matching breadcrumb/jot → still include it
  (it's real work the user forgot to capture); place it by slug if the commit
  touches that item's files/area, else in the ad-hoc bucket. These capture gaps
  are exactly why git is read, not skipped.
- A breadcrumb/jot/status with **no** commit → still counts (planning, non-code
  work, investigations).

Untagged jots and the user's commits not tied to any item collect under an
"ad-hoc" bucket. **When attribution is genuinely ambiguous, ask the user rather
than guessing.**

### 4. Synthesize the recap

Write headline-style, outcome-focused prose — what moved, not a transcript.
Sections:

- **Summary** — 3–6 bullets: the window's headline accomplishments across all
  items.
- **By item** — one subsection per slug that saw activity: what progressed
  (from breadcrumbs + commits + that item's status entries + tagged jots), with
  a light commit/files tally where useful. Link the item (`[[<slug>]]`).
- **Ad-hoc** — untagged jots and the user's stray (item-less) commits, as a
  short list.

Keep it backward-looking. Outstanding / blocked / coming-due is the dashboard's
job — don't duplicate it here.

### 5. Write the retrospective file

Save to `~/work/data/retrospectives/` (a flat directory — no dated subfolders),
named by the window's **end** date and its span:

- `~/work/data/retrospectives/<end-date>.retrospective-<N>d.md`

where `<N>d` is the span from step 1. Overwrite if a file already exists for the
same end-date + span (regeneration is safe). Frontmatter: `type: retrospective`,
`span: <N>d`, `start`, `end`, `generated` (ISO) — there is no `window`/class
field; span plus start/end is the single source of truth. Then the
`# Retrospective — <label> (<start> → <end>)` heading and the sections from
step 4. See [[retrospectives/CLAUDE|retrospectives/CLAUDE.md]] for the
directory's schema.

### 6. Propose status write-backs

For each **directory** item with *material* progress in the window — material =
it has breadcrumbs, the user's own commits, or tagged jots in the range — draft,
but do not yet write:

- a `status/` entry, `items/<slug>/status/<end-date>.md` (or `-HHMM` if one
  exists for that date), summarizing what moved, what's blocked, what's next, in
  the curated voice `status/` expects; and
- a refreshed "## Current state" paragraph for the item's front door.

Present the drafts and ask the user to confirm per item (write / edit / skip).
**Write only on confirmation** — judging significance and framing is the whole
reason this is an LLM skill and not the dumb hook, but the user owns the commit.

**Single-file items** have no `status/` to write to. If one shows sustained
progress (several breadcrumbs accumulating under its slug), don't write status —
instead flag it as a **promotion signal**: suggest promoting it to a directory
item (per `items/CLAUDE.md`). Until then it stays diary-only.

### 7. Update the index pointer

In `~/work/data/index.md`, under `## Latest retrospective`, maintain a single
`- Most recent retrospective: [[retrospectives/<file>]]` line pointing at the
file just written (update only if this window's end date is ≥ the one already
referenced, so back-filling doesn't regress it). If that line doesn't exist yet,
**add it** — and on this first run also remove any leftover retired pointers
(`Most recent daily summary`, `Most recent standup`) from the section. The
`dashboard` regenerates the rest of `index.md` but preserves this section, so
the pointer is the retrospective's to maintain. If the `## Latest retrospective`
section itself is missing, warn rather than fabricating it.

### 8. Print

Print the recap to stdout and the saved file path.

## Notes

- **Local only — no Slack, no calendar.** The retrospective recaps captured
  work. Things never captured (a hallway ask you didn't `workjot`) won't appear;
  that's the accepted trade of intentional curation.
- **Propose, don't autonomously mutate.** Step 6 never writes into an item
  without per-item confirmation.
- **Read-derived.** Source of truth is breadcrumb/jot/status frontmatter and git
  history; the retrospective ranks and frames, it doesn't invent.
- **Re-runs are safe.** The retrospective file regenerates; status write-backs
  are append-only `status/` entries written only on confirmation.
- **Past windows are immutable.** Regenerating the current window is fine;
  treat regenerating an *old* window as fix-outright-errors-only — a
  retrospective reflects what the diary captured at the time.
