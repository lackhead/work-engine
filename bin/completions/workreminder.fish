# Completion for `workreminder` — completes -i/--item with active item slugs.
# Canonical location: ~/work/engine/bin/completions/workreminder.fish (the work-engine repo);
# autoloaded via fish_complete_path → ~/work/engine/bin/completions.

function __workreminder_item_slugs
    set -l items $HOME/work/data/items
    test -d $items; or return
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

complete -c workreminder -f
complete -c workreminder -s v -l verbose -d 'Show what is happening as it happens'
complete -c workreminder -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c workreminder -s i -l item    -x -a '(__workreminder_item_slugs)' -d 'related work item'
complete -c workreminder -s h -l help    -d 'Show help'
