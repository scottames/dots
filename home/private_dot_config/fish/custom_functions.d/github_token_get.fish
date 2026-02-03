#!/bin/env fish

# GitHub token resolution with layered fallback:
#   1. $GITHUB_TOKEN already set → use it
#   2. CI environment → no token (public repos only)
#   3. ghtkn has valid cached token → use it (no OAuth prompt)
#   4. fallback → PAT from ~/.gh.token

# --- Config ---
set -g _GHTKN_KEYRING_SERVICE "github.com/suzuki-shunsuke/ghtkn"
set -g _GHTKN_CONFIG_FILE "$HOME/.config/ghtkn/ghtkn.yaml"
set -g _GITHUB_TOKEN_PAT_FILE "$HOME/.gh.token"
# Buffer in seconds - consider token invalid if expiring within this time
set -g _GHTKN_EXPIRY_BUFFER 300
# Cached client_id (populated by _ghtkn_client_id)
set -g _GHTKN_CLIENT_ID_CACHE ""
# Cached app+config key associated with _GHTKN_CLIENT_ID_CACHE
set -g _GHTKN_CLIENT_ID_CACHE_KEY ""

# --- Helpers ---

function _ghtkn_config_file \
    --description "Get active ghtkn config path (GHTKN_CONFIG or default)"

    if set -q GHTKN_CONFIG[1]; and test -n "$GHTKN_CONFIG"
        echo "$GHTKN_CONFIG"
    else
        echo "$_GHTKN_CONFIG_FILE"
    end
end

function _ghtkn_app_name \
    --description "Get active ghtkn app name (GHTKN_APP or default)"

    if set -q GHTKN_APP[1]; and test -n "$GHTKN_APP"
        echo "$GHTKN_APP"
    else
        echo "$GITHUB_USER/ghtkn"
    end
end

function _ghtkn_client_id \
    --description "Get ghtkn client_id from config (cached, app-aware)"

    set -l app (_ghtkn_app_name)
    set -l cfg (_ghtkn_config_file)
    set -l cache_key "$app:$cfg"

    # Return cached value if available and app+config haven't changed
    if test -n "$_GHTKN_CLIENT_ID_CACHE" -a "$_GHTKN_CLIENT_ID_CACHE_KEY" = "$cache_key"
        echo "$_GHTKN_CLIENT_ID_CACHE"
        return 0
    end

    # Requires yq and config file
    command -q yq; or return 1
    test -f "$cfg"; or return 1

    # Look up by app name first, fall back to first app
    set -l client_id (yq ".apps[] | select(.name == \"$app\") | .client_id" "$cfg" 2>/dev/null)
    if test -z "$client_id" -o "$client_id" = null
        set client_id (yq '.apps[0].client_id' "$cfg" 2>/dev/null)
    end
    test -z "$client_id" -o "$client_id" = null; and return 1

    # Cache for subsequent calls
    set -g _GHTKN_CLIENT_ID_CACHE $client_id
    set -g _GHTKN_CLIENT_ID_CACHE_KEY $cache_key
    echo "$client_id"
end

function _ghtkn_has_valid_token \
    --description "Check if ghtkn has a valid cached token in keyring"

    # Requires secret-tool (libsecret) and jq
    command -q secret-tool; or return 1
    command -q jq; or return 1

    set -l client_id (_ghtkn_client_id); or return 1

    set -l secret (secret-tool lookup \
        service "$_GHTKN_KEYRING_SERVICE" \
        username "$client_id" 2>/dev/null)

    test -z "$secret"; and return 1

    # Parse expiration from JSON
    set -l exp (echo $secret | jq -r '.expiration_date' 2>/dev/null)
    test -z "$exp" -o "$exp" = null; and return 1

    # Compare expiration to now (with buffer)
    set -l exp_epoch (date -d "$exp" +%s 2>/dev/null)
    test -z "$exp_epoch"; and return 1

    set -l now_epoch (date +%s)
    set -l threshold (math "$now_epoch + $_GHTKN_EXPIRY_BUFFER")

    test "$exp_epoch" -gt "$threshold"
end

function _github_token_from_ghtkn \
    --description "Get token from ghtkn (assumes valid cache exists)"

    set -l client_id (_ghtkn_client_id); or return 1

    set -l secret (secret-tool lookup \
        service "$_GHTKN_KEYRING_SERVICE" \
        username "$client_id" 2>/dev/null)

    echo $secret | jq -r '.access_token' 2>/dev/null
end

function _github_token_from_pat \
    --description "Get token from PAT (keyring with file fallback)"

    secrettool_get_dots github-pat --fallback "$_GITHUB_TOKEN_PAT_FILE"
end

# --- Main ---

function github_token_get \
    --description "Get GitHub token using layered resolution (ghtkn → PAT fallback)"

    # 1. Already set - use it
    if set -q GITHUB_TOKEN[1]; and test -n "$GITHUB_TOKEN"
        echo $GITHUB_TOKEN
        return 0
    end

    # 2. CI environment - no token
    if set -q CI[1]; and test "$CI" = true
        return 1
    end

    # 3. ghtkn has valid cached token - use it
    if _ghtkn_has_valid_token
        _github_token_from_ghtkn
        return 0
    end

    # 4. Fallback to PAT
    if _github_token_from_pat
        return 0
    end

    return 1
end
