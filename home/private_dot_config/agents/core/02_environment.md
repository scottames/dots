# Environment

## Shell

- Current shell is likely fish shell, commands should be fish compliant or run
  with `bash -c`. Verify if unsure.

Some wrappers may cause commands to behave strangely, use absolute paths (e.g.
`/bin/ls`) or prepend `command` (e.g. `command ls`) for these specific and any
others you get weird behavior with.

- `ls` (wraps `eza`, agent call causes errors)
- `rm` (alias uses `-i` for safety, blocks agent use)

## Git

Yubikey is used for:

- GPG (git commit signing), no touch required
- SSH (git push/pull), touch is required - coordinate with me to do so
