# Completions for `workreminder` (create/list/show/complete/cancel/delete/due/promote subcommands).
# Canonical location: ~/work/engine/bin/completions/workreminder.fish (the work-engine repo);
# autoloaded via fish_complete_path → ~/work/engine/bin/completions.

function __workreminder_root
    if set -q WORK_ROOT; and test -n "$WORK_ROOT"
        echo $WORK_ROOT
    else
        echo $HOME/work
    end
end

# How many positionals are already completed after the subcommand.
function __workreminder_nargs
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
function __workreminder_item_slugs
    set -l items (__workreminder_root)/data/items
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

# Active reminder names (top level only), never archived/ -- archived
# reminders are never tab-completed anywhere in this file; reaching one
# (show, delete) means typing the name out by hand. Shared by show, complete,
# cancel, delete, due, and promote.
function __workreminder_active_names
    set -l root (__workreminder_root)/data/reminders
    test -d $root; or return
    for p in $root/*.md
        test -e $p; or continue
        basename $p .md
    end
end

complete -c workreminder -f

complete -c workreminder -s v -l verbose -d 'Show what is happening as it happens'
complete -c workreminder -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c workreminder -s h -l help    -d 'Show help'

complete -c workreminder -n __fish_use_subcommand -a create   -d 'Create a reminder'
complete -c workreminder -n __fish_use_subcommand -a list     -d 'List reminders'
complete -c workreminder -n __fish_use_subcommand -a show     -d 'Print a reminder'
complete -c workreminder -n __fish_use_subcommand -a complete -d 'Complete a reminder and archive it'
complete -c workreminder -n __fish_use_subcommand -a cancel   -d 'Cancel a reminder and archive it'
complete -c workreminder -n __fish_use_subcommand -a delete   -d 'Delete a reminder outright'
complete -c workreminder -n __fish_use_subcommand -a due      -d 'Set or clear a due date'
complete -c workreminder -n __fish_use_subcommand -a promote  -d 'Promote to a work item'

# create [-i|--item <slug>] [description...] -- description given -> fires
# immediately, no prompts; description omitted -> full interactive flow
complete -c workreminder -n '__fish_seen_subcommand_from create' -s i -l item \
    -x -a '(__workreminder_item_slugs)' -d 'related work item'

# list [--archived|--all]
complete -c workreminder -n '__fish_seen_subcommand_from list' -l archived -d 'Show reminders/archived/'
complete -c workreminder -n '__fish_seen_subcommand_from list' -l all      -d 'Show both zones'

# show <name>
complete -c workreminder -n '__fish_seen_subcommand_from show; and test (__workreminder_nargs) -eq 0' \
    -a '(__workreminder_active_names)' -d reminder

# complete <name>
complete -c workreminder -n '__fish_seen_subcommand_from complete; and test (__workreminder_nargs) -eq 0' \
    -a '(__workreminder_active_names)' -d reminder

# cancel <name>
complete -c workreminder -n '__fish_seen_subcommand_from cancel; and test (__workreminder_nargs) -eq 0' \
    -a '(__workreminder_active_names)' -d reminder

# delete <name>
complete -c workreminder -n '__fish_seen_subcommand_from delete; and test (__workreminder_nargs) -eq 0' \
    -a '(__workreminder_active_names)' -d reminder

# due <name> [date]
complete -c workreminder -n '__fish_seen_subcommand_from due; and test (__workreminder_nargs) -eq 0' \
    -a '(__workreminder_active_names)' -d reminder
complete -c workreminder -n '__fish_seen_subcommand_from due; and test (__workreminder_nargs) -eq 1' \
    -x -d 'YYYY-MM-DD (omit to clear)'

# promote <name> [workitem create args...] -- no completion attempt for the
# pass-through args, achieved by simply not adding a rule for nargs >= 1
complete -c workreminder -n '__fish_seen_subcommand_from promote; and test (__workreminder_nargs) -eq 0' \
    -a '(__workreminder_active_names)' -d reminder
