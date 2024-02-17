#!/bin/env fish

function _read_confirm \
    --description "Read confirmation from user interaction. Optionally pass message as flag -m/message"

    set -l options 'm/message='
    argparse -n _read_confirm $options -- $argv
    or return

    set -l message "Do you want to continue? [y/N] "
    if set -q _flag_message
        set message $_flag_message
    end

    while true
        read -l -P $message confirm

        switch $confirm
            case Y y
                return 0
            case '' N n
                return 1
        end
    end
end
