#!/bin/env fish

function fonts --description "List installed fonts"
    fc-list | awk '{\$1=\"\"}1' | cut -d: -f1 | sort | uniq
end
