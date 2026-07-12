# Reminders (per-directory schema)

Reminders are noted items that need follow-up — "this exists, don't
lose it." Each reminder lives as a single markdown file under
`~/work/data/reminders/`. Examples: a question I want to come back to, a
person who said they'd send me something, a half-formed idea worth
revisiting, a thread I want to re-read once it's settled, a config
quirk I noticed but didn't have time to dig into.

Reminders are deliberately lower-overhead than work items. A work item is
something you sit down and work in a dedicated session; a reminder is just a
tracked thing — "this needs follow-up of some kind, even if I don't yet know
what" — that you action or flip without a working session. Most reminders are
frontmatter-only files where the filename itself is the description. If a
reminder grows enough shape that it earns its own session, promote it to a
work item; until then, it stays a reminder.

Reminders are not work items: they're not worked in a session, not
directory-scaffolded, and have no phases or status logs. They're notes with
metadata.

Vault-wide conventions (markdown style, frontmatter rules, linking,
file naming) live in [[CLAUDE]]. This file specifies how those
conventions apply to reminders and what structure each reminder file
carries.

## Lifecycle

A reminder has exactly **two states** — `active` (in circulation) and
**archived** (out of circulation) — and archival happens for one of **two
reasons**: `addressed` or `dismissed`. Unlike work items, status and location
are *not* independent axes here: the state is the whole lifecycle, and the
`status:` frontmatter value carries it — `active` while circulating, and the
archival *reason* (`addressed`/`dismissed`) once archived. There is no
addressed-but-still-circulating limbo: `addressed`/`dismissed` mean the
reminder is archived.

### Status values

The `status:` field is required and takes one of the following
values:

- **`active`** — in circulation; needs follow-up. Default state for any
  newly-created reminder; creating a reminder is itself the act of saying
  "this needs follow-up." There is no `proposed` state for reminders — they're
  inherently lighter-weight than work items, and the act of capturing one is
  the commitment. Active reminders live at the top level of `reminders/`.
- **`addressed`** — archived because the underlying thing was done, resolved,
  or followed up on. The reminder did its job.
- **`dismissed`** — archived because it turned out not to need follow-up after
  all (false alarm, no longer relevant, the question answered itself).
  Distinct from `addressed`: dismissed means "I never followed up and don't
  need to."

`addressed` and `dismissed` are the two **reasons for archival**; both imply
the file has moved to `archived/`. Transitions are conscious decisions —
nothing changes status automatically. When a reminder is addressed or
dismissed, I (or Claude on my behalf, with my approval) set the `status:` and
move the file together (see "Archiving" below).

### Archive

`~/work/data/reminders/archived/` holds reminders no longer in active circulation.
Because state and location are coupled, the lifecycle is simply
`active → archived` and the `status:` value records why:
`active → addressed` or `active → dismissed`. Both the status edit and the
`→ archived/` move are part of the **same** transition, done together — a
reminder doesn't sit at `addressed`/`dismissed` while still at the top level.

The frontmatter status is canonical; the `archived/` location is its
mechanical counterpart and should always agree (top level ⇔ `active`,
`archived/` ⇔ `addressed`/`dismissed`).

Nothing is deleted. Archiving is a deliberate act, not automatic.

## File structure

Each reminder is a single markdown file — no per-reminder
subdirectories. Format:

