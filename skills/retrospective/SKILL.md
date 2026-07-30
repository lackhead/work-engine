---
name: retrospective
description: Roll up what was accomplished over a window — day, week, month, quarter, or an explicit range — cross-item or scoped to a single item — by reading each item's own log/ (session breadcrumbs + logged notes) and worktree git history. Purely local and read-derived (no Slack/calendar). Saves a dated cross-item retrospective to ~/work/data/retrospectives/ and proposes a refreshed Current state for items with material progress.
user_invocable: true
---

Summarize what got done over a requested window, optionally scoped to a
single item, and (for cross-item runs) save it to
`~/work/data/retrospectives/`. The retrospective is **read-derived and
local**: it reads each item's own `log/`, plus every item's front door (for
the instant `log-<timestamp>` items born straight to `completed` — see
below), and git history across the worktrees — nothing else. The system is
curated by intention, so
there is **no Slack or calendar ingestion**; the retrospective recaps what's
already been captured, it doesn't go looking outside the tree.

Two jobs: (1) recap the window — cross-item runs write a dated retrospective
file, item-scoped runs just print (see "Write the retrospective file" below
for why); and (2) propose a refreshed `## Current state` paragraph for items
that saw material progress. The second is propose-then-write — it never
edits an item without confirmation.

This replaces the old `daily-summary`. A standup needs no separate skill: run a
retrospective over the since-last-standup window for "what I did," and glance at
the `dashboard` for what's outstanding, blocked, and coming due.

## Arguments

A free-form window phrase (defaults to `today` if omitted), optionally
preceded by an item slug to scope the whole run to just that item:

- `<window phrase>` — cross-item, the default.
- `<item-slug> <window phrase>` — e.g. `nagios last week`. Recognize this
  form by checking whether the first token matches an existing item's slug
  (`items/<slug>/`, `items/backlog/<slug>/`, or `items/archived/<slug>/`); if
  it doesn't match any item, treat the whole argument as just the window
  phrase instead.

Window phrase vocabulary:

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

**Item-scoped runs always read raw, regardless of window length.** The
corpus is just one item's own `log/`, already bounded by that item's
lifetime — there's no volume problem to optimize away, and nothing is saved
to `retrospectives/` for these anyway (see step 5).

**Cross-item runs:**

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
  raw for everything. The factual layer (`log/`/git) is always safe to
  re-read; reusing saved retros is purely a volume optimization, never required
  for correctness.

### 3. Gather local sources in the window

**Item-scoped run:** walk just `items/<slug>/log/` (wherever that item
currently sits — top level, `backlog/`, or `archived/`), filtering entries to
the window by their `start`/`end` (breadcrumbs) or `time` (logged notes).
Collect:

- **Session breadcrumbs** — `<date>.<slug>.session.<NN>.md`. Parse frontmatter
  (`type`, `slug`, `session-num`, `start`/`end`, `dirty`, `commits`,
  `files-changed`, `item-files-changed`, and `repos` — an inline list, present
  only when at least one worktree was touched) and the one-line body. There is
  no `repo:` or `branch:` field; per-repo branch and counts live in the body.
