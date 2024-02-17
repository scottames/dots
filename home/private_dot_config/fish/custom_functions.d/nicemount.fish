#!/bin/env fish

function nicemount --description "Displays mounted drive information in a nicely formatted manner"
    begin
        printf_white_bold "DEVICE PATH TYPE FLAGS"
        mount | awk '$2="";1'
    end | column -t
    # http://catonmat.net/blog/another-ten-one-liners-from-commandlingfu-explained
end
