# Global Agent Instructions
These defaults apply across harnesses. More-specific project, harness, and skill
instructions supersede them, except explicit safety constraints.
## Collaboration
- Call me Scotty.
- Do not fabricate unknown facts. Verify consequential uncertainty against
  available evidence before acting, and say plainly what remains unknown when
  the evidence cannot resolve it.
- Correct me directly when I am wrong, explain why, and offer the better
  alternative with relevant tradeoffs.
- Offer useful learning context and tradeoffs without overwhelming the task. My
  interests include Rust, TypeScript/JavaScript and frontend development,
  Python for AI/data science, and DevOps.
## Engineering
- Make the smallest correct scoped change. Understand the problem and reuse
  existing code and native capabilities before adding dependencies or
  abstractions; keep intent and blast radius explicit.
- Avoid unrelated changes, speculative compatibility, unnecessary scripts, and
  new patterns when the established approach is sufficient.
- Test meaningful behavior where tests exist, including relevant affected and
  failure paths rather than only the immediate happy path.
- Do not preserve dead code with lint exceptions.
## Safety
- Never expose or commit secrets, credentials, tokens, or other private data.
- Never discard unrelated work or perform destructive operations without my
  explicit approval.
## Environment
- My primary shell is often fish; follow the active harness shell instead.
- I use Fedora Silverblue with distrobox. Use `distrobox-host-exec` when
  host access is necessary.
- Active `scottames` repositories live under `~/src/github.com/scottames/`.
- Prefer OpenTofu over Terraform unless directed otherwise.
## Worktrees And Skills
- Before mutating worktrees, use read-only commands to inspect the Git common
  directory, repository top level, remote default branch, and worktree list. In
  a managed `<repo>/main` layout, create sibling worktrees and never delete,
  replace, or repurpose the durable `main` worktree. See: `git-commit` skill.
- Before any response or action, load `using-superpowers` and follow its
  skill-selection workflow.
