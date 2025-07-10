#!/bin/env fish

function aws_ctx \
    --description "Set AWS_PROFILE to the given, or chosen if not provided, profile"

    if not type -q gum
        printf_err "Missing 'gum'\n"
        return 1
    end

    set -l _profile ""
    if test (count $argv) -gt 0
        set _profile $argv[1]

        if test $_profile = clear
            set -e AWS_PROFILE
            printf_info "AWS_PROFILE ($AWS_PROFILE) cleared\n"
            return 0
        end
    else
        set _profile (aws configure list-profiles | gum filter)
    end

    set -gx AWS_PROFILE $_profile
    printf_info "Activated: $AWS_PROFILE\n"
end
