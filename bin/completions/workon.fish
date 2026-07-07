# Completion for `workon <slug> [repo]`.
# Canonical location: ~/work/engine/bin/completions/workon.fish (the work-engine repo).
# Symlinked into ~/.config/fish/completions/ so fish autoloads it.

function __workon_item_slugs
    set -l items $HOME/work/data/items
    test -d $items; or return
    # Active (top-level) items only.
    for p in $items/*
        set -l b (basename $p)
        contains -- $b CLAUDE.md backlog archived; and continue
        if test -d $p
            echo $b
        else
            echo (string replace -r '\.md$' '' $b)
        end
    end
end

# Repos that have a worktree under the slug already on the command line.
function __workon_slug_worktrees
    # Find the first non-option positional after `workon`.
    set -l toks (commandline -opc)
    test (count $toks) -ge 2; or return
    set -l slug ''
    for tok in $toks[2..-1]
        string match -q -- '-*' $tok; and continue
        set slug $tok
        break
    end
    test -n "$slug"; or return
    set -l wt $HOME/work/worktrees/$slug
    test -d $wt; or return
    for p in $wt/*
        test -d $p; and basename $p
    end
end

# Count non-option positional tokens after `workon` (skips flags like -d).
function __workon_nargs
    set -l toks (commandline -opc)
    set -l n 0
    if test (count $toks) -ge 2
        for tok in $toks[2..-1]
            string match -q -- '-*' $tok; or set n (math $n + 1)
        end
    end
    echo $n
end

complete -c workon -f

# Options.
complete -c workon -s v -l verbose -d 'Show what is happening as it happens'
complete -c workon -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c workon -s h -l help    -d 'Show help'

# arg 1 (non-option) = slug, arg 2 = repo.
complete -c workon -n 'test (__workon_nargs) -eq 0' -a '(__workon_item_slugs)' -d 'work item'
complete -c workon -n 'test (__workon_nargs) -eq 1' -a '(__workon_slug_worktrees)' -d worktree
