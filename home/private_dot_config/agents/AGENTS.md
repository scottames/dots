# Global Agent Rules

Guidance on my personal workflow and preferences.

## Core Standards

### ALWAYS

Call me Scotty

#### DO NOT GUESS

If you do not know, never guess. Say you do not know, we will figure it out
together.

#### Call me out

If I am wrong, call me out. I'm always learning, there may be a better way that
we can learn from!

### Learning

I'm always trying to learn. If there are opportunities you see to help me learn
or dig in deeper, ask.

#### Some context

- I am proficient in these in this order:
  - Shellscript
  - Golang
  - Python
  - Rust
- My background is in DevSecOps with some backend development

#### Key Focus Areas

In these areas, you should especially help me understand deeper what we are
implementing together, what implications of decisions are, etc.

Attempting to become proficient in:

- Rust
- Typescript and Javascript
  - Generally frontend development, it is foreign to me, but I am very
    interested in learning the ins and outs
- Python
  - As it applies to AI and Data Science

Always interested to get better at:

- DevOps (all-things!)

If you have thoughts on better how to make these directions better to help us
learn together, let me know.

## Environment

### Shell

- Current shell is likely fish shell, commands should be fish compliant or run
  with `bash -c`. Verify if unsure.

Some wrappers may cause commands to behave strangely, use absolute paths (e.g.
`/bin/ls`) or prepend `command` (e.g. `command ls`) for these specific and any
others you get weird behavior with.

- `cd` (wraps zoxide)
- `ls` (wraps `eza`)
- `rm` (alias uses `-i` for safety, blocks agent use)

### Git

Yubikey is used for:

- GPG (git commit signing), no touch required
- SSH (git push/pull), touch is required - coordinate with me to do so

#### Worktrees / Bare checkout layout

Most of my repositories use a bare-checkout + worktree layout. When creating a
worktree:

- Detect repo layout with
  `git rev-parse --path-format=absolute --git-common-dir` and
  `git rev-parse --show-toplevel`
- If the common dir basename is `.bare`, treat this as bare-checkout + worktree
  mode
- In bare-checkout + worktree mode, create new worktrees as siblings of `.bare`
  at `<common_dir_parent>/<branch_name>` (equivalent to `../<branch_name>` when
  working from `main`)
- Use `main` as the start point unless I explicitly request a different base:
  `git worktree add -b <branch_name> <common_dir_parent>/<branch_name> main`
- If repo is in bare-checkout + worktree mode, this layout should be used unless
  I explicitly say otherwise
- If repo is not in bare-checkout + worktree mode, treat it as a regular clone
  and do not assume this layout

Safety:

- Sanitize branch names for path safety (letters, numbers, `/`, `-`, `_`, `.`)
- Never reuse an existing target directory; choose a different branch/path
- Prefer read-only detection commands first; only run mutating git commands when
  needed for the requested task

## Coding

### Coding Preferences

- Always prefer concise and simple solutions
- Keep the codebase very clean and organized
- Avoid duplication of code whenever possible, which means checking for other
  areas of the codebase that might already have similar code and functionality
- Be careful to only make changes that are requested or are well understood and
  related to the change being requested
- When fixing an issue or bug, do not introduce a new pattern or technology
  without first exhausting all options for the existing implementation. And if
  this becomes necessary, present the new design and get confirmation that this
  is indeed the correct direction
- Avoid writing scripts in files if possible, especially if the script is likely
  only to be run once
- Avoid having files over 200-300 lines of code. Refactor at that point.
- Never keep around dead code by adding a linter comment to allow it unless
  explicitly told to

### Coding Workflow Preferences

- Focus on the areas of code relevant to the task
- Do not touch code that is unrelated to the task
- Write thorough tests for all major functionality where tests already exist
- Avoid making major changes to the patterns and architecture of how a feature
  works, after it has shown to work well, unless explicitly instructed
- Always think about what other methods and areas of code might be affected by
  code changes

### Shell Scripting

(aka shell scripts, bash, fish, etc.)

- `shellcheck` should always be adhered to
  - including in justfiles and github workflows, if applicable

## Tool-Specific

### docker

- On Fedora Linux assume docker is podman

### Terraform / OpenTofu

- Unless otherwise stated, opentofu (`tofu`) should always be used over
  terraform
