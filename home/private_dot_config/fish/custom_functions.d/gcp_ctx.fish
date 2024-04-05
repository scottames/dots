#!/bin/env fish

function gcp_ctx \
    --description "Set gcloud to the given, or chosen if not provided, project"

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
        set _profile (aws configure list-profiles | gum choose)
    end

    if test (count $argv) -gt 0
        set _name $argv[1]

        if test $_name = clear
            set -l CLEARED_CLOUDSDK_ACTIVE_CONFIG_NAME
            set -e CLOUDSDK_ACTIVE_CONFIG_NAME
            printf_info "CLOUDSDK_ACTIVE_CONFIG_NAME ($CLEARED_CLOUDSDK_ACTIVE_CONFIG_NAME) cleared\n"
            return 0
        end
    else
        if not type -q gum
            printf_err "Missing 'gum'\n"
            return 1
        end

        set _conf (gcloud config configurations list)
        set _name (gum choose $_conf[2..] --header "  $_conf[1]" | string split " ")[1]
    end


    set -gx CLOUDSDK_ACTIVE_CONFIG_NAME $_name
    printf_info "Activated: $CLOUDSDK_ACTIVE_CONFIG_NAME\n"
end
