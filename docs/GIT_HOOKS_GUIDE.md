# Git Hooks Setup Guide

## ✅ Pre-Push Hook Configured!

A Git pre-push hook is now set up to automatically run RuboCop auto-correction before every push.

## 🔧 How It Works

### Automatic Pre-Push Formatting

Every time you run `git push`, the hook will:

1. 🔍 Run `bundle exec rubocop -a` on all files
2. ✅ Auto-correct all possible formatting issues
3. 🚀 Proceed with the push if successful
4. ❌ Block the push if there are unfixable issues

### Example Workflow

```bash
# Make your changes
git add .
git commit -m "Update feature"

# Push to remote
git push origin main
# → Hook automatically runs: bundle exec rubocop -a
# → If successful, push proceeds
# → If issues remain, push is blocked
```

## 🚫 Bypassing the Hook

If you need to push without running the hook (not recommended):

```bash
git push --no-verify
```

## 📁 Hook Location

- **Hook file**: `.githooks/pre-push`
- **Git config**: Uses custom hooks path `.githooks/`

## 🔧 Manual Installation (for team members)

If a team member clones the repository, they need to run:

```bash
git config core.hooksPath .githooks
```

This tells Git to use the custom hooks directory instead of `.git/hooks/`.

## 📝 Hook Details

The pre-push hook:

- Runs `bundle exec rubocop -a` for auto-correction
- Exits with code 1 if issues can't be auto-fixed
- Shows helpful error messages
- Can be bypassed with `--no-verify` if needed

## 🎯 Benefits

- ✅ Consistent code style across all commits
- ✅ Prevents pushing improperly formatted code
- ✅ Automatic formatting before push
- ✅ Catches issues early

## 🔄 Updating the Hook

To modify the hook, edit:

```
.githooks/pre-push
```

After editing, the changes take effect immediately for all team members using the custom hooks path.

## 💡 Tips

1. **Commit before pushing**: RuboCop corrections will modify files, so commit your changes first
2. **Review auto-corrections**: Check what RuboCop changed before pushing
3. **Manual fixes**: If the hook blocks your push, fix remaining issues manually
4. **Team setup**: Ensure all team members run `git config core.hooksPath .githooks`

## 🚀 Other Hooks

You can add more hooks to `.githooks/`:

- `pre-commit` - Runs before each commit
- `commit-msg` - Validates commit messages
- `post-checkout` - Runs after checkout
- `pre-rebase` - Runs before rebase

All hooks in `.githooks/` will be automatically used.

---

**Note**: The `.githooks/` directory is tracked in Git, making it easy to share hooks with your team!
