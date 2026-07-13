# Documents (per-directory schema)

Documents are stand-alone written work that lives in the
work-management system without yet being tied to a work item. Examples:
a proposal for a work item I'm thinking about but haven't committed to
yet, a strategy or analysis piece, a working draft of a memo or
position paper, a "thinking out loud" essay I want to work through
before deciding what to do with it.

The defining trait of a document is that it stands alone — it's
readable on its own, has substantive content (more than a reminder's
filename-as-title shape), and doesn't yet have a home in any
work item. As soon as a document becomes tied to a work item, it moves
into that item's directory and stops being a top-level document.

The broader principle: `~/work/` is where all of my managed work
lives. Code goes in repos and some work happens directly on machines,
but at some point all of it is referred to from a work item,
document, or reminder within `~/work/`. `~/work/data/docs/`
exists so that work artifacts that don't yet fit any other content
type still have a home here rather than scattering across
`~/Documents/` or random places.

Documents are not:

- **Work items** — things you sit down and work in a session. A
  document might *seed* a work item but isn't itself one. (Dated activity
  capture with no topic to organize around is also a work item now — see
  `items/CLAUDE.md`'s "Recording out-of-band work" — not a separate content
  type to contrast against here.)
- **Reminders** — low-overhead "this exists, don't lose it" pointers.
  A document has substantive content; a reminder usually doesn't.
- **Item-internal docs** — those live at `items/<name>/docs/`
  and are part of a specific work item. The directory name is shared
  with this directory by design; the location and the per-directory
  `CLAUDE.md` files differentiate the scopes (just as `archived/`
  recurs across content types without confusing anyone).

Vault-wide conventions (markdown style, frontmatter rules, linking,
file naming) live in [[CLAUDE]]. This file specifies how those
conventions apply to documents.

## Lifecycle

A document has three possible futures, only the first of which keeps
it in `~/work/data/docs/` long-term:

- **Long-lived in `docs/`.** The document is durable reference
  material I keep coming back to — strategy notes, evergreen
  analysis, a position I refer to when discussing a recurring topic.
  It stays in `docs/` indefinitely.
- **Seed for a work item.** The document captures the case for, or
  the early thinking behind, a work item that eventually gets
  committed to. When the item is created, the document
  moves into the item's directory. The document is gone from
  `~/work/data/docs/` at that point — its content lives on as part of
  the item. See "Promoting to a work item" below for typical
  patterns.
- **Archived or deleted.** The document was a working draft, a
  piece of thinking that didn't pan out, or something that's no
  longer useful. Archival (`~/work/data/docs/archived/`) is the default
  — preserving the artifact for later reference. Deletion is
  acceptable for genuine ephemera (rough drafts, false starts,
  anything where preservation has no value). When in doubt, archive.

Unlike work items and reminders, documents do **not** carry a
`status:` field. The document's existence in `docs/` (vs.
`docs/archived/`, vs. having been promoted into a work item) is the
lifecycle signal — frontmatter doesn't need to duplicate it.

### Archive

