#!/usr/bin/env fish

set -l repo_root (path dirname (path dirname (path dirname (status filename))))
set -l is_has "$repo_root/home/private_dot_config/fish/conf.d/__is_has.fish"
set -l nvim_wrapper "$repo_root/home/private_dot_config/fish/custom_functions.d/nvim.fish"
set -gx HOME (mktemp -d)

function cleanup --on-event fish_exit
    rm -rf "$HOME"
end

function is_light
    return 1
end

# Simulate independently installed stack CLIs without gh.
set -g IS_HAS_TEST_GH_AVAILABLE false
function type
    if contains -- gh $argv
        test "$IS_HAS_TEST_GH_AVAILABLE" = true
        return
    end
    if contains -- gh-stack $argv
        return 0
    end
    if contains -- gt $argv
        return 0
    end
    if contains -- distrobox-host-exec $argv
        return 0
    end
    builtin type $argv
end

source "$is_has"

if test "$HAS_GH" != false
    printf 'ASSERTION FAILED: fixture reports gh as unavailable\n' >&2
    exit 1
end

if test "$HAS_GH_STACK" != true
    printf 'ASSERTION FAILED: hyphenated gh-stack normalizes to HAS_GH_STACK\nactual: %s\n' "$HAS_GH_STACK" >&2
    exit 1
end

if test "$HAS_GT" != true
    printf 'ASSERTION FAILED: gt is included in generic capability detection\nactual: %s\n' "$HAS_GT" >&2
    exit 1
end

if test "$HAS_DISTROBOX_HOST_EXEC" != true
    printf 'ASSERTION FAILED: distrobox-host-exec normalizes to HAS_DISTROBOX_HOST_EXEC\nactual: %s\n' "$HAS_DISTROBOX_HOST_EXEC" >&2
    exit 1
end

function is_distrobox
    return 1
end

function distrobox
    set -g IS_HAS_TEST_DISTROBOX_CALL $argv
end

mkdir -p "$HOME/bin"
printf '#!/bin/sh\nexit 0\n' >"$HOME/bin/nvim"
chmod +x "$HOME/bin/nvim"
set -gx PATH "$HOME/bin" $PATH
set -gx HAS_DISTROBOXHOSTEXEC false
set -gx DISTROBOX_DEFAULT test-box
source "$nvim_wrapper"
nvim example.txt
set -l distrobox_call (string join ' ' -- $IS_HAS_TEST_DISTROBOX_CALL)
if test "$distrobox_call" != 'enter test-box -- nvim example.txt'
    printf 'ASSERTION FAILED: nvim consumes HAS_DISTROBOX_HOST_EXEC\nactual: %s\n' "$distrobox_call" >&2
    exit 1
end

printf 'ok\n'
