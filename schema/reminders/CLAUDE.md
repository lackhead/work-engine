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
reasons**: `completed` or `cancelled`. Unlike work items, status and location
are *not* independent axes here: the state is the whole lifecycle, and the
`status:` frontmatter value carries it — `active` while circulating, and the
archival *reason* (`completed`/`cancelled`) once archived. There is no
completed-but-still-circulating limbo: `completed`/`cancelled` mean the
reminder is archived. These are the same two terminal values work items use
(see `items/CLAUDE.md`), so both content types share one vocabulary for "done."

### Status values

The `status:` field is required and takes one of the following
values:

- **`active`** — in circulation; needs follow-up. Default state for any
  newly-created reminder; creating a reminder is itself the act of saying
  "this needs follow-up." There is no `proposed` state for reminders — they're
  inherently lighter-weight than work items, and the act of capturing one is
  the commitment. Active reminders live at the top level of `reminders/`.
- **`completed`** — archived because the underlying thing was done, resolved,
  or followed up on. The reminder did its job.
- **`cancelled`** — archived because it turned out not to need follow-up after
  all (false alarm, no longer relevant, the question answered itself).
  Distinct from `completed`: cancelled means "I never followed up and don't
  need to."

`completed` and `cancelled` are the two **reasons for archival**; both imply
the file has moved to `archived/`. Transitions are conscious decisions —
nothing changes status automatically. When a reminder is completed or
cancelled, I (or Claude on my behalf, with my approval) set the `status:` and
move the file together (see "Archiving" below).

### Archive

`~/work/data/reminders/archived/` holds reminders no longer in active circulation.
Because state and location are coupled, the lifecycle is simply
`active → archived` and the `status:` value records why:
`active → completed` or `active → cancelled`. Both the status edit and the
`→ archived/` move are part of the **same** transition, done together — a
reminder doesn't sit at `completed`/`cancelled` while still at the top level.

The frontmatter status is canonical; the `archived/` location is its
mechanical counterpart and should always agree (top level ⇔ `active`,
`archived/` ⇔ `completed`/`cancelled`).

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
| `created` | `YYYY-MM-DD` when the reminder was first captured (the date the *reminder* was created, not necessarily the date the underlying item arose). |
| `status` | One of `active`, `completed`, `cancelled`. New reminders default to `active` (top level); `completed`/`cancelled` are the two archival reasons and imply the file lives under `archived/`. See "Status values" above. |

Optional fields:

| Field | Notes |
|-------|-------|
| `source` | Where the reminder came from. Common values: `manual` (added by hand — the default for `workreminder create`), `backfill-from-log` (added retrospectively from a logged item), `slack-thread`, `meeting`. Free-form text — pick a value that lets future-me trace the origin. |
| `related-item` | Wikilink to a work item when the reminder is tied to or adjacent to a specific one. **Quoted** — `related-item: "[[ad-upgrade]]"`; unquoted, `[[ad-upgrade]]` is a nested YAML flow sequence, not a wikilink. Single value, not a list — if a reminder spans several items, that's a sign it's actually a work item of its own. |
| `due` | `YYYY-MM-DD` deadline. Bare date only — no `due-type` (`hard`/`soft`) the way work items have; reminders stay deliberately lower-overhead. Omit when there isn't one. |
| `tags` | Inline list of short kebab-case tags. |

## Naming conventions

- **File names:** `<kebab-case-description>.md` — no date prefix. The
  creation date already lives in the `created:` frontmatter field, so
  putting it in the filename too would just be duplication; dropping it
  also shortens what you type for `show`/`complete`/`cancel`/`delete`/`due`.
- **Auto-derived and capped at 30 characters.** `workreminder create`
  kebab-cases the description into a default slug, truncated at a word
  boundary (never mid-word). In the interactive flow (no description given
  on the command line) it's proffered for you to accept (blank) or override
  right there — the best moment to judge whether the mechanical slug is any
  good, since the full description is already in front of you. Quick add
  (description given positionally) uses the mechanical default outright,
  no confirmation step:
  - `check-on-mikes-pr-progress.md`
  - `revisit-rocky-firewall-quirk.md`
  - `parse-check-the-bootstrap.md` (mechanical, from a much longer
    description)
  - `beta-lm-license-hague.md` (hand-typed at the prompt, replacing a
    mechanical default that would have landed on a less meaningful part
    of a long sentence)
