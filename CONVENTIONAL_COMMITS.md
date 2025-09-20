# 📝 Conventional Commits Guide

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automatic semantic versioning and release generation.

## 🎯 **Quick Reference**

| Commit Type | Version Bump | Example |
|-------------|--------------|---------|
| `feat:` | **Minor** (0.1.0 → 0.2.0) | `feat: add SSH key validation` |
| `fix:` | **Patch** (0.1.0 → 0.1.1) | `fix: resolve config file corruption` |
| `docs:` | **Patch** | `docs: update installation guide` |
| `style:` | **Patch** | `style: fix code formatting` |
| `refactor:` | **Patch** | `refactor: improve error handling` |
| `test:` | **Patch** | `test: add integration tests` |
| `chore:` | **Patch** | `chore: update dependencies` |
| `BREAKING CHANGE:` | **Major** (0.1.0 → 1.0.0) | `feat!: redesign CLI interface` |

## 🚀 **Automatic Release Workflow**

Every push to the `main` branch triggers:

1. **Version Calculation** - Based on commit messages since last release
2. **Release Notes Generation** - From commit history
3. **Tag Creation** - Automatic semantic version tag
4. **Release Publication** - GitHub release with artifacts

## ✍️ **Commit Message Format**

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Examples

#### ✅ **Good Examples:**

```bash
# New feature (minor bump)
feat: add colored output support
feat(cli): implement --dry-run flag
feat(ssh): add SSH key generation

# Bug fixes (patch bump)
fix: resolve account switching issue
fix(validation): handle empty email addresses
fix(tests): fix flaky integration test

# Breaking changes (major bump)
feat!: redesign CLI interface with new subcommands
feat(api)!: change account storage format

BREAKING CHANGE: The account storage format has changed.
Existing accounts will need to be re-imported.

# Documentation and maintenance (patch bump)
docs: update README with installation instructions
chore: update dependencies to latest versions
test: add comprehensive validation tests
style: apply consistent code formatting
refactor: improve error handling logic
```

#### ❌ **Avoid These:**

```bash
# Too vague
fix: bug fix
feat: improvements
update stuff

# Missing type
add new feature
resolve issue with accounts

# Wrong type
feat: fix typo in documentation  # should be docs:
fix: add new feature            # should be feat:
```

## 🏷️ **Scope Examples**

Use scopes to indicate what part of the codebase is affected:

- `cli` - Command-line interface changes
- `ssh` - SSH key related functionality
- `config` - Configuration handling
- `validation` - Input validation
- `tests` - Test-related changes
- `docs` - Documentation updates
- `ci` - CI/CD pipeline changes

## 🔄 **Release Types**

### **Patch Release** (0.1.0 → 0.1.1)
- Bug fixes
- Documentation updates
- Code style improvements
- Test additions
- Maintenance tasks

### **Minor Release** (0.1.0 → 0.2.0)
- New features
- New functionality
- Backward-compatible changes

### **Major Release** (0.1.0 → 1.0.0)
- Breaking changes
- API modifications
- Incompatible updates

## 🎯 **Tips for Success**

1. **Be Descriptive**: Explain what the change does, not how
2. **Use Present Tense**: "add feature" not "added feature"
3. **Keep It Short**: First line under 50 characters
4. **Use Body for Details**: Explain complex changes in the body
5. **Reference Issues**: Include `Closes #123` in footer

## 🔍 **Checking Your Commits**

Before pushing, verify your commits follow the convention:

```bash
# View recent commits
git log --oneline -5

# Check if commits will trigger correct version bump
git log v0.1.0..HEAD --oneline --pretty=format:"%s"
```

## 🚀 **What Happens After Push**

1. **CI Runs** - All tests and checks pass
2. **Version Calculated** - Based on commit types
3. **Release Notes Generated** - From commit messages
4. **Tag Created** - New semantic version
5. **Release Published** - GitHub release with artifacts

Your commits directly drive the release process - make them count! 🎉
