#!/bin/env fish

function load_env \
    --description="load .env file, injecting values with op. optionally specify op -t/team"

    set -l _argparse_options 't/team=?'
    argparse -n load_env $_argparse_options -- $argv
    or return


    _arg_req_gt_one $argv || return 1
    set -l team my
    if set -q _flag_team
        set team $_flag_team[1]
    end

    for file in $argv
        if ! test -f $file
            printf_err "Cannot find '$file'\n"
            return 1
        end

        op inject -i $file --account "$team.1password.com" \
            | while read -l line

            set -l arr (string split -m 1 '=' -- $line)
            if test (count $arr) -eq 2
                # Trim quotes + export to shell
                set -gx \
                    $arr[1] \
                    (string trim --chars='\'\"' -- $arr[2])
            else
                printf_warn \
                    "skipping line, expected key=value in '$arr'\n"
            end
        end
    end
end
