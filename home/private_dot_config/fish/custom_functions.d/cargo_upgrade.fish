#!/bin/env fish

function cargo_upgrade --description "Runs cargo upgrade via 'list | install'"
    if not [ $HAS_CARGO ]
        printf_err "cargo not found"
        return 1
    end

    cargo install --list \
        | grep -v '^ ' \
        | cut -d' ' -f 1 \
        | xargs cargo install
end
