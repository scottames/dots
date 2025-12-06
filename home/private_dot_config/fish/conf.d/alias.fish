#!/bin/env fish

if [ $HAS_NVIM ]
    alias vim='nvim'
    alias vi='nvim'
else if [ $HAS_VIM ]
    alias vi='vim'
end

alias watch='watch --color'

function printf_debug
    if $DEBUG
        printf_cyan_bold "$BULLET $argv"
    end
end

function printf_info
    printf_white_bold "$INFO $argv"
end
function printf_warn
    printf_yellow_bold "$WARNING $argv"
end
function printf_err
    printf_red_bold "$CROSS $argv"
end

alias printf_black "printf_color -c black"
alias printf_black_bold "printf_color -c black -b"
alias printf_red "printf_color -c red"
alias printf_red_bold "printf_color -c red -b"
alias printf_green "printf_color -c green"
alias printf_green_bold "printf_color -c green -b"
alias printf_yellow "printf_color -c yellow"
alias printf_yellow_bold "printf_color -c yellow -b"
alias printf_blue "printf_color -c blue"
alias printf_blue_bold "printf_color -c blue -b"
alias printf_magenta "printf_color -c magenta"
alias printf_magenta_bold "printf_color -c magenta -b"
alias printf_cyan "printf_color -c cyan"
alias printf_cyan_bold "printf_color -c cyan -b"
alias printf_white "printf_color -c white"
alias printf_white_bold "printf_color -c white -b"
alias printf_fail print_err
alias printfr printf_red
alias printfrbld printf_red_bold
alias printfg printf_green
alias printfgbld printf_green_bold
alias printfy printf_yellow
alias printfybld printf_yellow_bold
alias printfb printf_blue
alias printfbbld printf_blue_bold
alias printfm printf_magenta
alias printfmbld printf_magenta_bold
alias printfc printf_cyan
alias printfcbld printf_cyan_bold
alias printfw printf_white
alias printfwbld printf_white_bold
