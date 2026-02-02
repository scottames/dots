# Load Tavily API key from file if present
if status is-interactive
    if test -f "$HOME/.tavily.token"
        set -gx TAVILY_API_KEY (cat "$HOME/.tavily.token")
    else
        printf_warn "no ~/.tavily.token found, not setting"
    end
end
