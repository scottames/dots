function _stax_trunk --description "Read the configured trunk without changing repository metadata"
    set -l trunk (command git show refs/stax/trunk 2>/dev/null)
    if test -z "$trunk"
        set trunk (command git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | string replace 'origin/' '')
    end
    if test -z "$trunk"
        for candidate in main master
            if command git show-ref --verify --quiet refs/heads/$candidate
                set trunk $candidate
                break
            end
        end
    end
    if test -z "$trunk"
        printf 'Cannot determine trunk; initialize Stax or select --base explicitly.\n' >&2
        return 1
    end
    printf '%s\n' "$trunk"
end
