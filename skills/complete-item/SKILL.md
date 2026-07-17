---
name: complete-item
description: Close out a work item that's genuinely finished — draft a permanent, categorized ## Retrospective section and a final ## Current state from the item's full log/ history, write them directly and print them for review, stamp status: completed, then hand off to `workitem complete` to move the directory. The one item-scoped run whose retrospective is persisted, since the item is leaving circulation for good.
user_invocable: true
---

Close out a single work item for good: draft its permanent closing narrative,
write it, and archive the item. This is a one-time lifecycle
event, not a time-window recap — it's triggered by "this item is done," never
by a date range. That's the whole reason it's a separate skill from
`retrospective`, even though it reads the same kind of sources
(`log/`, worktree commits) that `retrospective`'s item-scoped mode does:
`retrospective` answers "what happened since X," this answers "this item is
finished, close it out."

**Scope.** Use this for substantive completions — anything with enough
history that a closing narrative is worth writing. Two cases skip it
entirely and go straight to `workitem complete`/`workitem cancel` instead
(see `items/CLAUDE.md`'s "Completing an item" / "Archiving"):

- **Trivial or quick items** — `workitem complete <slug>` sets
  `status: completed` and moves the directory directly, no retrospective
  drafted.
- **Cancellations** — abandoned work has no narrative worth drafting.
  `workitem cancel <slug>` sets `status: cancelled` and moves the directory
  directly.

## Arguments

An item slug, or none (infer from the current session's item if it's
unambiguous — e.g. `workon` opened a session scoped to one item — otherwise
ask).

## Steps

### 1. Resolve the item

Locate the item's front door (`items/<slug>/<slug>.md`, checking top-level
then `backlog/` — never `archived/`, since that's already closed). If the
slug is ambiguous or missing, ask.

### 2. Gather its full lifetime

Read the same sources `retrospective`'s item-scoped run reads — session
breadcrumbs and logged notes in `items/<slug>/log/`, plus the user's own
commits (author-filtered exactly as documented in
`retrospective`'s SKILL.md — see that file for the filtering rule, not
repeated here) across every repo the item has a worktree for — but windowed
from the item's `made:` date through today, not a parsed window phrase. This
is the item's whole life, not a slice of it.

### 3. Draft the closing content

Two pieces, both drafted but not yet written:

- **`## Retrospective`** — a permanent, categorized closing narrative. Shape:
  an italicized meta line (`*<start> → <end> · N sessions · ~M commits*`),
  then two to six bullets grouped by theme (not a chronological transcript —
  what mattered, grouped by what it was), and an optional closing
  *Process note* for anything worth remembering next time (a process
  hiccup, a lesson, a decision that mattered). Write it once; it's never
  revisited after this.
- **Finalized `## Current state`** — replace the existing paragraph with a
  `**Complete.**` (or `**Cancelled.**`, if this run is closing out an
  abandoned item with a narrative worth keeping) opening, then a short
  summary paragraph — the same altitude as the rest of `Current state`'s
  living-narrative voice, just now final.
- **Drop `## What's next`**, if the item has one — nothing is next once an
  item is done.

### 4. Write

No confirm-before-writing gate here — unlike `retrospective`'s per-item
`## Current state` proposals, write the draft straight to the file:

- Insert `## Retrospective` directly after `## Current state` (before
  `## Item files`, if present) — see the placement example in
  `items/CLAUDE.md`.
- Replace `## Current state` with the finalized paragraph; remove
  `## What's next` if it was there.
- Set `status: completed` (or `cancelled`) and stamp `completed:` with
  today's date directly in the frontmatter.

### 5. Hand off to archive

Run `workitem complete <slug>` (or `workitem cancel <slug>` if step 4 closed
this out as cancelled) — status is already set from step 4, so this just
re-confirms it, stamps `completed:`, and moves the directory; see
`items/CLAUDE.md`'s "Archiving".

### 6. Print

Print the `## Retrospective` and finalized `## Current state` content that
was just written, plus the archive result (destination path, worktree(s)
removed if any) — the user reviews what actually landed and can amend the
file by hand afterward if anything needs a correction.

## Notes

- **Persists by exception.** Every other item-scoped `retrospective` run is
  print-only, never saved — this is the one case a closing narrative is
  written permanently, directly into the item's own front door, because the
  item is leaving circulation and this is its one lasting home for that
  story.
- **Write, then let review happen after.** No confirm-before-writing gate,
  unlike `retrospective` — the draft is written and printed in the same
  step; review is a look-back-and-amend, not a look-before-you-write.
- **Not for trivial items or cancellations.** See "Scope" above — both have
  a faster, ceremony-free path through `workitem complete`/`workitem cancel`
  directly.
