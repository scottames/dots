# worktrunk completions for fish
# https://worktrunk.dev/faq/#3-shell-integration
complete --keep-order --exclusive --command wt \
    --arguments \
    "(
        test -n \"\$WORKTRUNK_BIN\"
        or set -l WORKTRUNK_BIN (type -P wt)
        COMPLETE=fish \$WORKTRUNK_BIN -- \
            (commandline --current-process --tokenize --cut-at-cursor) \
            (commandline --current-token)
    )"