- YAML frontmatter (specified below).
- A `#` heading matching a description of the reminder (typically
  the human form of the filename's description part).
- Optional body prose: any context that doesn't fit in the filename.
  Most reminders are frontmatter-only — the filename and frontmatter
  carry all the information needed. A body is added only when the
  source thread, decision context, or specifics of "what to do"
  matter and would be lost without notes.

## Frontmatter

Required fields:

| Field | Notes |
|-------|-------|
| `created` | `YYYY-MM-DD` when the reminder was first captured (the date the *reminder* was created, not necessarily the date the underlying item arose — but for reminders surfaced by the daily-summary skill or similar, those typically match). |
| `status` | One of `active`, `addressed`, `dismissed`. New reminders default to `active` (top level); `addressed`/`dismissed` are the two archival reasons and imply the file lives under `archived/`. See "Status values" above. |

Optional fields:

| Field | Notes |
|-------|-------|
| `source` | Where the reminder came from. Common values: `daily-summary` (proposed by the daily-summary skill), `backfill-from-jots` (added retrospectively from a jot), `manual` (added by hand), `slack-thread`, `meeting`. Free-form text — pick a value that lets future-me trace the origin. |
| `related-item` | Wikilink to a work item, e.g. `[[ad-upgrade]]`, when the reminder is tied to or adjacent to a specific work item. Single value, not a list — if a reminder spans several items, that's a sign it's actually a work item of its own. |
| `due` | `YYYY-MM-DD` deadline. Bare date only — no `due-type` (`hard`/`soft`) the way work items have; reminders stay deliberately lower-overhead. Omit when there isn't one. |
| `tags` | Inline list of short kebab-case tags. |

## Naming conventions

- **File names:** `YYYY-MM-DD-<kebab-case-description>.md`. The date
  prefix is the date the reminder was *created* (matching the
  `created:` frontmatter field), not the date the underlying item
  arose. The description is short enough to be meaningful at a
  glance:
  - `2026-04-30-check-on-mikes-pr-progress.md`
  - `2026-04-30-revisit-rocky-firewall-quirk.md`
  - `2026-05-01-ask-lucas-about-q3-staffing.md`
- The date prefix makes the directory naturally chronological when
  sorted, which is what I want when scanning for what I've recently
  flagged.
- **No spaces** in filenames, per the vault-wide convention.

## How Claude should engage with reminders

### Adding a reminder

`workreminder create` is the tool: it creates a single file with `created:`
set to today and `status: active`, prompting for the description (used in
both the filename and the body heading) and, optionally, `-i/--item` to set
`related-item`. It does not prompt for other optional fields unless brought
up. The body is added only when there's context worth capturing — most
reminders are frontmatter-only.

Adding a reminder is the act of saying "this needs follow-up,"
which is why `active` is the default — there is no `proposed` for
reminders.

### Surfacing active reminders

`workreminder list` shows reminders, defaulting to active (top level);
`--archived`/`--all` broadens the scope — mirrors `workitem list`. When
asked about active reminders directly, Claude reads files at
`~/work/data/reminders/*.md` (excluding `archived/`) and filters to
`status: active`. Default sort: by `created:` date ascending (oldest
first), so stale ones surface naturally.

### Setting or changing a due date

`workreminder due <slug> [date]` sets or changes the optional `due:` field;
omitting the date clears it. There is no `due-type` for reminders — see the
frontmatter table above.

### Archiving (addressing or dismissing)

A reminder leaves active circulation by being **addressed** or **dismissed**,
and that is a single coupled transition — set the `status:` and move the file
together:

1. Edit the frontmatter `status:` to `addressed` (followed up / resolved) or
   `dismissed` (no follow-up needed after all).
2. Move the file to `~/work/data/reminders/archived/<name>.md`.

`workreminder archive <slug> [--addressed|--dismissed]` automates this —
prompts for the reason if not given as a flag, sets `status:`, and moves the
file — mirroring `workitem archive --completed/--cancelled`.

Both steps always happen together — don't set `addressed`/`dismissed` while
leaving the file at the top level, and don't move a file to `archived/`
without recording the reason in `status:`. (The only edge case is genuinely
abandoning tracking with no opinion on outcome — prefer `dismissed` for that
rather than inventing a third state.)

The body is preserved as-is; don't rewrite history.

### Deleting a reminder created in error

`workreminder delete <slug>` removes a reminder outright — for one created
by mistake, not for the normal end-of-life path (that's archiving, which
preserves the body). Distinct from archiving the same way `workitem delete`
is distinct from `workitem archive`.

### Promoting a reminder to a work item

If a reminder grows enough shape that it earns its own working session, it
should become a work item. Workflow:

1. Create the work item under `~/work/data/items/<name>.md` (or a directory item)
   with appropriate frontmatter, in the right attention zone.
2. Set the reminder's `status:` to `addressed` (the reminder did its
   job — it surfaced something that became real work) and move it to
   `archived/` — the coupled transition described under "Archiving".
3. Note the relationship in the item's frontmatter via
   `tags: [from-reminder]` or similar if it matters; usually it
   doesn't.

## Cross-references

- **Work items:** `[[<name>]]`.
- **Other reminders:** `[[reminders/<YYYY-MM-DD-name>]]`.
- **Documents:** `[[docs/<name>]]`.
- **Jots:** by full path to a specific file, e.g.
  `[[jots/2026/04/29/2026-04-29.log]]`. Useful for reminders backfilled
  from a jot — that's where the underlying context lives.
- **Repositories:** plain backticked paths, e.g. `~/work/repos/Ansible`.
  Repos are git working trees nested in the vault but conceptually
  separate — reference by path, never wikilink.

## Templates

The two examples below show the range — one frontmatter-only (the
common case), one with a brief body for context that the filename
alone wouldn't capture.

### Example 1: frontmatter only

```markdown
---
created: 2026-04-30
status: active
source: daily-summary
related-item: [[auto-update-backstop]]
---

# Check on first paris auto-update notification
```

### Example 2: with brief body for context

```markdown
---
created: 2026-04-30
status: active
source: backfill-from-jots
tags: [rocky-linux]
---

# Revisit the Rocky firewall quirk from the prototype build

While building the Rocky 9 prototype on 2026-04-29 I noticed
firewalld was rejecting the SSH config push even after the rule
was added — needed an explicit `firewall-cmd --reload` that the
Debian path doesn't require. Worked around it for the demo. Worth
deciding whether the Ansible role should learn to do the reload
on Rocky, or whether this is signal that I'm hand-rolling
something firewalld already does cleanly via a different mechanism.
```
