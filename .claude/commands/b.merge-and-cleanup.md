Merge PR and cleanup worktree with implementation summary for issue: $ARGUMENTS.

Follow these steps:

1. **Verify Worktree Environment**
   ```bash
   # Check current directory is a worktree
   pwd  # Should show clubpay-issue-XXX pattern

   # Verify we're in correct branch
   git branch --show-current
   ```

2. **Check and Handle Uncommitted Changes**
   ```bash
   # Check for any uncommitted changes
   git status

   # If there are uncommitted changes:
   git add -A
   git commit -m "chore: final adjustments before merge (Issue #$ARGUMENTS)" in Japanese
   git push

   # Wait for CI checks to pass after push
   gh pr checks --watch
   ```

3. **Get PR Details and Extract Related Issues**
   ```bash
   # Get PR information
   gh pr view --json title,body,number,url,state

   # Extract issue numbers from "Closes #XXX" or "Fixes #XXX" patterns
   # Look for related issues in PR description
   ```

4. **Verify Merge Readiness**
   ```bash
   # Check PR status and approvals
   gh pr status

   # Ensure all checks are passing (should be done after step 2)
   gh pr checks

   # Final verification - no uncommitted changes
   git status
   ```

5. **Merge PR with Branch Cleanup**
   ```bash
   # Merge PR and delete remote branch
   gh pr merge --merge --delete-branch

   # Confirm merge was successful
   gh pr view --json state,mergedAt
   ```

6. **Post Implementation Summary to Related Issues**
   ```bash
   # For each issue that was closed by this PR:
   gh issue comment $ARGUMENTS --body "
   ## 📊 Implementation Summary

   ### ✅ Status: Completed via PR #[PR_NUMBER]

   ### 🎯 Key Changes
   - [List main changes implemented]
   - [Technical improvements made]
   - [New features added]

   ### 📈 Results & Metrics
   - [Performance improvements if applicable]
   - [Test coverage metrics if relevant]
   - [User experience enhancements if measurable]

   ### 🔧 Technical Details
   - [Architecture decisions made]
   - [New dependencies introduced]
   - [Configuration changes required]
   - [Database migrations if any]

   ### 📚 Lessons Learned
   - [Technical challenges encountered]
   - [Solutions and approaches applied]
   - [Knowledge gained during implementation]
   - [Best practices discovered]

   ### 🧪 Quality Assurance
   - [Testing strategies employed]
   - [Code review outcomes]
   - [Performance benchmarks]
   - [Security considerations addressed]

   ### ⏭️ Next Steps & Follow-ups
   - [Follow-up tasks if any]
   - [Future improvements planned]
   - [Monitoring requirements]
   - [Documentation updates needed]

   ---
   *Implemented in PR #[PR_NUMBER] and merged to main branch*
   🤖 Generated with [Claude Code](https://claude.ai/code)

   Co-Authored-By: Claude <noreply@anthropic.com>
   "
   ```

7. **Close Related Issues**
   ```bash
   # Close the main issue
   gh issue close $ARGUMENTS

   # Close any other issues that were resolved by this PR
   # (extracted from PR description)
   ```

8. **Navigate to Main Repository for Cleanup**
   ```bash
   # Get the parent directory (main repository)
   cd ..

   # Verify we're now in main repository
   pwd  # Should show main clubpay directory
   git remote -v  # Should show main repository remotes
   ```

9. **Update Main Repository**
   ```bash
   # Switch to main branch and pull latest changes
   git checkout main
   git pull origin main

   # Verify the merge is reflected
   git log --oneline -5
   ```

10. **Remove Worktree**
   ```bash
   # Remove the worktree directory
   git worktree remove clubpay-issue-$ARGUMENTS --force

   # Verify worktree removal
   git worktree list
   ```

11. **Clean Up Local References**
    ```bash
    # Prune remote tracking branches
    git remote prune origin

    # Clean up any remaining local references
    git branch -d feature/issue-$ARGUMENTS-* 2>/dev/null || true
    ```

12. **Final Verification**
    ```bash
    # Verify final state
    git branch -a
    git log --oneline -5
    git worktree list

    # Confirm issue is closed
    gh issue view $ARGUMENTS --json state,closedAt
    ```

## Important Notes:

### Pre-Merge Checklist:
- **Always check `git status` before attempting merge** - Uncommitted changes will cause issues
- **Commit and push any pending changes** - The worktree will be removed after merge
- **Wait for CI checks to complete** - Never proceed with failing checks
- **Verify PR is approved** - Some repositories require approval before merge

### Worktree-Specific Considerations:
- **Always run this command from within the worktree directory** (clubpay-issue-XXX)
- The worktree will be completely removed after merge - ensure all work is committed
- A new Claude Code session should be started after worktree removal
- Main repository will be updated with latest changes from main branch

### Error Handling:
- If merge fails, investigate PR status and resolve conflicts before retrying
- If worktree removal fails, check for any open files or processes in the directory
- If issue closure fails, manually close through GitHub web interface

### Post-Merge Workflow:
- Start new development from the updated main branch
- Create new worktrees for subsequent issues from the clean main branch
- Monitor CI/CD pipelines for any post-merge issues

ARGUMENTS: issue_number

Example usage: `/b.merge-and-cleanup 230`
