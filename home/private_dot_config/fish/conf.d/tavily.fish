# Load Tavily API key from keyring (with file fallback)
if status is-interactive
    set -l tavily_key (secrettool_get_dots tavily --fallback "$HOME/.tavily.token" 2>/dev/null)
    if test -n "$tavily_key"
        set -gx TAVILY_API_KEY $tavily_key
    else
        printf_warn "Tavily API key not found in keyring or ~/.tavily.token"
    end
end
