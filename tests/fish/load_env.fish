#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (path dirname (status filename))))
set -l function_dir "$repo_root/home/private_dot_config/fish/custom_functions.d"
set fish_function_path "$function_dir"

function printf_err
    printf '%s' $argv >&2
end

source "$function_dir/load_env.fish"
or exit 1

set -l output_file (mktemp)
function cleanup --on-event fish_exit
    rm -f "$output_file"
end

load_env >"$output_file" 2>&1
set -l result $status
set -l output (string collect <"$output_file")

if test $result -eq 0
    printf 'ASSERTION FAILED: load_env without arguments returns failure\n' >&2
    exit 1
end

if not string match -q '*At least one argument required*' -- "$output"
    printf 'ASSERTION FAILED: load_env reports its argument requirement\nactual: %s\n' "$output" >&2
    exit 1
end

if string match -q '*Unknown command*' -- "$output"
    printf 'ASSERTION FAILED: load_env resolves its argument helper\nactual: %s\n' "$output" >&2
    exit 1
end

printf 'ok\n'
