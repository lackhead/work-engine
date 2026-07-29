# Completions for the `worktree` helper (slugs, repos, branches).
# Canonical location: ~/work/engine/bin/completions/worktree.fish (the work-engine repo).
# Symlinked into ~/.config/fish/completions/ so fish autoloads it.

function __worktree_root
    if set -q WORK_ROOT; and test -n "$WORK_ROOT"
        echo $WORK_ROOT
    else
        echo $HOME/work
    end
end

# Nth positional (1-based) after the subcommand, skipping options.
function __worktree_arg_n
    set -l want $argv[1]
    set -l toks (commandline -opc)
    test (count $toks) -ge 3; or return
    set -l n 0
    for tok in $toks[3..-1]
        string match -q -- '-*' $tok; and continue
        set n (math $n + 1)
        if test $n -eq $want
            echo $tok
            return
        end
    end
end

# How many positionals are already completed after the subcommand.
function __worktree_nargs
    set -l toks (commandline -opc)
    set -l n 0
    if test (count $toks) -ge 3
        for tok in $toks[3..-1]
            string match -q -- '-*' $tok; or set n (math $n + 1)
        end
    end
    echo $n
end

# Item slugs (for `add`): active (top-level) items only — not backlog/archived.
function __worktree_item_slugs
    set -l items (__worktree_root)/data/items
    test -d $items; or return
    for zone in $items
        test -d $zone; or continue
        for p in $zone/*
            set -l b (basename $p)
            contains -- $b CLAUDE.md backlog archived; and continue
            if test -d $p
                echo $b
            else
                echo (string replace -r '\.md$' '' $b)
            end
        end
    end
end

# Slugs that already have a worktree (for `rm` / `list`).
function __worktree_live_slugs
    set -l wt (__worktree_root)/worktrees
    test -d $wt; or return
    for p in $wt/*
        test -d $p; and basename $p
    end
end

# Canonical clones under repos/ (only these qualify for branch lookup).
function __worktree_repos
    set -l repos (__worktree_root)/repos
    test -d $repos; or return
    for p in $repos/*
        test -e $p/.git; and basename $p
    end
end

# Repos already checked out under a given slug (for `rm <slug> <repo>`).
function __worktree_live_repos
    set -l d (__worktree_root)/worktrees/(__worktree_arg_n 1)
    test -d $d; or return
    for p in $d/*
        test -d $p; and basename $p
    end
end

# Branches of the repo named as `add`'s 2nd positional (local + remote).
function __worktree_branches
    set -l d (__worktree_root)/repos/(__worktree_arg_n 2)
    test -d $d; or return
    begin
        git -C $d for-each-ref --format='%(refname:short)' refs/heads
        git -C $d for-each-ref --format='%(refname:lstrip=3)' refs/remotes
    end 2>/dev/null | string match -rv '^HEAD$' | sort -u
end

# --- rules ----------------------------------------------------------------
complete -c worktree -f   # no filename completion by default

complete -c worktree -s v -l verbose -d 'Show what is happening as it happens'
complete -c worktree -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c worktree -s h -l help    -d 'Show help'

complete -c worktree -n __fish_use_subcommand -a add            -d 'Create a worktree'
complete -c worktree -n __fish_use_subcommand -a rm             -d 'Remove worktree(s)'
complete -c worktree -n __fish_use_subcommand -a mv             -d 'Relocate worktree(s) to a new slug'
complete -c worktree -n __fish_use_subcommand -a list           -d 'List worktrees'
complete -c worktree -n __fish_use_subcommand -a refresh        -d 'Fast-forward canonical clones'
complete -c worktree -n __fish_use_subcommand -a prune-branches -d 'Find/delete orphaned branches'

# add <slug> <repo> [branch] [--base ref]
complete -c worktree -n '__fish_seen_subcommand_from add; and test (__worktree_nargs) -eq 0' -a '(__worktree_item_slugs)' -d item
complete -c worktree -n '__fish_seen_subcommand_from add; and test (__worktree_nargs) -eq 1' -a '(__worktree_repos)'      -d repo
complete -c worktree -n '__fish_seen_subcommand_from add; and test (__worktree_nargs) -eq 2' -a '(__worktree_branches)'   -d branch
complete -c worktree -n '__fish_seen_subcommand_from add' -l base -r -d 'Base ref for a new branch'

# rm <slug> [repo] [--delete-branch]
complete -c worktree -n '__fish_seen_subcommand_from rm remove; and test (__worktree_nargs) -eq 0' -a '(__worktree_live_slugs)' -d worktree
complete -c worktree -n '__fish_seen_subcommand_from rm remove; and test (__worktree_nargs) -eq 1' -a '(__worktree_live_repos)' -d repo
complete -c worktree -n '__fish_seen_subcommand_from rm remove' -l delete-branch -d 'Also delete the branch if merged'

# mv <old-slug> <new-slug> -- new-slug is a name being chosen, not completed
complete -c worktree -n '__fish_seen_subcommand_from mv rename; and test (__worktree_nargs) -eq 0' -a '(__worktree_live_slugs)' -d worktree

# list [slug]
complete -c worktree -n '__fish_seen_subcommand_from list ls; and test (__worktree_nargs) -eq 0' -a '(__worktree_live_slugs)' -d worktree

# refresh [repo] [--if-stale]
complete -c worktree -n '__fish_seen_subcommand_from refresh sync; and test (__worktree_nargs) -eq 0' -a '(__worktree_repos)' -d clone
complete -c worktree -n '__fish_seen_subcommand_from refresh sync' -l if-stale -d 'Skip clones fetched <24h ago'

# prune-branches [repo] [--apply]
complete -c worktree -n '__fish_seen_subcommand_from prune-branches; and test (__worktree_nargs) -eq 0' -a '(__worktree_repos)' -d clone
complete -c worktree -n '__fish_seen_subcommand_from prune-branches' -l apply -d 'Delete the branches found safe to delete'
