#!/bin/env fish

function pip_list_outdated --description "pip: list outdated packages"
    printf_info "pip outdated packages\n\n"
    pip list --outdated
end
