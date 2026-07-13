# Retrospectives (per-directory schema)

Retrospectives are the **consolidations** of the work system: backward-looking
roll-ups of what got done over a window — cross-item, or scoped to a single
item — generated on demand by the
[[../.claude/skills/retrospective/SKILL|retrospective]] skill. They are
deliberately kept **separate from the raw activity layer** — every item's own
`log/` (session breadcrumbs + logged notes), including instant `log-<timestamp>`
items born straight to `completed` for activity with no existing item to
attach to — this directory is the *consolidation* of that activity. Keeping
them apart makes the set of retrospectives easy to peruse on its own and keeps
the raw work-record distinct from the summaries derived from it (principle #4
in [[CLAUDE]]).

Vault-wide conventions live in [[CLAUDE]]. This file specifies how those apply
to retrospectives.

## Directory layout

```
~/work/data/retrospectives/
├── CLAUDE.md
└── <YYYY-MM-DD>.retrospective-<N>d.md   # one per generated roll-up
```

- **Flat directory, no dated subfolders.** A flat list sorts chronologically by
  filename, which is the whole point — the set is meant to be skimmed at a
  glance. (Contrast an item's `log/`, which is date-per-file.)
- **No `archived/`.** Like the raw activity layer, retrospectives accrete;
  they don't transition between active and archived. Unlike the raw layer,
  they are *regenerable* (see Lifecycle).

## Filename

`<YYYY-MM-DD>.retrospective-<N>d.md`

- `<YYYY-MM-DD>` — the window's **end** date (when the retrospective was taken).
- `<N>d` — the **duration** the roll-up looked back, in whole days (the
  `span`). Always days, never weeks/months/quarters — one unit, no conversion
  ambiguity, and spans compare numerically (which the long-window read strategy
  relies on). `<N>` is `ceil((end − start) / 24h)`, floored at `1`, so any
  partial day rounds up: an 8-hour end-of-day recap is `1d`, a 2.5-day span is
  `3d`, a trailing week is `7d`. A calendar "this week" run mid-week reflects its
  *actual* elapsed coverage (e.g. Mon→Fri ≈ `5d`), not a nominal 7 — duration is
  honest about what was read, which is why it's preferred over a window-class
  label.

Examples: `2026-06-19.retrospective-7d.md`, `2026-06-17.retrospective-8d.md`.

This directory only ever holds **cross-item** roll-ups. An item-scoped run
(`retrospective nagios last week`) is printed, not saved here — it reads
straight from `nagios`'s own `log/`, which is already the cheap, reusable
source; there's no long-window composition problem to solve by persisting
it the way a cross-item roll-up has.

## Frontmatter

| Field | Notes |
|-------|-------|
| `type` | Always `retrospective` |
| `span` | The duration looked back, `<N>d` — matches the filename suffix |
| `start` | Window start (`YYYY-MM-DD`, or ISO 8601 if a time matters) |
| `end` | Window end — the date in the filename |
| `generated` | ISO 8601 timestamp of when the roll-up was produced |

There is **no `window`/class field** (`day`/`week`/`month`/…). The span plus the
start/end dates are the single source of truth for what the retrospective
covers; a coarse class would be a second, looser encoding of the same thing.

## Body

Headline-style, outcome-focused prose — what moved over the window, not a
transcript. Sections, per the retrospective skill:

- `# Retrospective — <label> (<start> → <end>)` heading
- `## Summary` — the window's headline accomplishments
- `## By item` — one subsection per slug that saw activity, item-linked
- `## Ad-hoc` — instant `log-<timestamp>` items (activity with no existing
  item to attach to) and stray (item-less) commits

The retrospective is **read-derived and local** — it ranks and frames what
items' `log/` entries and the user's own git history already captured; it
doesn't invent state or reach outside the tree (no Slack, no calendar).

## Lifecycle and integrity

- **Regenerable.** Re-running the skill for the same window (same end date +
  same span) overwrites that file — regeneration is safe for the current window.
  Treat re-generating a *past* window as the same "fix outright errors only"
  rule that governs an item's `log/`: a retrospective reflects what was
  captured at the time.
- **Collisions only on same-date-same-span.** Two roll-ups taken the same day
  over different look-backs get distinct filenames (`…-5d` vs `…-7d`) and coexist.
- **Nothing is deleted on archive** — there is no archive step; the directory
  just accumulates.

## Cross-references

Link a retrospective by its path-qualified wikilink (the directory is flat, so
the basename is unique, but the path reads clearly):

- `[[retrospectives/2026-06-19.retrospective-7d]]`

The `~/work/data/index.md` front page carries a single auto-maintained pointer to the
most recent retrospective under its `## Latest retrospective` section; that
pointer is the retrospective skill's to maintain (the `dashboard` preserves the
section). The directory itself isn't a wikilink target — link a specific file.
