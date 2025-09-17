#!/bin/env fish

function github_token_load \
    --description "(optionally) Load GITHUB_TOKEN into the environment using ghtkn"

    if status --is-interactive
        $GUM_BIN confirm "Load GITHUB_TOKEN with ghtkn?" \
            --default=false --timeout=10s \
            && set -gx GITHUB_TOKEN (ghtkn get)
    else
        printf_info "in non-interactive shell, skipping ghtkn prompt"
    end
end
