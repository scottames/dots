#!/usr/bin/env zsh
# documentation: http://zsh.sourceforge.net/Doc/Release/Options.html

# -------------------------------------------------------------------
# basics
# -------------------------------------------------------------------
setopt no_beep # don't beep on error
setopt interactive_comments # Allow comments even in interactive shells (especially for Muness)
setopt RM_STAR_WAIT # add a 10 second wait before you can confirm a wildcard deletion

# -------------------------------------------------------------------
# changing directories
# -------------------------------------------------------------------
setopt auto_cd # If you type foo, and it isn't a command, and it is a directory in your cdpath, go there
setopt cdablevarS # if argument to cd is the name of a parameter whose value is a valid directory, it will become the current directory
setopt pushd_ignore_dups # don't push multiple copies of the same directory onto the directory stack

# -------------------------------------------------------------------
# expansion and globbing
# -------------------------------------------------------------------
setopt extended_glob # treat #, ~, and ^ as part of patterns for filename generation

# -------------------------------------------------------------------
# history
# -------------------------------------------------------------------
setopt append_history # Allow multiple terminal sessions to all append to one zsh command history
setopt extended_history # save timestamp of command and duration
setopt inc_append_history # Add comamnds as they are typed, don't wait until shell exit
setopt hist_expire_dups_first # when trimming history, lose oldest duplicates first
setopt hist_ignore_dups # Do not write events to history that are duplicates of previous events
setopt hist_ignore_space # remove command line from history list when first character on the line is a space
setopt hist_find_no_dups # When searching history don't display results already cycled through twice
setopt hist_reduce_blanks # Remove extra blanks from each command line being added to history
setopt hist_verify # don't execute, just expand history
setopt auto_pushd # make cd push the old directory onto the directory stack
setopt share_history # imports new commands and appends typed commands to history

# -------------------------------------------------------------------
# completion
# -------------------------------------------------------------------
setopt always_to_end # When completing from the middle of a word, move the cursor to the end of the word
setopt auto_menu # show completion menu on successive tab press. needs unsetop menu_complete to work
setopt auto_name_dirs # any parameter that is set to the absolute name of a directory immediately becomes a name for that directory
setopt complete_in_word # Allow completion from within a word/phrase

unsetopt menu_complete # do not autoselect the first completion entry

# -------------------------------------------------------------------
# correction
# -------------------------------------------------------------------
unsetopt correct_all # spelling correction for arguments
setopt correct # spelling correction for commands

# -------------------------------------------------------------------
# prompt
# -------------------------------------------------------------------
setopt prompt_subst # Enable parameter expansion, command substitution, and arithmetic expansion in the prompt
# setopt transient_rprompt # only show the rprompt on the current prompt

# -------------------------------------------------------------------
# scripts and functions
# -------------------------------------------------------------------
setopt multios # perform implicit tees or cats when multiple redirections are attempted
