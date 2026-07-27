# Completions for `workitem` (create/list/show/log/activate/defer/block/
# unblock/complete/cancel/rename/delete subcommands).
# Canonical location: ~/work/engine/bin/completions/workitem.fish (the work-engine repo);
# autoloaded via fish_complete_path → ~/work/engine/bin/completions.

function __workitem_root
    if set -q WORK_ROOT; and test -n "$WORK_ROOT"
        echo $WORK_ROOT
    else
        echo $HOME/work
    end
end

function __workitem_repos
    set -l repos (__workitem_root)/repos
    test -d $repos; or return
    for p in $repos/*
        test -e $p/.git; and basename $p
    end
end

# How many positionals are already completed after the subcommand.
function __workitem_nargs
    set -l toks (commandline -opc)
    set -l n 0
    if test (count $toks) -ge 3
        for tok in $toks[3..-1]
            string match -q -- '-*' $tok; or set n (math $n + 1)
        end
    end
    echo $n
end

# Item slugs in active circulation: top-level + backlog, never archived/.
# Archived items are never tab-completed anywhere in this file -- reaching
# one (show, delete) means typing the slug out by hand. Shared by show, log,
# and delete. NOT complete/cancel -- those only apply to top-level items
# (see __workitem_toplevel_slugs); a backlog item never became active work.
function __workitem_active_slugs
    set -l items (__workitem_root)/data/items
    test -d $items; or return
    for zone in $items $items/backlog
        test -d $zone; or continue
        for p in $zone/*
            test -d $p; or continue
            set -l b (basename $p)
            contains -- $b backlog archived; and continue
            test -f $p/$b.md; and echo $b
        end
    end
end

# Item slugs in items/backlog/ (candidates for `activate`).
function __workitem_backlog_slugs
    set -l zone (__workitem_root)/data/items/backlog
    test -d $zone; or return
    for p in $zone/*
        test -d $p; or continue
        set -l b (basename $p)
        test -f $p/$b.md; and echo $b
    end
end

# Item slugs at top level, any status (candidates for `defer`; both active
# and blocked are valid sources).
function __workitem_toplevel_slugs
    set -l items (__workitem_root)/data/items
    test -d $items; or return
    for p in $items/*
        test -d $p; or continue
        set -l b (basename $p)
        contains -- $b backlog archived; and continue
        test -f $p/$b.md; and echo $b
    end
end

# status: value from a front-door file, or nothing if unreadable.
function __workitem_status_of
    test -f $argv[1]; or return
    string match -rg '^status:\s*(\S+)' < $argv[1] | head -n 1
end

# Top-level slugs whose status is exactly `active` (candidates for `block`).
function __workitem_blockable_slugs
    set -l items (__workitem_root)/data/items
    for b in (__workitem_toplevel_slugs)
        test (__workitem_status_of $items/$b/$b.md) = active; and echo $b
    end
end

# Top-level slugs whose status is exactly `blocked` (candidates for `unblock`).
function __workitem_unblockable_slugs
    set -l items (__workitem_root)/data/items
    for b in (__workitem_toplevel_slugs)
        test (__workitem_status_of $items/$b/$b.md) = blocked; and echo $b
    end
end

complete -c workitem -f

complete -c workitem -s v -l verbose -d 'Show what is happening as it happens'
complete -c workitem -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c workitem -s h -l help    -d 'Show help'

complete -c workitem -n __fish_use_subcommand -a create   -d 'Create a work item'
complete -c workitem -n __fish_use_subcommand -a list     -d 'List work items'
complete -c workitem -n __fish_use_subcommand -a show     -d 'Print a work item front door'
complete -c workitem -n __fish_use_subcommand -a log      -d 'Record a note (existing item, or a new completed item)'
complete -c workitem -n __fish_use_subcommand -a activate -d 'Move a backlog item to top-level (active)'
complete -c workitem -n __fish_use_subcommand -a defer    -d 'Move a top-level item to backlog (deferred)'
complete -c workitem -n __fish_use_subcommand -a block    -d 'Mark a top-level item blocked'
complete -c workitem -n __fish_use_subcommand -a unblock  -d 'Mark a blocked item active'
complete -c workitem -n __fish_use_subcommand -a complete -d 'Complete a work item and archive it'
complete -c workitem -n __fish_use_subcommand -a cancel   -d 'Cancel a work item and archive it'
complete -c workitem -n __fish_use_subcommand -a rename   -d "Rename an item's slug (directory + front door)"
complete -c workitem -n __fish_use_subcommand -a delete   -d 'Delete a work item outright'

# create [-q|--quick] [-b|--backlog] [-s|--slug <slug>] [title...]
complete -c workitem -n '__fish_seen_subcommand_from create' -s q -l quick \
    -d 'Skip prompts, generate a timestamp title/slug'
complete -c workitem -n '__fish_seen_subcommand_from create' -s b -l backlog \
    -d 'Create in items/backlog/ instead, status proposed'
complete -c workitem -n '__fish_seen_subcommand_from create' -s s -l slug \
    -x -d 'Deliberate short slug (skip auto-truncation)'

# list [--backlog|--archived|--all] [--status <value>]
complete -c workitem -n '__fish_seen_subcommand_from list' -l backlog  -d 'Show items/backlog/'
complete -c workitem -n '__fish_seen_subcommand_from list' -l archived -d 'Show items/archived/'
complete -c workitem -n '__fish_seen_subcommand_from list' -l all      -d 'Show every zone'
complete -c workitem -n '__fish_seen_subcommand_from list' -l status -x \
    -a 'proposed active blocked deferred completed cancelled' -d 'Filter to one status'

# show <slug>
complete -c workitem -n '__fish_seen_subcommand_from show; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_active_slugs)' -d item

# log [-r|--repo <repo>] [item-slug] -- never archived, matching wi_log's own restriction
complete -c workitem -n '__fish_seen_subcommand_from log; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_active_slugs)' -d item
complete -c workitem -n '__fish_seen_subcommand_from log' -s r -l repo \
    -x -a '(__workitem_repos)' -d 'repo for git facts'

# activate <slug>
complete -c workitem -n '__fish_seen_subcommand_from activate; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_backlog_slugs)' -d item

# defer <slug>
complete -c workitem -n '__fish_seen_subcommand_from defer; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_toplevel_slugs)' -d item

# block <slug>
complete -c workitem -n '__fish_seen_subcommand_from block; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_blockable_slugs)' -d item

# unblock <slug>
complete -c workitem -n '__fish_seen_subcommand_from unblock; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_unblockable_slugs)' -d item

# complete <slug> -- top-level only; a backlog item is activated or deleted, never completed
complete -c workitem -n '__fish_seen_subcommand_from complete; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_toplevel_slugs)' -d item

# cancel <slug> -- top-level only; a backlog item is activated or deleted, never cancelled
complete -c workitem -n '__fish_seen_subcommand_from cancel; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_toplevel_slugs)' -d item

# rename <slug> <new-slug> -- new-slug is a name being chosen, not completed
complete -c workitem -n '__fish_seen_subcommand_from rename; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_active_slugs)' -d item

# delete <slug> [--force]
complete -c workitem -n '__fish_seen_subcommand_from delete; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_active_slugs)' -d item
complete -c workitem -n '__fish_seen_subcommand_from delete' -l force -d 'Required — confirm the item has nothing worth preserving'
