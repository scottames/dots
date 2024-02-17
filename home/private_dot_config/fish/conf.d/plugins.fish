#!/bin/env fish

# https://github.com/meaningful-ooo/sponge
if type -q _sponge_remove_from_history
    set -gx sponge_purge_only_on_exit true
end
