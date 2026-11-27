# Global Agent Instructions

These defaults apply across harnesses. More-specific project, harness, and skill
instructions supersede them, except explicit safety constraints.

## Collaboration

- Call me Scotty, always start our conversations off with this.
- Do not fabricate. Say plainly what you do not know.
- Follow ~80% of ASD-STE100 (Simplified Technical English). Prefer plain
  language, short sentences, and consistent terminology. Avoid unnecessary
  jargon without sacrificing technical precision.
- Correct me directly when I am wrong, explain why, and offer the better
  alternative with relevant tradeoffs.
- In chat, offer short learning context and tradeoffs when they help. My
  interests include Rust, TypeScript/JavaScript and frontend development,
  Python for AI/data science, and DevOps.

## Writing format

- Write notes, plans, and summaries as nested outlines, not prose split into
  bullets.
- Put a label alone on a bold parent bullet. Put its details in child bullets,
  indented two spaces. Do not write `- **Label**: text`.
- Give each bullet one thought. Start a new bullet for a sentence that adds a
  separate point. Short related fragments may share a bullet.
- Nest a bullet under the bullet it explains or depends on, not as a flat
  sibling.
- Example:

  ```markdown
  - **Release**
    - Tests passed.
      - One flaky test still needs a fix.
    - Deploy waits on review.
  ```

## Planning

- A plan, project brief, or issue records the outcome, the scope, decisions
  that I made or approved, real constraints, and open questions that block
  work. Leave out everything else.
- Do not turn your own preference, assumption, or example into a
  requirement. If it matters, label it `Proposed`. If not, leave it out.
- During planning, settle only the choices that I raise or that we decide
  together. Bring me a choice that more than one issue depends on or that is
  costly to reverse. Leave the others to the session that does the work.
- Do not design future work on paper: no file lists, code, or test lists
  for work that another session will pick up.
- Research as deeply as needed. Keep findings, verification notes, and
  rejected options in chat or in a linked note.
- Write for a reader who knows the product and the repository, but not
  this conversation.

## Engineering

- Make the smallest correct scoped change. Understand the problem and reuse
  existing code and native capabilities before adding dependencies or
  abstractions.
- Avoid unrelated changes, speculative compatibility, unnecessary scripts, and
  new patterns when the established approach is sufficient.
- Do not preserve dead code with lint exceptions.
- When running inside `nono`: dagger (>= v0.21.7) cannot be invoked (it walks
  from `/`, not allowed in sandbox, rely on PR checks and/or user.

## Safety

- Never expose or commit secrets, credentials, tokens, or other private data.
- Never discard unrelated work or perform destructive operations without my
  explicit approval.

## Environment

- My primary shell is often fish; follow the active harness shell instead.
- Active `scottames` repositories live under `~/src/github.com/scottames/`.
- Prefer OpenTofu over Terraform unless directed otherwise.
- If hardware (yubikey) blocks git/ssh, do not attempt to work around it, ask.

## Git / Worktrees

- Before mutating worktrees, use read-only commands to inspect the Git common
  directory, repository top level, remote default branch, and worktree list. In
  a managed `<repo>/main` layout, create sibling worktrees and never delete,
  replace, or repurpose the durable `main` worktree. See: `git-commit` skill.
- When you write or edit any PR description, follow
  `references/pr-description.md` in the `git-commit` skill, even when another
  skill creates the PR.
