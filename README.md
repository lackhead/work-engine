# work-engine

The portable engine for a personal work-management system: schema
(`CLAUDE.md` set), skills, `bin/` tooling, and the isolated-sandbox recipe.
Deployed to `~/work/engine/` (default; override with `$WORK_ROOT`), sibling to
`~/work/data/` — the private, per-instance vault this engine operates on but
never contains. See `schema/CLAUDE.md` for the full design.

Deploy on a new machine:

```
git clone <this-repo> ~/work/engine
# add ~/work/engine/bin to PATH, and ~/work/engine/bin/completions to
# fish_complete_path (see dotfiles' shell config for the wiring)
workinit    # materializes ~/work/data and the symlinks back into engine/
```

Edit through a worktree, same as any other repo (`worktree add <slug>
work-engine`), never by hand-editing the deployed `~/work/engine/` copy — pull
the merged result into it with a plain `git pull`.
