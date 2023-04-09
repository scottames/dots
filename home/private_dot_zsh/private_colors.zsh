#!/usr/bin/env zsh

function print_black() {
  print -- "${fg[black]}${1}${reset_color}"
}

function print_black_bold() {
  print -- "${fg_bold[black]}${1}${reset_color}"
}

function print_red() {
  print -- "${fg[red]}${1}${reset_color}"
}

function print_red_bold() {
  print -- "${fg_bold[red]}${1}${reset_color}"
}

function print_green() {
  print -- "${fg[green]}${1}${reset_color}"
}

function print_green_bold() {
  print -- "${fg_bold[green]}${1}${reset_color}"
}

function print_yellow() {
  print -- "${fg[yellow]}${1}${reset_color}"
}

function print_yellow_bold() {
  print -- "${fg_bold[yellow]}${1}${reset_color}"
}

function print_blue() {
  print -- "${fg[blue]}${1}${reset_color}"
}

function print_blue_bold() {
  print -- "${fg_bold[blue]}${1}${reset_color}"
}

function print_magenta() {
  print -- "${fg[magenta]}${1}${reset_color}"
}

function print_magenta_bold() {
  print -- "${fg_bold[magenta]}${1}${reset_color}"
}

function print_cyan() {
  print -- "${fg[cyan]}${1}${reset_color}"
}

function print_cyan_bold() {
  print -- "${fg_bold[cyan]}${1}${reset_color}"
}

function print_white() {
  print -- "${fg[white]}${1}${reset_color}"
}

function print_white_bold() {
  print -- "${fg_bold[white]}${1}${reset_color}"
}

function print_info() { print_white_bold "${INFO} ${1}" }
function print_warn() { print_yellow_bold "${WARNING} ${1}" }
function print_err() { print_red_bold "${CROSS} ${1}" }
alias print_fail=print_err

alias printr=print_red
alias printrbld=print_red_bold
alias printg=print_green
alias printgbld=print_green_bold
alias printy=print_yellow
alias printybld=print_yellow_bold
alias printb=print_blue
alias printbbld=print_blue_bold
alias printm=print_magenta
alias printmbld=print_magenta_bold
alias printc=print_cyan
alias printcbld=print_cyan_bold
alias printw=print_white
alias printwbld=print_white_bold

## Resources
# https://www.rockhoppertech.com/blog/zsh-using-color/
# https://wiki.archlinux.org/title/zsh#Colors