- **Logged notes** — `<date>.<slug>.log.<NN>.md`, which covers two `type:`
  values: `workitem-log` (sparse, hand-written, from `workitem log`) and
  `item-rename` (tool-written, carrying `former-slug:` — the item was renamed
  at that moment, which is usually worth a line in the recap). Also any legacy
  `<date>.<slug>.jot.<NN>.md` (`type: jot`, from before `workitem log` — see
  `items/CLAUDE.md`'s "Session log" section); keep recognizing it.

  A renamed item's older entries keep the **old** slug in both filename and
  `slug:` frontmatter, since `log/` is immutable. Group by the item's current
  directory, not by the `slug:` field, or a rename will split one item's
  history into two.
- **The user's own commits** in that item's worktree(s), filtered by author
  and date range (see the git filtering rule below).

**Pre-`log/` history lives outside the item.** Before item-owned `log/`
directories existed, breadcrumbs were written to a dated tree at
`~/work/data/diary/<YYYY>/<MM>/<DD>/`, in the same
`<date>.<slug>.session.<NN>.md` shape but with a slightly older frontmatter
set (it carries `session-id:`, which current breadcrumbs don't). Nothing
writes there anymore and it appears in no schema. If the window reaches back
far enough to overlap it, either read those files too — they parse the same
way — or say plainly in the output that history before the item's earliest
`log/` entry was not covered. Do **not** silently report a long window as
complete while skipping it; the whole point of a long-window run is that the
user isn't going to go looking themselves.

**Cross-item run:** for every date in the window, walk every item's
`items/**/log/` (including `archived/`, since an item's activity during the
window doesn't care where it sits today) and collect the same file types
across all of them, plus:

- **Instant `log-<timestamp>` items** — activity with no existing item to
  attach to is now an item in its own right, born directly into
  `items/archived/` with no `log/` of its own (see `items/CLAUDE.md`'s
  "Recording out-of-band work"). Recognize these among `items/archived/**` by
  **both** signals together (avoids misreading a legitimately-titled item
  that happens to start with "log-"): `made == completed` **and** slug
  matching `^log-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}(-[0-9]+)?$`.
  Filter by their `made`/`completed` date falling in the window; their body
  note (and optional `Commit:` line) is the entry — these are the only
  entries that stay ungrouped by slug (see below), same role `jots/` used to
  play before it retired.
- **Git history — the user's own commits only, across every repo.**
  Breadcrumbs and logged notes are the *intent* layer but they're lossy: the
  user sometimes commits without logging it, so git is a primary source, not
  just supporting detail. The catch is that the repos are **shared** —
  `~/work/repos/<repo>` and every worktree's `main` mix several admins'
  commits, and a worktree `git log` shows the *whole* shared history. So
  **always filter by author**:

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

Group everything by **slug** (trivial for the item-scoped run — everything's
already one slug). Then **cross-reference the two layers**:

- A commit (by the user) **with** a matching `log/` entry → attribute
  to that item.
- A commit (by the user) **with no** matching `log/` entry → still include it
  (it's real work the user forgot to capture); place it by slug if the commit
  touches that item's files/area, else in the ad-hoc bucket (cross-item runs
  only). These capture gaps are exactly why git is read, not skipped.
- A `log/` entry with **no** commit → still counts (planning, non-code
  work, investigations).

For cross-item runs, instant `log-<timestamp>` items and the user's commits
not tied to any item collect under an "ad-hoc" bucket. **When attribution is
genuinely ambiguous, ask the user rather than guessing.**

### 4. Synthesize the recap

Write headline-style, outcome-focused prose — what moved, not a transcript.

**Item-scoped run:** a single narrative for that item — what progressed
(from `log/` entries + commits), with a light commit/files tally where
useful. No "By item"/"Ad-hoc" split; there's only one item.

**Cross-item run**, sections:

- **Summary** — 3–6 bullets: the window's headline accomplishments across all
  items.
- **By item** — one subsection per slug that saw activity: what progressed
  (from that item's `log/` entries + commits), with a light commit/files
  tally where useful. Link the item (`[[<slug>]]`).
- **Ad-hoc** — instant `log-<timestamp>` items and the user's stray
  (item-less) commits, as a short list.

Keep it backward-looking. Outstanding / blocked / coming-due is the dashboard's
job — don't duplicate it here.

### 5. Write the retrospective file

**Cross-item runs only.** Save to `~/work/data/retrospectives/` (a flat
directory — no dated subfolders), named by the window's **end** date and its
span:

- `~/work/data/retrospectives/<end-date>.retrospective-<N>d.md`

where `<N>d` is the span from step 1. Overwrite if a file already exists for the
same end-date + span (regeneration is safe). Frontmatter: `type: retrospective`,
`span: <N>d`, `start`, `end`, `generated` (ISO) — there is no `window`/class
field; span plus start/end is the single source of truth. Then the
`# Retrospective — <label> (<start> → <end>)` heading and the sections from
step 4. See [[retrospectives/CLAUDE|retrospectives/CLAUDE.md]] for the
directory's schema.

**Item-scoped runs skip this step entirely** — the recap is printed (step 8)
and not persisted, since it's cheaply re-derivable from that item's own
`log/` at any time; see the note in `retrospectives/CLAUDE.md` for why this
directory only holds cross-item roll-ups.

### 6. Propose a refreshed Current state

For each item with *material* progress in the window — material = it has
`log/` entries or the user's own commits in the range — draft, but do not yet
write, a refreshed `## Current state` paragraph for the item's front door,
in the curated voice the front door expects.

Present the draft and ask the user to confirm per item (write / edit / skip).
**Write only on confirmation** — judging significance and framing is the whole
reason this is an LLM skill and not the dumb hook, but the user owns the commit.

An item-scoped run only ever has one item to consider here — itself.

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

Print the recap to stdout, plus the saved file path for cross-item runs
(item-scoped runs have no file to point at — the recap itself is the output).

## Notes

- **Local only — no Slack, no calendar.** The retrospective recaps captured
  work. Things never captured (a hallway ask you didn't `workitem log`) won't
  appear; that's the accepted trade of intentional curation.
- **Propose, don't autonomously mutate.** Step 6 never writes into an item
  without per-item confirmation.
- **Read-derived.** Source of truth is each item's `log/` frontmatter (plus
  instant `log-<timestamp>` items' front-door bodies) and git history; the
  retrospective ranks and frames, it doesn't invent.
- **Re-runs are safe.** The retrospective file regenerates for cross-item runs;
  the `## Current state` write-back happens only on confirmation.
- **Past windows are immutable.** Regenerating the current window is fine;
  treat regenerating an *old* window as fix-outright-errors-only — a
  retrospective reflects what was captured at the time.
- **Not for closing out a finished item.** This skill answers "what happened
  in this window" — even scoped to one item, it's still a time-window recap,
  printed and not persisted. Use `complete-item` instead when the item itself
  is done: it drafts a permanent `## Retrospective` section and archives the
  item, a one-time lifecycle event rather than a window query.
