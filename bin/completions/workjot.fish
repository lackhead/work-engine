# Completion for `workjot` — completes the -r/--repo value with canonical clones.
# Canonical location: ~/work/engine/bin/completions/workjot.fish (the work-engine repo);
# autoloaded via fish_complete_path → ~/work/engine/bin/completions.

function __workjot_repos
    set -l repos $HOME/work/repos
    test -d $repos; or return
    for p in $repos/*
        test -e $p/.git; and basename $p
    end
end

complete -c workjot -f
complete -c workjot -s v -l verbose -d 'Show what is happening as it happens'
complete -c workjot -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c workjot -s r -l repo    -x -a '(__workjot_repos)' -d 'repo for git facts'
complete -c workjot -s h -l help    -d 'Show help'
