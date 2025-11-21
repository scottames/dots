#!/bin/env fish

if status --is-interactive

    # ╭──────────────────────────────────────────────────────────╮
    # │ direnv                                                   │
    # ╰──────────────────────────────────────────────────────────╯
    if $HAS_DIRENV
        direnv hook fish | source
    else
        printf_warn "direnv not found\n"
    end

    # ╭──────────────────────────────────────────────────────────╮
    # │ zoxide                                                   │
    # │   https://github.com/ajeetdsouza/zoxide                  │
    # ╰──────────────────────────────────────────────────────────╯
    if $HAS_ZOXIDE
        zoxide init fish | source
    else
        if status --is-interactive
            printf_warn "zoxide not found\n"
        end
    end

end
