#!/bin/env fish

if [ $IS_LINUX ]
    and ! [ $HAS_EZA ]
    set _ls_arg ' --color'
end

abbr -a ax aws_ctx # see functions
abbr -a axc "aws_ctx clear"
abbr -a agi "aqua g -i"
abbr -a aia "aqua i -a"
abbr -a aquagi "aqua g -i"
abbr -a aquaia "aqua i -a"
abbr -a ch chezmoi
abbr -a cha "chezmoi add"
abbr -a chcd "cd (chezmoi source-path)"
abbr -a chd "chezmoi diff"
abbr -a che "chezmoi edit"
abbr -a chef chezmoi_edit_fzf
abbr -a chet "chezmoi execute-template" # + '{{ .chezmoi.hostname }}' OR < foo.tmpl
abbr -a chg "chezmoi git --"
abbr -a chgm "chezmoi git -- commit -m"
abbr -a chgmn "chezmoi git -- commit -n -m"
abbr -a chm "chezmoi merge"
abbr -a chs "chezmoi status"
abbr -a da "direnv allow"
abbr -a db distrobox
abbr -a dba "distrobox assemble"
abbr -a dbac "distrobox assemble create --replace --file $HOME/.config/distrobox/assemble.ini"
abbr -a dbhe distrobox-host-exec
abbr -a dc "distrobox create"
abbr -a de "distrobox enter"
abbr -a dep "distrobox ephemeral"
abbr -a dl "distrobox list"
abbr -a dr "distrobox rm"
abbr -a ds "distrobox stop"
abbr -a du "distrobox upgrade"
abbr -a f "distrobox enter f"
abbr -a G "grep -i"
abbr -a dots "cd $DOTS"
abbr -a g git
abbr -a ga "git add"
abbr -a gaa "git add ."
abbr -a gaaa "git add --all"
abbr -a gaf "git add-fzf"
abbr -a gau "git add --update"
abbr -a gb "git branch"
abbr -a gbr git_checkout_fzf # see functions
abbr -a gbd "git branch --delete "
abbr -a gc "git checkout"
abbr -a gcb "git checkout -b"
abbr -a gcbwd git_checkout_branch_with_date
abbr -a gcbo "git checkout -t origin/"
abbr -a gcld git_clone_cd # see functions
abbr -a gcl "git clone"
abbr -a gcln git_clean # see functions
abbr -a gclip getclip
abbr -a gcm "git commit"
abbr -a gco "git checkout"
abbr -a gcontrib "git shortlog | grep -E '^[^ ]'" # list contributors
abbr -a gd "git diff"
abbr -a gdf "git diff-fzf"
abbr -a gds "git diff --staged"
abbr -a gda "git diff HEAD"
abbr -a gdb "git diff master..`git rev-parse --abbrev-ref HEAD`"
abbr -a gf "git reflog"
abbr -a ghist "git hist"
abbr -a ghpr "GH_FORCE_TTY=100% gh pr list | fzf --ansi --preview 'GH_FORCE_TTY=100% gh pr view {1}' --preview-window down --header-lines 3 | awk '{print $1}'"
abbr -a ginit "git init"
abbr -a gitref "git rev-parse --short HEAD && git rev-parse HEAD"
abbr -a gl "git log"
abbr -a glg "git log --graph --oneline --decorate --all"
abbr -a gm "git commit -m"
abbr -a gma "git commit -am"
abbr -a gmn "git commit -n -m"
abbr -a gp "git push"
abbr -a gpf "git push --force-with-lease"
abbr -a gpff "git push --force"
abbr -a gpl "git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
abbr -a gpu "git pull"
abbr -a gprn git_prune
abbr -a gr "git rebase"
abbr -a gra "git remote add"
abbr -a grf "git checkout --"
abbr -a grhard "git reset HEAD --hard"
abbr -a grr "git remote rm"
abbr -a grs "git restore"
abbr -a grsh "git reset --soft HEAD~"
abbr -a gs git_status # see functions
abbr -a gsf "git show-fzf"
abbr -a gst "git stash"
abbr -a gsta "git stash apply"
abbr -a gstd "git stash drop"
abbr -a gstl "git stash list"
abbr -a gstp "git stash pop"
abbr -a gsts "git stash save"
abbr -a gsw "git switch"
abbr -a gta "git tag -a -m"
abbr -a gtd "gt down"
abbr -a gtl "gt log"
abbr -a gtls "gt ls"
abbr -a gtu "gt up"
abbr -a gtss "gt submit --stack --update-only"
abbr -a gu git_update
abbr -a guc gum_commit
abbr -a gv "git log --pretty=format:'%s' | cut -d \" \" -f 1 | sort | uniq -c | sort -nr"
abbr -a gwtls "git worktree list"
abbr -a gwtrm "git worktree remove"
abbr -a k kubectl
abbr -a kctl kubectl
abbr -a ketall "kubectl get-all"
abbr -a kubectx "kubectl ctx"
abbr -a kubens "kubectl ns"
abbr -a lg lazygit
abbr -a lh "ls -d .*$_ls_arg" # show hidden files/directories only
abbr -a lsd "ls -ld *$_ls_arg" # show directories
abbr -a lsf "ls -aFhl$_ls_arg"
abbr -a l "ls -alh$_ls_arg" # list all (including hidden)
abbr -a ll "ls -hl$_ls_arg" # list long w/ headers
abbr -a makepass "openssl rand -base64 12"
abbr -a md mkdir_cd
abbr -a mgt "mage go:test"
abbr -a mages mage-select
abbr -a mg mage
abbr -a mgs mage-select
abbr -a nmap_check_for_firewall "sudo nmap -sA -p1-65535 -v -T4"
abbr -a nmap_check_for_vulns "nmap --script=vuln"
abbr -a nmap_detect_versions "sudo nmap -sV -p1-65535 -O --osscan-guess -T4 -Pn"
abbr -a nmap_fast "nmap -F -T5 --version-light --top-ports 300"
abbr -a nmap_fin "sudo nmap -sF -v"
abbr -a nmap_full "sudo nmap -sS -T4 -PE -PP -PS80,443 -PY -g 53 -A -p1-65535 -v"
abbr -a nmap_full_udp "sudo nmap -sS -sU -T4 -A -v -PE -PS22,25,80 -PA21,23,80,443,3389 "
abbr -a nmap_full_with_scripts "sudo nmap -sS -sU -T4 -A -v -PE -PP -PS21,22,23,25,80,113,31339 -PA80,113,443,10042 -PO --script all "
abbr -a nmap_list_interfaces "nmap --iflist"
abbr -a nmap_open_ports "nmap --open"
abbr -a nmap_ping_through_firewall "nmap -PS -PA"
abbr -a nmap_slow "sudo nmap -sS -v -T1"
abbr -a nmap_traceroute "sudo nmap -sP -PE -PS22,25,80 -PA21,23,80,3389 -PU -PO --traceroute "
abbr -a nmap_web_safe_osscan "sudo nmap -p 80,443 -O -v --osscan-guess --fuzzy "
abbr -a nosleep "systemd-inhibit --what=handle-lid-switch sleep 2592000" # disable systemd sleep
abbr -a o open
abbr -a oo "open ."
abbr -a pcr "pre-commit run"
abbr -a pcra "pre-commit run -a"
abbr -a pp print_path # see functions
abbr -a rm "rm -i"
abbr -a sclip setclip
abbr -a ta "tmux attach -t"
abbr -a tattach "tmux attach -t base || tmux new -s base"
abbr -a tc "trunk check"
abbr -a tcc "trunk check --ci"
abbr -a tf terraform
abbr -a tfa "terraform apply"
abbr -a tfc "rm -rf .terraform"
abbr -a tfi "terraform init"
abbr -a tfp "terraform plan"
abbr -a tfv "terraform validate"
abbr -a tfver "terraform version"
abbr -a tk "tmux kill-session -t"
abbr -a tls "tmux ls"
abbr -a tm "tmux attach || tmux"
abbr -a tmux "tmux -u"
abbr -a tn "tmux new -s"
abbr -a ttakeover "tmux detach -a"
abbr -a v vim
abbr -a vd "vagrant destroy"
abbr -a vh "vagrant halt"
abbr -a vp "vagrant provision"
abbr -a vr "vagrant reload"
abbr -a vs "vagrant ssh"
abbr -a vst "vagrant status"
abbr -a vu "vagrant up"
abbr -a za zellij_attach # see functions
abbr -a zja zellij_attach # see functions
abbr -a ze zellij_edit # see functions
abbr -a zef zellij_edit --floating # see functions
abbr -a ze. "zellij_new_tab_edit_split $DOTS --name=." # see functions
abbr -a zeb "zellij_new_tab_edit_split $MY_SRC_DIR/boxes --name='[]'"
abbr -a zet zellij_new_tab_edit_split
abbr -a zeu "zellij_new_tab_edit_split $MY_SRC_DIR/ublue"
abbr -a zego "zellij_new_tab_edit_split --layout=go"
abbr -a zj zellij # see functions
abbr -a zjac "zellij action"
abbr -a zjpd "zellij action new-pane --direction down"
abbr -a zjpl "zellij action new-pane --direction left"
abbr -a zjpr "zellij action new-pane --direction right"
abbr -a zjpu "zellij action new-pane --direction up"
abbr -a zjr "zellij run --"
abbr -a zr zellij_run # see functions
abbr -a zrt zellij_rename_tab # see functions
abbr -a zte zellij_new_tab_edit_split # see functions

