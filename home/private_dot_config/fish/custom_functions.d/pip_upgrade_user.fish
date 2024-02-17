#!/bin/env fish

function pip_upgrade_user --description "pip: upgrade all outdated packages (current virtualenv)"
    pip_list_outdated_user
    pip list --outdated --user | tail +3 | cut -d ' ' -f 1 | xargs -n1 pip install -U
end
