# Minimal fish config for the isolated Claude workspace container.
#
# Generic and disposable — the work-system tooling itself lives on the mounted
# engine (~/work/engine/bin), not in here. PATH is set in the image (ENV); this
# just quiets the interactive shell and wires up the work-system command
# completions.

set -g fish_greeting ""

# worktree / workon / work* completions shipped in the engine.
if test -d $HOME/work/engine/bin/completions
    if not contains $HOME/work/engine/bin/completions $fish_complete_path
        set -gx fish_complete_path $HOME/work/engine/bin/completions $fish_complete_path
    end
end
