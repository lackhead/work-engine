# Completions for `workitem` (create/list/archive/delete subcommands).
# Canonical location: ~/work/engine/bin/completions/workitem.fish (the work-engine repo);
# autoloaded via fish_complete_path → ~/work/engine/bin/completions.

function __workitem_root
    echo $HOME/work
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

# Item slugs eligible for archiving: top-level + backlog (not already archived).
function __workitem_archivable_slugs
    set -l items (__workitem_root)/data/items
    test -d $items; or return
    for zone in $items $items/backlog
        test -d $zone; or continue
        for p in $zone/*
            test -d $p; or continue
            set -l b (basename $p)
            contains -- $b backlog archived; and continue
            echo $b
        end
    end
end

# Item slugs eligible for deletion: any zone, including archived/ (delete can
# target an already-archived item too, unlike archive).
function __workitem_deletable_slugs
    set -l items (__workitem_root)/data/items
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

complete -c workitem -f

complete -c workitem -s v -l verbose -d 'Show what is happening as it happens'
complete -c workitem -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c workitem -s h -l help    -d 'Show help'

complete -c workitem -n __fish_use_subcommand -a create  -d 'Create a work item'
complete -c workitem -n __fish_use_subcommand -a list    -d 'List work items'
complete -c workitem -n __fish_use_subcommand -a show    -d 'Print a work item front door'
complete -c workitem -n __fish_use_subcommand -a archive -d 'Archive a work item'
complete -c workitem -n __fish_use_subcommand -a delete  -d 'Delete a work item outright'

# create [-q|--quick] [title...]
complete -c workitem -n '__fish_seen_subcommand_from create' -s q -l quick \
    -d 'Skip prompts; active/top-level, tags: [quick]'

# list [--backlog|--archived|--all] [--status <value>]
complete -c workitem -n '__fish_seen_subcommand_from list' -l backlog  -d 'Show items/backlog/'
complete -c workitem -n '__fish_seen_subcommand_from list' -l archived -d 'Show items/archived/'
complete -c workitem -n '__fish_seen_subcommand_from list' -l all      -d 'Show every zone'
complete -c workitem -n '__fish_seen_subcommand_from list' -l status -x \
    -a 'proposed active blocked deferred completed cancelled' -d 'Filter to one status'

# show <slug>
complete -c workitem -n '__fish_seen_subcommand_from show; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_deletable_slugs)' -d item

# archive <slug> [--completed|--cancelled]
complete -c workitem -n '__fish_seen_subcommand_from archive; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_archivable_slugs)' -d item
complete -c workitem -n '__fish_seen_subcommand_from archive' -l completed -d 'Mark completed'
complete -c workitem -n '__fish_seen_subcommand_from archive' -l cancelled -d 'Mark cancelled'

# delete <slug> [--force]
complete -c workitem -n '__fish_seen_subcommand_from delete; and test (__workitem_nargs) -eq 0' \
    -a '(__workitem_deletable_slugs)' -d item
complete -c workitem -n '__fish_seen_subcommand_from delete' -l force -d 'Allow deleting a non-quick item'
