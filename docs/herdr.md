# Herdr

## Desktop app

- **Project and worktree helpers**
  - `herdr_new_workspace [PATH]` (`hw`) opens a single-terminal space, or selects an
    existing local space in that checkout. PATH defaults to the current folder.
    - New names use `project_label`, such as `dots` and `dots:sa/foo`.
    - `--label NAME` overrides the name, including on an existing space.
  - `herdr_wt_switch` (`hwt`) opens the Worktrunk picker.
    - `herdr_wt_switch sa/foo` opens a branch directly.
    - `herdr_wt_switch --create --base @ sa/foo` creates from the current branch.
    - Ensures the main checkout has a space before opening the selected checkout.
    - Worktrunk controls checkout paths and hooks; the calling shell stays put.
  - These helpers require a running desktop app, `hc`, and `jq`.
  - `HC_TERMINAL_ID` selects the desktop behavior, including when `HERDR_ENV` is
    also inherited. Without it, the helpers retain the legacy TUI behavior.
    - Legacy terminals expose `HERDR_ENV`; outside either runtime the default
      remains the legacy TUI. `--simple` skips only the legacy split layout.
- **Configuration**
  - `~/.config/herdr-core/config.toml` selects Fish for new terminals and recovery.
  - `~/.config/herdr-app/keys.json`, `settings.json`, and `mods/tmux-prefix/` are
    chezmoi-managed personal configuration.
  - Ctrl+B opens the migrated prefix shortcuts; `?` shows the full list.
    - The first opening seeds agent sorting to Grouped by space if no sort has
      been selected. Later choices in the app are preserved.
  - `theme-set` links the generated palette as `themes/current.json` and selects
    it on the active layout. Other layouts inherit it unless they have a theme
    override of their own.
  - Shipped layouts, mods, generated guides/types, and runtime state are not
    imported into chezmoi.
- **Agent status**
  - The desktop app consumes native OSC 7501 reports; it has no equivalent to
    `herdr integration install`.
  - OpenCode 2.2.5 is confirmed to report natively; 2.0.8 does not.
  - `hc get <terminal>` should show `reported: true` and a non-null status.
  - The `53_herdr_integrations` script still serves the separate legacy TUI.
    - Its old socket integrations do not populate the desktop Agents panel.

## In Distrobox

An opt-in Linux user service starts the default Herdr server inside an
already-running `f`, after the existing Distrobox startup job. It does not
deliberately start or assemble `f`, replace an existing Herdr server, or change
ordinary SSH behavior. Both local `herdr` and `herdr --remote <server>` can
attach to the shared default session.

### Enable

After deploying the dotfiles, opt in on each machine with:

```bash
systemctl --user daemon-reload
systemctl --user enable --now herdr-distrobox.service
```

With user lingering enabled, startup happens at boot; otherwise it normally
happens at first login. The [Field Office setup script](../home/.chezmoiscripts/run_onchange_after_05_field_office.sh.tmpl)
enables lingering on Linux when `host.is_field_office` is `true`, unless it is
already enabled. If permission is denied, it warns with the command to run
manually. Other machines' lingering settings are left unchanged.

### Lifecycle

If `f` is down or a server already exists, startup is skipped. There are no
automatic retries or restarts: after starting `f` later, run
`systemctl --user start herdr-distrobox.service`. Ordinary Herdr startup can
still fall back to a host server when no server is running.

The running check is best-effort: if `f` stops between the check and entry,
Distrobox may start it again. Live handoff is not supported for service-managed
sessions; use `systemctl --user restart herdr-distrobox.service` when ready to
end the current panes and restart the server.

### Diagnose or Disable

Use `journalctl --user -u herdr-distrobox.service` for diagnostics. To opt out,
run `systemctl --user disable --now herdr-distrobox.service`; stopping an active
service ends its Herdr session and panes, but does not stop `f`. A pre-existing
server that caused startup to be skipped is left alone.
