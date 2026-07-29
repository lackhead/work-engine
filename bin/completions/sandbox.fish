# Completions for `sandbox` (build/up/down/restart/recreate/status/shell/rebuild subcommands).
# Canonical location: ~/work/engine/bin/completions/sandbox.fish (the work-engine repo);
# autoloaded via fish_complete_path → ~/work/engine/bin/completions.

complete -c sandbox -f

complete -c sandbox -s v -l verbose -d 'Show what is happening as it happens'
complete -c sandbox -s d -l debug   -d 'Show diagnostic detail (implies --verbose)'
complete -c sandbox -s h -l help    -d 'Show help'

complete -c sandbox -n __fish_use_subcommand -a build    -d 'Build the image from ~/work/engine/sandbox/'
complete -c sandbox -n __fish_use_subcommand -a up       -d 'Create or start the persistent container (builds if needed)'
complete -c sandbox -n __fish_use_subcommand -a down     -d 'Stop the container (keeps it + named volumes)'
complete -c sandbox -n __fish_use_subcommand -a restart  -d 'Stop then start the container (no rebuild)'
complete -c sandbox -n __fish_use_subcommand -a recreate -d 'Drop and recreate the container on the current image (no rebuild)'
complete -c sandbox -n __fish_use_subcommand -a status   -d 'Show image / container / volume state'
complete -c sandbox -n __fish_use_subcommand -a shell    -d 'Open an interactive fish shell inside the container'
complete -c sandbox -n __fish_use_subcommand -a rebuild  -d 'Rebuild the image (--no-cache) and recreate the container'
