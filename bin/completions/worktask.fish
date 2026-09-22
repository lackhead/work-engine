# Completions for `worktask` (create/list/show/log/complete/cancel/delete/due/item/promote subcommands).
# Canonical location: ~/work/engine/bin/completions/worktask.fish (the work-engine repo);
# autoloaded via fish_complete_path → ~/work/engine/bin/completions.

function __worktask_root
    if set -q WORK_ROOT; and test -n "$WORK_ROOT"
        echo $WORK_ROOT
    else
        echo $HOME/work
    end
end

# How many positionals are already completed after the subcommand.
function __worktask_nargs
    set -l toks (commandline -opc)
    set -l n 0
    if test (count $toks) -ge 3
        for tok in $toks[3..-1]
            string match -q -- '-*' $tok; or set n (math $n + 1)
        end
    end
    echo $n
end

# Item slugs for -i/--item: any zone (top, backlog, archived).
function __worktask_item_slugs
    set -l items (__worktask_root)/data/items
    test -d $items; or return
    for zone in $items $items/backlog $items/archived
        test -d $zone; or continue
        for p in $zone/*
            test -d $p; or continue
            set -l b (basename $p)
            contains -- $b backlog archived; and continue
            echo $b
        end
    end
end

# Active task names (top level only), never archived/ -- archived
# tasks are never tab-completed anywhere in this file; reaching one
# (show, delete) means typing the name out by hand. Shared by show, log,
# complete, cancel, delete, due, item, and promote.
function __worktask_active_names
    set -l root (__worktask_root)/data/tasks
    test -d $root; or return
    for p in $root/*.md
        test -e $p; or continue
        basename $p .md
    end
end

complete -c worktask -f

complete -c worktask -s v -l verbose -d 'Show what is happening as it happens'
complete -c worktask -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c worktask -s h -l help    -d 'Show help'

complete -c worktask -n __fish_use_subcommand -a create   -d 'Create a task'
complete -c worktask -n __fish_use_subcommand -a list     -d 'List tasks'
complete -c worktask -n __fish_use_subcommand -a show     -d 'Print a task'
complete -c worktask -n __fish_use_subcommand -a log      -d 'Log a timestamped note on a task'
complete -c worktask -n __fish_use_subcommand -a complete -d 'Complete a task and archive it'
complete -c worktask -n __fish_use_subcommand -a cancel   -d 'Cancel a task and archive it'
complete -c worktask -n __fish_use_subcommand -a delete   -d 'Delete a task outright'
complete -c worktask -n __fish_use_subcommand -a due      -d 'Set or clear a due date'
complete -c worktask -n __fish_use_subcommand -a item     -d 'Set, pick, or clear the related item'
complete -c worktask -n __fish_use_subcommand -a promote  -d 'Promote to a work item'

# create [-i|--item <slug>] [description...] -- description given -> fires
# immediately, no prompts; description omitted -> full interactive flow
complete -c worktask -n '__fish_seen_subcommand_from create' -s i -l item \
    -x -a '(__worktask_item_slugs)' -d 'related work item'

# list [--archived|--all]
complete -c worktask -n '__fish_seen_subcommand_from list' -l archived -d 'Show tasks/archived/'
complete -c worktask -n '__fish_seen_subcommand_from list' -l all      -d 'Show both zones'

# show <name>
complete -c worktask -n '__fish_seen_subcommand_from show; and test (__worktask_nargs) -eq 0' \
    -a '(__worktask_active_names)' -d task

# log <name> [note...] -- no completion attempt for the free-text note,
# achieved by simply not adding a rule beyond nargs 0
complete -c worktask -n '__fish_seen_subcommand_from log; and test (__worktask_nargs) -eq 0' \
    -a '(__worktask_active_names)' -d task

# complete <name>
complete -c worktask -n '__fish_seen_subcommand_from complete; and test (__worktask_nargs) -eq 0' \
    -a '(__worktask_active_names)' -d task

# cancel <name>
complete -c worktask -n '__fish_seen_subcommand_from cancel; and test (__worktask_nargs) -eq 0' \
    -a '(__worktask_active_names)' -d task

# delete <name> [--force]
complete -c worktask -n '__fish_seen_subcommand_from delete; and test (__worktask_nargs) -eq 0' \
    -a '(__worktask_active_names)' -d task
complete -c worktask -n '__fish_seen_subcommand_from delete' -l force \
    -d 'Skip the confirmation prompt (required non-interactively)'

# due <name> [date]
complete -c worktask -n '__fish_seen_subcommand_from due; and test (__worktask_nargs) -eq 0' \
    -a '(__worktask_active_names)' -d task
complete -c worktask -n '__fish_seen_subcommand_from due; and test (__worktask_nargs) -eq 1' \
    -x -d 'YYYY-MM-DD (omit to clear)'

# item <name> [slug|--clear] -- no slug -> interactive picker; --clear removes
complete -c worktask -n '__fish_seen_subcommand_from item; and test (__worktask_nargs) -eq 0' \
    -a '(__worktask_active_names)' -d task
complete -c worktask -n '__fish_seen_subcommand_from item; and test (__worktask_nargs) -eq 1' \
    -x -a '(__worktask_item_slugs)' -d 'related work item'
complete -c worktask -n '__fish_seen_subcommand_from item' -l clear -d 'Remove the related-item association'

# promote <name> [workitem create args...] -- no completion attempt for the
# pass-through args, achieved by simply not adding a rule for nargs >= 1
complete -c worktask -n '__fish_seen_subcommand_from promote; and test (__worktask_nargs) -eq 0' \
    -a '(__worktask_active_names)' -d task
