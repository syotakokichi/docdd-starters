Create a new worktree for the issue: $ARGUMENTS.

Follow these steps:

1. Use `gh issue view` to get the issue details
2. Generate branch name from issue title
3. Create worktree directory at ../clubpay-issue-<number>
4. Use `git worktree add` to create the worktree
5. Show the created worktree path and next steps

Remember to:
- Check if worktree already exists
- Create new branch if it doesn't exist
- Show current worktrees with `git worktree list`
