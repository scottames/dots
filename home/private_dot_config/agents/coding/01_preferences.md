# Coding Preferences

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

## Coding Workflow Preferences

- Focus on the areas of code relevant to the task
- Do not touch code that is unrelated to the task
- Write thorough tests for all major functionality where tests already exist
- Avoid making major changes to the patterns and architecture of how a feature
  works, after it has shown to work well, unless explicitly instructed
- Always think about what other methods and areas of code might be affected by
  code changes
