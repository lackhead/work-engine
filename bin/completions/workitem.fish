# Completion for `workitem` (title is free text; just the help flag).
# Canonical location: ~/work/engine/bin/completions/workitem.fish (the work-engine repo);
# autoloaded via fish_complete_path → ~/work/engine/bin/completions.

complete -c workitem -f
complete -c workitem -s v -l verbose -d 'Show what is happening as it happens'
complete -c workitem -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c workitem -s h -l help    -d 'Show help'