# ╭──────────────────────────────────────────────────────────╮
# │ cd helpers                                               │
# ╰──────────────────────────────────────────────────────────╯
abbr -a s "pwd > ~/.save_dir"
abbr -a i "cd (cat ~/.save_dir)"

# ╭──────────────────────────────────────────────────────────╮
# │ gitnow                                                   │
# ╰──────────────────────────────────────────────────────────╯
if type -q gitnow
    abbr -a stg stage
end

# ╭──────────────────────────────────────────────────────────╮
# │ tealdeer                                                 │
# ╰──────────────────────────────────────────────────────────╯
if [ $HAS_TLDR ]
    # requires tealdeer
    abbr -a tldrf "tldr --list | fzf --preview "tldr {1} --color=always" --preview-window=right,70% | xargs tldr"
end

# ╭──────────────────────────────────────────────────────────╮
# │ update & upgrade defaults                                │
# ╰──────────────────────────────────────────────────────────╯
set _default_upgrade "pip_upgrade && pip_upgrade_user && rust_upgrade"
set _default_update "aqua update-aqua && rustup update"

if [ $IS_LINUX ]
    switch $DISTRO
        case arch
            if [ $HAS_PARU ]
                abbr -a update "paru -Syy && $_default_update"
                abbr -a upgrade "paru -Syyu && $_default_upgrade"
            else
                abbr -a update "sudo pacman -Syy && $_default_update"
                abbr -a upgrade "printf_warn 'no AUR updates will be performed\n' && sudo pacman -Syyu && $_default_upgrade"
            end
        case ubuntu
            abbr -a upgrade "sudo apt update && sudo apt upgrade && sudo apt autoremove && $_default_upgrade"
            abbr -a update "sudo apt update && $_default_update"
    end
end

#  ╭──────────────────────────────────────────────────────────╮
#  │ mac                                                      │
#  ╰──────────────────────────────────────────────────────────╯
if [ $IS_MAC ]
    abbr -a brewupdate "brew update; brew upgrade; brew cleanup; brew doctor"
    abbr -a brewrefresh "brew outdated | while read -l cask; brew upgrade $cask; end"
    abbr -a ql "qlmanage -p 2>/dev/null" # OS X Quick Look
    abbr -a today "calendar -A 0 -f /usr/share/calendar/calendar.mark | sort"
    abbr -a mailsize "du -hs ~/Library/mail"
    abbr -a smart "diskutil info disk0 | grep SMART" # display SMART status of hard drive
    abbr -a wifi "networksetup -setairportpower en0"
end
