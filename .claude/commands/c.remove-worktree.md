Remove a worktree for the completed issue: $ARGUMENTS.

Follow these steps:

1. List all worktrees with `git worktree list`
2. Find the worktree for the given issue number
3. Check if there are uncommitted changes
4. Use `git worktree remove` to delete the worktree
5. Optionally delete the branch if merged

Remember to:
- Warn about uncommitted changes
- Ask for confirmation before removing
- Show remaining worktrees after removal
