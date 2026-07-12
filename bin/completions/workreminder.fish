# Completions for `workreminder` (create/list/archive/delete/due subcommands).
# Canonical location: ~/work/engine/bin/completions/workreminder.fish (the work-engine repo);
# autoloaded via fish_complete_path → ~/work/engine/bin/completions.

function __workreminder_root
    echo $HOME/work
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

# Active reminder names (top level only) — targets for archive/due.
function __workreminder_active_names
    set -l root (__workreminder_root)/data/reminders
    test -d $root; or return
    for p in $root/*.md
        test -e $p; or continue
        basename $p .md
    end
end

# Any reminder name, active or archived — targets for delete/due.
function __workreminder_all_names
    set -l root (__workreminder_root)/data/reminders
    test -d $root; or return
    for dir in $root $root/archived
        test -d $dir; or continue
        for p in $dir/*.md
            test -e $p; or continue
            basename $p .md
        end
    end
end

complete -c workreminder -f

complete -c workreminder -s v -l verbose -d 'Show what is happening as it happens'
complete -c workreminder -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c workreminder -s h -l help    -d 'Show help'

complete -c workreminder -n __fish_use_subcommand -a create  -d 'Create a reminder'
complete -c workreminder -n __fish_use_subcommand -a list    -d 'List reminders'
complete -c workreminder -n __fish_use_subcommand -a archive -d 'Archive a reminder'
complete -c workreminder -n __fish_use_subcommand -a delete  -d 'Delete a reminder outright'
complete -c workreminder -n __fish_use_subcommand -a due     -d 'Set or clear a due date'

# create [-i|--item <slug>] [description...]
complete -c workreminder -n '__fish_seen_subcommand_from create' -s i -l item \
    -x -a '(__workreminder_item_slugs)' -d 'related work item'

# list [--archived|--all]
complete -c workreminder -n '__fish_seen_subcommand_from list' -l archived -d 'Show reminders/archived/'
complete -c workreminder -n '__fish_seen_subcommand_from list' -l all      -d 'Show both zones'

# archive <name> [--addressed|--dismissed]
complete -c workreminder -n '__fish_seen_subcommand_from archive; and test (__workreminder_nargs) -eq 0' \
    -a '(__workreminder_active_names)' -d reminder
complete -c workreminder -n '__fish_seen_subcommand_from archive' -l addressed -d 'Followed up / resolved'
complete -c workreminder -n '__fish_seen_subcommand_from archive' -l dismissed -d 'No follow-up needed'

# delete <name>
complete -c workreminder -n '__fish_seen_subcommand_from delete; and test (__workreminder_nargs) -eq 0' \
    -a '(__workreminder_all_names)' -d reminder

# due <name> [date]
complete -c workreminder -n '__fish_seen_subcommand_from due; and test (__workreminder_nargs) -eq 0' \
    -a '(__workreminder_all_names)' -d reminder
complete -c workreminder -n '__fish_seen_subcommand_from due; and test (__workreminder_nargs) -eq 1' \
    -x -d 'YYYY-MM-DD (omit to clear)'
