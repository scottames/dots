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

#### Worktree layouts

Before creating or removing a worktree, detect the repo layout with read-only
Git commands:

```bash
git rev-parse --path-format=absolute --git-common-dir
git rev-parse --show-toplevel
git remote get-url origin 2>/dev/null
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null
git worktree list --porcelain
```

`git_clone_for_worktrees` defaults to the normal layout; `--bare` creates the
legacy layout.

- **Legacy `.bare` layout**: common dir basename is `.bare`; project root is its
  parent; worktrees go at `<project_root>/<branch_name>`.
- **Normal `<repo>/main` layout**: common dir basename is `.git`, toplevel
  basename is the default branch, and the parent matches the remote repo name or
  already has sibling worktrees. Project root is the parent; worktrees go at
  `<repo>/<branch_name>`. `<repo>/main` is durable Git infrastructure; never
  delete, replace, or repurpose it when cleaning up feature worktrees.
- **Ordinary clone**: anything else is a standalone clone. Do not assume the
  parent is a managed worktree root. Only create an external worktree if the
  task needs one; prefer `<toplevel_parent>/<repo_name>-<branch_name>`.

For managed layouts, start from the default branch unless I request another
base, e.g.
`git worktree add -b <branch_name> <project_root>/<branch_name> main`. Worktrunk
mirrors this with `{{ repo_path }}/../{{ branch | sanitize }}`.

Safety:

- Sanitize branch names for path safety (letters, numbers, `/`, `-`, `_`, `.`)
- Never reuse an existing target directory; choose a different branch/path
- Prefer read-only detection commands first; only run mutating git commands when
  needed for the requested task

#### Personal Projects

When cross-referencing between repositories owned by me (GitHub user:
`scottames`), all of my active projects will be checked out at
`~/src/github.com/scottames/`.

## Coding

### Coding Preferences

- Always prefer concise and simple solutions
- Prefer the smallest correct solution: understand the problem first, reuse
  existing code before writing new code, use standard library/native platform
  features before dependencies, and avoid unrequested abstractions. This does
  not override required workflows, tests, security, validation, accessibility,
  or explicit user requirements.
- If a task needs sharper YAGNI/minimalism pressure, use the `ponytail` skill.
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

### grep / ripgrep

- When running any grep/rg from $HOME or above `~/.local` ALWAYS exclude
  `./.local/share/containers/**`, otherwise you'll end up with a nasty amount of
  "permission denied" errors filling up the context

### GitHub Actions Workflows

- Use `actionlint` to verify a workflow

### docker

- On Fedora Linux
  - assume docker is podman
  - most likely we are running inside a `distrobox` container (ask the user if
    host access is needed, should be rare) - see `$CONTAINER_ID` env
    - use `distrobox-host-exec` to execute commands outside the container
    - all user/project-space should work in the container
  - need a package for the session? (debugging, etc.) install it in the
    container! no problem. (`sudo dnf install ...`)

### Terraform / OpenTofu

- Unless otherwise stated, opentofu (`tofu`) should always be used over
  terraform

## On using Skills

**IMPORTANT**

If you think there is even a 1% chance a skill might apply to what you are
doing, you PROBABLY SHOULD invoke the skill. IF A SKILL APPLIES TO YOUR TASK,
YOU DO NOT HAVE A CHOICE. YOU MUST USE IT. This is not negotiable. This is not
optional. You cannot rationalize your way out of this. If the user does not want
to use the skill they will reject it.

### Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought                             | Reality                                                |
| ----------------------------------- | ------------------------------------------------------ |
| "This is just a simple question"    | Questions are tasks. Check for skills.                 |
| "I need more context first"         | Skill check comes BEFORE clarifying questions.         |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first.           |
| "I can check git/files quickly"     | Files lack conversation context. Check for skills.     |
| "Let me gather information first"   | Skills tell you HOW to gather information.             |
| "This doesn't need a formal skill"  | If a skill exists, use it.                             |
| "I remember this skill"             | Skills evolve. Read current version.                   |
| "This doesn't count as a task"      | Action = task. Check for skills.                       |
| "The skill is overkill"             | Simple things become complex. Use it.                  |
| "I'll just do this one thing first" | Check BEFORE doing anything.                           |
| "This feels productive"             | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means"            | Knowing the concept ≠ using the skill. Invoke it.      |

### Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (brainstorming, debugging) - these determine HOW to
   approach the task
2. **Implementation skills second** (frontend-design, mcp-builder) - these guide
   execution

"Let's build X" → brainstorming and planning first, then implementation skills.
"Fix this bug" → debugging first, then domain-specific skills.

### Skill Types

**Rigid** (TDD, debugging): Follow exactly. Don't adapt away discipline.
**Flexible** (patterns): Adapt principles to context.

The skill itself tells you which.

### User Instructions

Instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip workflows.
