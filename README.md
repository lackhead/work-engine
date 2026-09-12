# work-engine

The portable engine for a personal work-management system: schema
(`CLAUDE.md` set), skills, `bin/` tooling, and the isolated-sandbox recipe.
Deployed to `~/work/engine/` (default; override with `$WORK_ROOT`), sibling to
`~/work/data/` — the private, per-instance vault this engine operates on but
never contains. See `schema/CLAUDE.md` for the full design.

Setup instructions (new host, new instance): `docs/work-system-setup.md`.

Overview/demo: `docs/work-system-demo.md` — a terminal `slides` presentation
covering motivation, features, and day-to-day usage. Run it with
`slides docs/work-system-demo.md`.
