#!/bin/env fish

function pip_upgrade --description "pip: upgrade all outdated packages (current virtualenv)"
  pip_list_outdated

  printf_info "upgrading\n\n"
  pip list --outdated | tail +3 | cut -d ' ' -f 1 | xargs -n1 pip install -U
end
