Please commit changes and push to the remote repository.

Follow these steps:

1. **Check working directory**
   - Confirm you are in the project root: `pwd`
   - If not, change to project root: `cd $(git rev-parse --show-toplevel)`

2. **Review changes**
   - Run `git status` to check current changes
   - Run `git diff` to review unstaged changes
   - Run `git diff --cached` to review staged changes

3. **Check commit history**
   - Run `git log --oneline -5` to check recent commit message style

4. **Stage changes**
   - Run `git add .` to stage all changes (or specify files)
   - If in subdirectory, use relative paths: `git add ../../path/to/file`

5. **Commit with Japanese message**
   - Run `git commit` with appropriate message following project conventions
   - Use heredoc format for multi-line messages

6. **Handle pre-commit hooks**
   - If pre-commit hooks modify files:
     - Run `git status` to check what was modified
     - Run `git add .` to stage the modifications
     - Run `git commit -m "style: apply pre-commit fixes"` to create a new commit
   - **IMPORTANT**: Do NOT use `git commit --amend --no-edit` — if pre-commit hook fails, the original commit was not created, so `--amend` would modify the previous unrelated commit and destroy its changes

7. **Push to remote**
   - Run `git push` to push changes to remote repository
   - If rejected, run `git pull --rebase` first

Additional options:
- Specify files: `git add <file1> <file2>` instead of `git add .`
- Custom message: `git commit -m "<message>"`
- Skip push: Stop after step 6
- Dry run: Use `git diff --cached` to preview staged changes

Remember to follow the project's commit message conventions in Japanese and include the standard footer:
