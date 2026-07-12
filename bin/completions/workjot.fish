# Completions for `workjot` (create/list/edit/delete subcommands).
# Canonical location: ~/work/engine/bin/completions/workjot.fish (the work-engine repo);
# autoloaded via fish_complete_path → ~/work/engine/bin/completions.

function __workjot_root
    echo $HOME/work
end

function __workjot_repos
    set -l repos (__workjot_root)/repos
    test -d $repos; or return
    for p in $repos/*
        test -e $p/.git; and basename $p
    end
end

# Item slugs eligible for -i/--item: any zone (top, backlog, archived) — a
# jot can attribute to an item wherever it currently sits.
function __workjot_item_slugs
    set -l items (__workjot_root)/data/items
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

complete -c workjot -f

complete -c workjot -s v -l verbose -d 'Show what is happening as it happens'
complete -c workjot -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c workjot -s h -l help    -d 'Show help'

complete -c workjot -n __fish_use_subcommand -a create -d 'Record a new jot'
complete -c workjot -n __fish_use_subcommand -a list   -d 'Show jots'
complete -c workjot -n __fish_use_subcommand -a edit   -d 'Add follow-up to an existing jot'
complete -c workjot -n __fish_use_subcommand -a delete -d 'Delete a jot (confirm-gated)'

# create [-r|--repo <repo>] [-i|--item <slug>]
complete -c workjot -n '__fish_seen_subcommand_from create' -s r -l repo \
    -x -a '(__workjot_repos)' -d 'repo for git facts'
complete -c workjot -n '__fish_seen_subcommand_from create' -s i -l item \
    -x -a '(__workjot_item_slugs)' -d 'attribute to item'

# list [-i|--item <slug>] [--on <date>|--since <date>]
complete -c workjot -n '__fish_seen_subcommand_from list' -s i -l item \
    -x -a '(__workjot_item_slugs)' -d 'scope to item'
complete -c workjot -n '__fish_seen_subcommand_from list' -l on    -x -d 'YYYY-MM-DD'
complete -c workjot -n '__fish_seen_subcommand_from list' -l since -x -d 'YYYY-MM-DD'

# edit [-i|--item <slug>] [--on <date>]
complete -c workjot -n '__fish_seen_subcommand_from edit' -s i -l item \
    -x -a '(__workjot_item_slugs)' -d 'scope to item'
complete -c workjot -n '__fish_seen_subcommand_from edit' -l on -x -d 'YYYY-MM-DD'

# delete [-i|--item <slug>] [--on <date>]
complete -c workjot -n '__fish_seen_subcommand_from delete' -s i -l item \
    -x -a '(__workjot_item_slugs)' -d 'scope to item'
complete -c workjot -n '__fish_seen_subcommand_from delete' -l on -x -d 'YYYY-MM-DD'
