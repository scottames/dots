#!/bin/env fish

if status --is-interactive

    # ╭──────────────────────────────────────────────────────────╮
    # │ direnv                                                   │
    # ╰──────────────────────────────────────────────────────────╯
    if type -q direnv
        direnv hook fish | source
    else
        printf_warn "direnv not found\n"
    end

    # ╭──────────────────────────────────────────────────────────╮
    # │ zoxide                                                   │
    # │   https://github.com/ajeetdsouza/zoxide                  │
    # ╰──────────────────────────────────────────────────────────╯
    if type -q zoxide
        zoxide init fish | source
    else
        if status --is-interactive
            printf_warn "zoxide not found\n"
        end
    end

end
