---
name: dashboard
description: Answer "where does everything stand and what should I work on now" by reading work items, active reminders, recent session breadcrumbs, and worktree git activity — then regenerate ~/work/data/index.md as a ranked snapshot. Ranking is derived (due-date, status, staleness, optional priority), not hand-set. Read-derived and local — no external sources.
user_invocable: true
---

Generate the curated front-page view of the work system and write it to
`~/work/data/index.md`. The dashboard is **read-derived and local**: it computes
everything from the tree (item frontmatter, reminders), the diary (session
breadcrumbs and jots), and git (worktree activity). It never invents state — the
source of truth is frontmatter and git history, and the dashboard only ranks and
presents it. Capture is manual (the `work*` commands); the dashboard reflects
what's been captured, it doesn't scrape external sources.

`index.md` is a generated file. The dashboard owns most of it but leaves two
regions alone: the hand-owned **Notes / current focus** block and the
**Latest retrospective** pointer (maintained by `retrospective`). See
"Regenerate index.md" for exactly what is and isn't rewritten.

## Arguments

None. Running `dashboard` ranks in-flight work, regenerates `index.md`, and
prints the ranked view + suggested focus.

## Constants

```
STALE_ITEM_DAYS  = 7    # an active item with no breadcrumb/commit in this many days is "at risk"
DUE_SOON_DAYS    = 7    # due/within-this-window counts as an approaching deadline
```

## Steps

### 1. Read the work items

Read `~/work/data/items/**` and parse each item's frontmatter (`title`, `status`,
`due`, `due-type`, `to`, `priority`, `made`). Resolve the front door:
`items/<zone>/<slug>/<slug>.md` for directory items or `items/<zone>/<slug>.md`
for single-file items. Group by attention zone from the directory:

- **In-flight** — `items/` top level (`active` + `blocked`).
- **Backlog** — `items/backlog/` (`proposed` + `deferred`).
- **Archived** — `items/archived/` — ignore unless explicitly asked.

For each item also grab a one-line descriptor: the first non-empty,
non-heading line of the front-door body (trim to ~one clause). This becomes the
item's blurb in `index.md` — derived, so the index doesn't need hand-written
summaries.

### 2. Read active reminders

Read `~/work/data/reminders/*.md` (exclude `archived/`), keep `status: active`. Parse
`created`, the `#` heading (human description), and `related-item` if set. Sort
by `created` ascending (oldest first). Flag any older than `STALE_ITEM_DAYS` as
stale.

### 3. Compute per-item activity (for staleness)

For each in-flight item, find its most recent activity from two sources:

- **Breadcrumbs:** the newest `~/work/data/diary/YYYY/MM/DD/<date>.<slug>.session.NN.md`
  for that slug — read its `end:` timestamp.
- **Worktree commits:** if the item has a worktree, the newest commit date from
  `git -C ~/work/worktrees/<slug>/<repo> log -1 --format=%cI` (across each repo
  the item has a worktree for).

`last-activity = max(newest breadcrumb end, newest commit date)`. An item whose
`last-activity` is more than `STALE_ITEM_DAYS` ago — or that has none — is
**at-risk** (quietly falling behind). Two kinds of item are exempt from the
staleness nudge: **blocked** items (stalled on purpose) and **`priority: low`**
items (deliberately best-effort / when-I-get-around-to-it work — staleness is
expected there, not a problem to flag). Neither is ever marked at-risk.

### 4. Rank the in-flight items

Ranking is **derived**, never hand-set. Sort in-flight items into these
buckets, top to bottom; within a bucket, an explicit `priority:` (high > med >
low, or a smaller number = higher) breaks ties and can lift an item one bucket:

1. **Overdue** — `active`, `due` before today. Most overdue first.
2. **Due soon** — `active`, `due` within `DUE_SOON_DAYS`. Soonest first.
3. **At-risk** — `active`, **not `priority: low`**, no near deadline,
   `last-activity` older than `STALE_ITEM_DAYS`. Most stale first (a nudge to
   re-engage or defer).
4. **Active** — everything else that's `active`, including `priority: low`
   best-effort items (which land here rather than at-risk). Sort by `priority`
   (high → med → unset → low), then `last-activity` (most recent first), so
   low-priority work sinks to the bottom but stays visible.
5. **Blocked** — `blocked` items sink to the bottom, each annotated with what
   it's blocked on (`to:` / body) so it's visible but clearly not actionable.

**Suggested focus** = the top 1–3 *actionable* (non-blocked) items after
ranking, each with a one-line "why now" (overdue, due Friday, untouched 9 days,
explicit high priority).

### 5. Approaching deadlines

Collect, from both items (`due`) and reminders (a date in the heading/body or a
`due`-like field), anything falling within `DUE_SOON_DAYS` (plus anything
overdue). Sort ascending by date. This is a cross-cutting view, separate from
the per-zone listings.

### 6. Regenerate `index.md`

Rewrite `~/work/data/index.md` from the computed data. The dashboard **owns** these
sections and replaces them wholesale each run:

- `## In-flight work items` — ranked per step 4. One bullet per item:
  `- [[<slug>]] — <derived blurb>` followed by inline flags as warranted:
  `· **overdue** (due <date>)`, `· due <date>`, `· **blocked** on <who/what>`,
  `· stale <N>d`, `· to <person>`, `· priority: high`, `· priority: low`. Don't
  put the `· stale <N>d` flag on a `priority: low` item — its staleness is
  exempt by design; show `· priority: low` instead.
- `## Backlog` — `proposed` + `deferred` from `items/backlog/`, each annotated
  with its status.
- `## Approaching deadlines` — step 5, soonest first; omit the section if empty.
- `## Active reminders` — step 2; mark stale ones.
- `## Suggested focus` — the 1–3 picks with their "why now".

The dashboard **does not touch** these regions — copy them through verbatim:

- `## Documents` — static pointer to `[[docs/index]]`.
- `## Latest retrospective` — pointer maintained by `retrospective`; read-only
  here.
- `## Notes / current focus` — hand-owned free-form block. Never rewrite,
  reorder, or "tidy" it.

Preserve the page title, intro paragraph, and the `Schema and conventions:
[[CLAUDE]].` line. Just under the intro, (re)write a single generated-marker
line so it's clear the file is machine-produced:

```
_Generated by the `dashboard` skill — <YYYY-MM-DD HH:MM TZ>. Don't hand-edit
this file or worry that it's stale — it's a snapshot and is expected to lag
between runs. Update the item, then re-run `dashboard`. ("Notes / current focus"
and "Latest retrospective" are not generated.)_
```

If `index.md` is missing a preserved section (e.g. first run after a manual
edit), keep going but warn — don't fabricate a hand-owned block, and don't drop
content you don't recognize: leave any unrecognized section in place rather
than deleting it.

### 7. Print the glance

Print the ranked in-flight list, approaching deadlines, and suggested focus to
stdout so it's readable immediately, then print the `index.md` path.

## Notes

- **Read-derived and local.** No Slack, calendar, or external sources — capture
  is manual via the `work*` commands, and the dashboard only reflects what's in
  the tree, diary, and git. (Filing new reminders/items is `workreminder` /
  `workitem`, not the dashboard.)
- **Ranking is derived, upkeep-free.** No item needs a `priority:`; absence just
  means "rank me from due + status + staleness." `priority:` is an override for
  the rare item that warrants it.
- **Re-runs are safe.** `index.md` is regenerated each run; the hand-owned
  Notes block and the diary pointer are preserved, so nothing hand-authored is
  lost.
- **Reminders/items are surfaced, not mutated** — the dashboard reflects current
  frontmatter; it never changes statuses or files.
