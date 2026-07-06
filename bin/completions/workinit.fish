# Completion for `workinit` — no positional arguments, just the standard flags.
# Canonical location: ~/work/engine/bin/completions/workinit.fish (the
# work-engine repo); autoloaded via fish_complete_path → ~/work/engine/bin/completions.

complete -c workinit -f
complete -c workinit -s v -l verbose -d 'Show what is happening as it happens'
complete -c workinit -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c workinit -s h -l help    -d 'Show help'
