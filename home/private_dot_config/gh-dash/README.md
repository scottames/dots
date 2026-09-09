# gh-dash Configuration

`gh dash` is the repository dashboard. `gho` is the owner-dashboard launcher.
They deliberately use separate configurations because gh-dash cannot reliably
combine `repo:` with `user:` or `org:` filters.

## Configurations

- `config.base.yml.tmpl` is the base for the normal global config. `theme-set`
  appends the active theme to produce `~/.config/gh-dash/config.yml`. It has
  generic sections and `smartFilteringAtLaunch: true`, so `gh dash` or `ghd`
  inside a repository is scoped to that repository.
- `central.yml.tmpl` combines work and personal owner-wide PR sections. `gho`
  uses it outside either configured source tree.
- `personal.yml.tmpl` has personal owner-wide PR sections. `gho` selects it
  from within the personal source tree.
- `work.yml.tmpl` has work organization-wide PR sections. `gho` selects it
  from within the configured work source tree.

The owner configurations disable smart filtering. Their `t` bindings are
intentional no-ops so a fixed owner scope cannot be toggled into a broader,
unsafe query.

## Usage

```text
gh dash / ghd                 repository dashboard in the current repository
gho in personal source tree   personal owner dashboard
gho in work source tree       work owner dashboard
gho elsewhere                 combined personal and work dashboard
```

`gh dash` still follows its normal lookup order, so a repository-local
`.gh-dash.yml` takes precedence over the generated global configuration.
