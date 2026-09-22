function fish_title
    set -l title (string replace -- "$HOME/src/github.com/" '~/s/g/' -- "$PWD")
    if test "$title" = "$PWD"
        set title (prompt_pwd)
    end
    echo $title
end