`~/work/data/docs/archived/` is for documents moved out of active
circulation but worth preserving. Archival is a directory move; no
status edit accompanies it (there's no status field to edit).
Archived documents stay readable but become read-only by convention
— don't edit content under `archived/` except to fix outright errors.

### Promoting to a work item

The promotion from document to work-item content is a manual,
case-by-case process. The schema doesn't try to mechanize it because
no two documents promote the same way. Common patterns:

- A proposal-shaped document usually seeds the new item's
  `plan.md` (the case-and-shape statement).
- A situational/environmental background document often lands at
  `items/<name>/docs/<original-name>.md`.
- A particularly polished and self-contained document occasionally
  seeds the new item's front-door `<name>.md`, but this is rarer —
  front doors are typically shorter and more living than a
  substantial document.

The promotion is a one-time edit: move the file to its new home,
integrate or trim as needed, and update relevant cross-references.
The original file leaves `~/work/data/docs/`.

A document never gets cross-referenced from `~/work/data/docs/` after
promotion. The principle is that a document is a doc *because* no
work item owns it. Once one does, the file moves.

## File structure

Each document is a single markdown file. Format:

- YAML frontmatter (specified below).
- A `#` heading matching the title.
- Body prose. Documents are typically substantial — that's what
  makes them documents. The minimum useful body is a few paragraphs;
  a fuller working draft might span pages.

## Frontmatter

Required fields:

| Field | Notes |
|-------|-------|
| `title` | Human-readable title. Matches the body's `#` heading. |
| `created` | `YYYY-MM-DD` when the document was first captured. |

Optional fields:

| Field | Notes |
|-------|-------|
| `tags` | Inline list of short kebab-case tags for cross-referencing. |

Documents do **not** carry a `related-items` field. The principle
is that any document tied to a work item lives in the item's
directory, not here — physical location captures the relationship
without a frontmatter field. A document that *references* multiple
work items (e.g., a strategy piece commenting across the portfolio)
handles those references with wikilinks in the body, not in
frontmatter.

Documents also do **not** carry an `updated:` field. The file's
mtime answers "when was this last edited" without needing a
hand-maintained metadata field that would inevitably drift out of
date. The deliberate absence keeps the schema honest — every
frontmatter field that exists, exists because it carries information
that mtime can't.

## Naming conventions

- **Filenames:** lowercase-kebab-case description, no date prefix.
  Documents are identified by topic, not by capture date —
  `linux-server-rebuild-proposal.md`, `q3-staffing-thoughts.md`,
  `vendor-evaluation-vast-vs-pure.md`.
- **No spaces** in filenames, per the vault-wide convention.
- The `created:` frontmatter field captures the date the document
  was started; chronological listing happens via that field, not
  via the filename.

## How Claude should engage with documents

### Adding a document

When I ask Claude to add a new document, Claude creates a single
file at `~/work/data/docs/<name>.md` with `created:` set to today and a
substantive first draft of the body if I've described the content.
Claude asks for the title (used in both the filename and the body
heading) and does not prompt for optional fields unless I bring them
up.

Documents should be substantively populated from the start. A
`# Title` followed by `_TODO_` is not a useful document. If there's
not enough content to write meaningfully yet, the right move is
usually a reminder ("come back to this when ready") or a work item
("write the X document"), not an empty document file.

### Surfacing documents

When I ask about active documents, Claude reads files at
`~/work/data/docs/*.md` (excluding `archived/`) and surfaces them.
Default sort: alphabetical by title (since topic, not date, is the
primary key).

### Index style

The docs index at `[[docs/index]]` uses the `[[path|display-text]]`
form for entries — e.g.,
`[[docs/roles-layout-proposal|Roles, OS, and Versioning Strategy]]`.
This is a deliberate departure from the bare `[[path]]` form used in
the root `[[index]]` for work items and reminders. The reason
is that document filenames are topic-shorthand (e.g.,
`roles-layout-proposal`) while document titles are the meaningful
human-readable form ("Roles, OS, and Versioning Strategy") — readers
benefit from seeing the title in the index, not just the filename.
Work items and reminders don't have this gap because their
filenames basically *are* their titles.

### Archiving

To archive a document, move the file to
`~/work/data/docs/archived/<name>.md`. No status edit is needed — the
location is the signal. The body is preserved as-is.

### Deleting

Acceptable for genuine ephemera. Use sparingly; archival is the
default. If unsure, archive.

### Promoting to a work item

When a document seeds a work item being scaffolded, decide which file
inside the new item absorbs it (see "Promoting to a work item"
under Lifecycle for the typical patterns). Move the file into the
item, integrate or trim as needed, and update relevant
cross-references. The original file leaves `~/work/data/docs/`.

## Cross-references

- **Work items:** `[[<name>]]` — the bare item name is the canonical
  link target.
- **Item-internal documents:** `[[<name>/docs/<doc-name>]]`.
  Use when a standalone document needs to reference a doc that lives
  inside a specific work item.
- **Reminders:** `[[reminders/<name>]]`.
- **Other documents:** `[[docs/<name>]]`.
- **Repositories:** plain backticked paths, e.g. `~/work/repos/Ansible`
  or `Ansible/bin/update-hosts`. Repos are git working trees nested in
  the vault but conceptually separate — reference by path, never
  wikilink.

## Templates

The two examples below show the range — one is a substantial
proposal-shaped document (the canonical seed-for-a-project case),
the other is a shorter analytical piece intended to live in `docs/`
long-term.

### Example 1: work-item proposal

```markdown
---
title: Linux server rebuild proposal
created: 2026-05-01
tags: [proposal, infrastructure]
---

# Linux server rebuild proposal

## Why

The fleet of long-lived Linux servers under SCI has accumulated
configuration drift over roughly five years of in-place upgrades and
ad-hoc patching. Three distinct generations of base build coexist;
roles in the Ansible repo carry conditionals to paper over the
differences; new feature work has to verify against all three or
risk silent skew. This is paying off badly.

## What

Rebuild the Linux server fleet from a single current base build,
phased over Q3, with each rebuild driven by Ansible end-to-end
(no hand-tuning surviving the rebuild).

## Open questions

- Which hosts are in scope? (Production-critical SCI services
  vs. dev/scratch hosts.)
- How do we handle hosts with non-standard installed software not
  yet captured in Ansible?
- What's the cutover protocol for stateful services?

## What this isn't

Not a re-architecture. The point is to converge the existing fleet
on a single clean base; the application layout stays the same.
```

### Example 2: standalone analysis

```markdown
---
title: Notes on Canonical archive resilience
created: 2026-05-04
tags: [postmortem-adjacent, infrastructure]
---

# Notes on Canonical archive resilience

The 2026-05-01 Canonical archive DDoS exposed a pattern worth
thinking through: our auto-update path treats apt mirror
availability as transient, which it usually is, but a multi-day
outage of this scale puts hosts in a state where automated
update-or-fail logic isn't useful.

The earlier draft of a "permanent stale-cache mode" was rejected as
too much complexity for an event that's been rare. But the
analytical question is: at what frequency or duration would the
cost-benefit flip? Some napkin math…

[continued]
```
