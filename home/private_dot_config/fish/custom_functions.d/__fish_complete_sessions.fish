#!/bin/env fish

function __fish_complete_sessions
    zellij list-sessions --short --no-formatting 2>/dev/null
end
