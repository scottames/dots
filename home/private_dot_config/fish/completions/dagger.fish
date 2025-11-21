#!/bin/env fish

if status --is-interactive
    and type -q dagger

    dagger completion fish | source
end
