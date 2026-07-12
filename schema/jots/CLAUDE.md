# Jots (per-directory schema)

`jots/` holds **itemless, ad-hoc activity** — dated one-liners for things
that happened with no work item to attach to: a hallway debug, "Kate
flagged X and I sorted it," a quick fix with nothing else to say about it.
It is deliberately narrow. A jot tagged to a work item (`[[<slug>]]`)
**does not live here** — it belongs to that item's own record instead; see
`items/CLAUDE.md`'s `log/` section. This directory only ever holds the
untagged remainder.

(This directory was formerly `diary/` and held session breadcrumbs, tagged
jots, and a legacy session-capture type as well. Those all moved into each
item's own `log/`, or in the case of tagged jots specifically, were split
out by tag; see the `item-centric-session-history` item for the migration.
`jots/` now holds only what's left: activity with no item to attach to.)

Vault-wide conventions live in [[CLAUDE]]. This file specifies how those
apply to `jots/`.

## Directory layout

```
~/work/data/jots/
└── YYYY/
    └── MM/
        └── DD/
            └── <YYYY-MM-DD>.log.md   # ad-hoc jot log (one per day)
```

- One folder per day. Empty days have no folder — the tree only contains
  days that produced at least one untagged jot.
- Years and months are zero-padded (`2026/04/29`, not `2026/4/29`).
- Each day folder holds exactly one file: the day's jot log.

## The jot log

**Filename:** `<YYYY-MM-DD>.log.md` (one per day)

An append-only stream of timestamped one-liners recording ad-hoc,
**itemless** activity. Written by `workjot create` when no item is given at
the attribution prompt. Where an item's own `log/` says "this happened to
item X," a jot here just says "this happened," full stop — there's no item
whose story it belongs to.

When the work involved a commit, the entry carries the commit's
`<repo>@<branch> <hash> "<subject>"` after confirming it, same as an
item-attributed jot would.

**Frontmatter:** `type: jot-log`, `date: <YYYY-MM-DD>` — set once on the
day's first entry.

**Body:** a `# Jot log — <date>` heading, then bullet lines of the form
`- HH:MM — <note> (<repo>@<branch> <hash> "<subject>")`, where the commit
clause is optional. No `[[<slug>]]` tag ever appears here — a jot that
carries one is, by definition, not itemless, and lands in that item's
`log/` instead (see `items/CLAUDE.md`).

## Lifecycle and integrity

Jots are **append-only by default**, with two narrow, tooled exceptions —
both via `workjot`, never by hand-editing the file directly:

- **`workjot edit`** — amend an existing entry, most commonly to add
  follow-up context that wasn't known at the time ("turned out this was
  actually X"). This is a deliberate extension of the "past entries don't
  get rewritten" rule that governs the rest of the tree — jots specifically
  may accrue follow-up, not just error fixes.
- **`workjot delete`** — confirm-gated removal, for an entry created by
  outright mistake. Always prompts with a warning before deleting; there is
  no silent delete path.

Outside of those two actions, past-day entries are immutable. There is no
`archived/` subdirectory — jots don't transition between active and
archived states; they simply accumulate.

## How Claude should engage with jots

### Reading

- **"What ad-hoc/itemless things happened on day X?"** — read
  `jots/YYYY/MM/DD/<date>.log.md`.
- **"What happened with item X (on day Y, last week, ...)?"** — this
  directory is the wrong place to look. Read that item's own `log/`
  instead (see `items/CLAUDE.md`); a jot attributed to an item never
  appears here.
- A cross-cutting window question ("what happened last week," with no item
  filter) merges this directory with every item's `log/` — that's the
  `retrospective` skill's job, not something to do by hand.

### Writing

- **Don't author files here directly.** Use `workjot create` (prompts for
  the note and, optionally, an item to attribute it to — leave that prompt
  blank for a genuinely itemless jot), `workjot edit`, or `workjot delete`.
  Tagged jots never land here regardless of how `workjot` is invoked — the
  tool routes them into the item's `log/` itself.
- `workjot` handles file naming, frontmatter, and the day-folder creation;
  there's no reason to create a `YYYY/MM/DD/` folder or the day's log file
  by hand.

### Cross-references

Use full vault-relative wikilinks pointing at a specific day's log:

- `[[jots/2026/04/29/2026-04-29.log]]`

The `jots/` directory itself isn't a wikilink target, and neither is a day
folder — link the specific log file inside it.
