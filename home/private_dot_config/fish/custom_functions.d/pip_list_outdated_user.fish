#!/bin/env fish

function pip_list_outdated_user --description "pip: list outdated packages"
  printf_info "pip outdated user packages\n\n"
  pip list --outdated --user
end