- Chronological order is no longer free from an alphabetical directory
  listing (that was the date prefix's doing) — `workreminder list` sorts
  by `created:` explicitly instead.
- A collision with an existing slug appends `-2`, `-3`, ... rather than
  refusing — expected once slugs are short and possibly truncated, not an
  error.
- **No spaces** in filenames, per the vault-wide convention.

## How Claude should engage with reminders

### Adding a reminder

`workreminder create` has two modes, chosen by whether a description is
given on the command line:

- **Quick add** — `workreminder create <description...>` creates the
  reminder immediately, no prompts at all (a fire-and-forget one-liner).
  `-i/--item <slug>` still works as a flag if given; otherwise the reminder
  has no related item. The slug is auto-generated from the description via
  the same `kebab()` + collision-suffix logic as the interactive path, with
  no confirmation step.
- **Interactive** — `workreminder create` (no description) prompts for the
  description, then whether to attach an existing item — if yes, picks one
  interactively (`fzf`, or a numbered-menu fallback if `fzf` isn't
  installed) across all three item zones, archived entries marked
  `(archived)` — then proffers the default slug to accept or override.

Either way it writes `created:` (today) and `status: active`. It does not
prompt for other optional fields unless brought up. The body is added only
when there's context worth capturing — most reminders are frontmatter-only.

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

### Archiving (completing or cancelling)

`workreminder complete <slug>` / `workreminder cancel <slug>` set the
respective `status:` and move the file to `archived/` in one step, mirroring
`workitem complete`/`workitem cancel` (see "Archive" above for why the two
always happen together). There's no bare "archive, decide later" verb — the
verb itself is the status decision. By hand: edit `status:` to `completed`
or `cancelled`, then move the file to
`~/work/data/reminders/archived/<name>.md` — both parts of the same edit.

For genuinely abandoning tracking with no opinion on outcome, prefer
`cancelled` rather than inventing a third state. The body is preserved as-is
— archiving never rewrites history.

### Deleting a reminder created in error

`workreminder delete <name>` removes a reminder outright — for one created
by mistake, not for the normal end-of-life path (that's completing/cancelling,
which preserves the body). Distinct from archiving the same way `workitem
delete` is distinct from `workitem complete`/`workitem cancel`, and guarded
the same way: it prompts for confirmation, and `--force` is required to delete
non-interactively (so a script or a non-interactive session can't remove a
reminder without saying so explicitly).

### Promoting a reminder to a work item

If a reminder grows enough shape that it earns its own working session, it
should become a work item. `workreminder promote <name> [workitem create
args...]` does this atomically: creates the work item (title defaults to
the reminder's own `#` heading; pass trailing args — a different title,
`-b/--backlog`, `-s/--slug`, etc. — to override what `workitem create`
receives instead), then completes the reminder in the same step (the coupled
transition described under "Archiving"). If item creation fails, the
reminder is left untouched — nothing archives on a failed promotion.
`promote` only applies to active reminders — an already-archived one refuses
with a clear error, since promoting something already closed doesn't make
sense.

There's no automatic cross-link back into the created item — `workitem
create` has no flag to set arbitrary `tags:` at creation, and per this
schema's own guidance, noting the relationship (`tags: [from-reminder]` or
similar) usually doesn't matter enough to be worth doing by hand afterward
either.

## Cross-references

- **Work items:** `[[<name>]]`. Useful for reminders backfilled from a
  logged item — that's where the underlying context lives.
- **Other reminders:** `[[reminders/<name>]]`.
- **Documents:** `[[docs/<name>]]`.
- **Repositories:** plain backticked paths, e.g. `~/work/repos/Ansible`.
  Repos are git working trees nested in the vault but conceptually
  separate — reference by path, never wikilink.

## Template

```markdown
---
created: 2026-04-30
status: active
source: manual
related-item: "[[auto-update-backstop]]"
---

# Check on first paris auto-update notification
```

Most reminders are frontmatter-only, as above; add body prose only when
context would otherwise be lost (see "File structure" above).
