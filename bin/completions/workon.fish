# Completion for `workon [-c|--create] [-r|--repo <repo>]... <slug>`.
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

# Canonical clones under ~/work/repos/ — used for -r/--repo completion.
function __workon_repos
    set -l repos $HOME/work/repos
    test -d $repos; or return
    for p in $repos/*
        test -d $p; and basename $p
    end
end

complete -c workon -f

# Options.
complete -c workon -s v -l verbose -d 'Show what is happening as it happens'
complete -c workon -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c workon -s h -l help    -d 'Show help'
complete -c workon -s c -l create -d "Don't ask — create <slug> if it doesn't exist"
complete -c workon -l quick -d 'Create a throwaway item and open it now'
complete -c workon -s r -l repo -x -a '(__workon_repos)' \
    -d 'Ensure a worktree for this repo and attach it (repeatable)'

# The only remaining positional: <slug> (non-quick) or the start of [title...]
# (--quick). There's no second positional anymore — a repo is only ever named
# via -r/--repo, never positionally.
complete -c workon -n 'not __fish_seen_argument -l quick; and test (__workon_nargs) -eq 0' \
    -a '(__workon_item_slugs)' -d 'work item'
