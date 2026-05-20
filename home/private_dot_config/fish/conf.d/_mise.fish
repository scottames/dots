#!/bin/env fish

if status --is-interactive
    and type -q mise

    mise activate fish | source
    mise completion fish | source
end
