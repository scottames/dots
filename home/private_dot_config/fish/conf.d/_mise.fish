#!/bin/env fish

if status --is-interactive
    and type -q mise

    mise completion fish | source
    mise activate fish | source
end
