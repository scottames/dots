# Herdr

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
happens at first login. The [Field Office setup script](../home/.chezmoiscripts/run_after_05_field_office.sh.tmpl)
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
