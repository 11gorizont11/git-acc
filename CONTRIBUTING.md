# Contributing to git-acc

Thank you for your interest in contributing to git-acc! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Code Style](#code-style)
- [Documentation](#documentation)
- [Release Process](#release-process)

## Code of Conduct

This project follows a simple code of conduct:

- Be respectful and inclusive
- Focus on constructive feedback
- Help create a welcoming environment for all contributors
- No harassment, discrimination, or inappropriate behavior

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Bash 4.4+**
- **Git**
- **jq**
- **ShellCheck** (for linting)
- **Bats** (for testing)

### Installation

```bash
# Ubuntu/Debian
sudo apt-get install git jq shellcheck bats

# macOS
brew install git jq shellcheck bats-core

# Or use our helper
make install-deps-ubuntu  # or install-deps-macos
```

### Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/11gorizont11/git-acc.git
cd git-acc

# Add upstream remote
git remote add upstream https://github.com/11gorizont11/git-acc.git
```

## Development Environment

### Setup Development Environment

```bash
# Set up development environment
make dev-setup

# Install development version (symlinked)
make install-dev

# Verify setup
git-acc --version
make check-deps
```

### Project Structure

```
git-acc/
├── bin/git-acc              # Main executable script
├── lib/git-acc-core.sh      # Core functions library
├── tests/git-acc.bats       # Test suite (Bats framework)
├── .github/workflows/       # CI/CD pipelines
├── Makefile                 # Build and development tasks
├── README.md               # Main documentation
├── INSTALL.md              # Installation guide
├── CONTRIBUTING.md         # This file
├── LICENSE                 # MIT license
└── .shellcheckrc           # ShellCheck configuration
```

### Key Files

- **`bin/git-acc`**: Main CLI script with command parsing and user interface
- **`lib/git-acc-core.sh`**: Reusable functions for account management, validation, etc.
- **`tests/git-acc.bats`**: Comprehensive test suite covering all functionality
- **`Makefile`**: Build system with targets for testing, linting, packaging

## Making Changes

### Development Workflow

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. **Make your changes**:
   - Edit the relevant files
   - Follow the coding standards (see below)
   - Add tests for new functionality

3. **Test your changes**:
   ```bash
   make test           # Run all tests
   make lint           # Check code style
   make validate       # Run all checks
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

### Commit Message Format

We follow conventional commits:

```
<type>: <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Adding or updating tests
- `refactor`: Code refactoring
- `style`: Code style changes (formatting, etc.)
- `ci`: CI/CD changes
- `chore`: Maintenance tasks

**Examples:**
```
feat: add SSH key generation during account creation
fix: handle corrupted JSON configuration files gracefully
docs: update installation instructions for macOS
test: add edge case tests for account switching
```

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run only unit tests
make test-unit

# Run integration tests
make test-integration

# Run specific test
cd tests && bats -f "test name pattern" git-acc.bats
```

### Writing Tests

Tests are written using the [Bats](https://github.com/bats-core/bats-core) framework. Each test should:

1. **Be descriptive**: Test names should clearly describe what's being tested
2. **Be isolated**: Each test should set up its own environment
3. **Test one thing**: Focus on a single behavior or edge case
4. **Clean up**: Use `teardown()` to clean up temporary files

#### Test Structure

```bash
@test "descriptive test name" {
    # Arrange - set up test data
    export XDG_CONFIG_HOME="$(mktemp -d)"

    # Act - perform the action
    run git-acc add --name "Test" --email "test@example.com"

    # Assert - verify the results
    [ "$status" -eq 0 ]
    [[ "$output" == *"Account 'Test' added successfully"* ]]

    # Verify side effects
    run git-acc list
    [[ "$output" == *"Test"* ]]
}
```

#### Test Categories

1. **Unit tests**: Test individual functions and commands
2. **Integration tests**: Test complete workflows
3. **Edge cases**: Test error conditions and boundary cases
4. **Regression tests**: Prevent bugs from reoccurring

### Test Guidelines

- Always test both success and failure cases
- Test with and without `--dry-run`
- Test JSON output where applicable
- Verify file system changes (configs, backups)
- Test with different input formats
- Include tests for error messages

## Code Style

### Bash Style Guidelines

1. **Shebang and safety**:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   IFS=$'\n\t'
   ```

2. **Variable naming**:
   ```bash
   # Use lowercase with underscores
   local user_name="value"
   local config_file="/path/to/file"

   # Constants in uppercase
   readonly VERSION="1.0.0"
   readonly CONFIG_DIR="/etc/myapp"
   ```

3. **Quoting**:
   ```bash
   # Always quote variables
   echo "User: $user_name"
   cp "$source_file" "$dest_file"

   # Quote command substitutions
   local current_date="$(date +%Y-%m-%d)"
   ```

4. **Functions**:
   ```bash
   # Descriptive names with snake_case
   check_dependencies() {
       local missing=()

       if ! command -v git &> /dev/null; then
           missing+=("git")
       fi

       # Return meaningful exit codes
       if [[ ${#missing[@]} -gt 0 ]]; then
           return 1
       fi

       return 0
   }
   ```

5. **Error handling**:
   ```bash
   # Check command success
   if ! git config --global user.name "$name"; then
       log_error "Failed to set git user name"
       return 1
   fi

   # Use meaningful error messages
   log_error "Account '$name' not found. Use 'git-acc list' to see available accounts."
   ```

6. **Output functions**:
   ```bash
   # Use printf over echo
   printf "Message with %s formatting\n" "$variable"

   # Consistent logging
   log_info "Operation completed successfully"
   log_error "Operation failed: $error_message" >&2
   ```

### ShellCheck Compliance

All code must pass ShellCheck without warnings:

```bash
make lint
```

Common ShellCheck rules we follow:
- SC2086: Quote variables to prevent word splitting
- SC2034: Unused variables (remove or prefix with `_`)
- SC2155: Declare and assign separately
- SC2001: Use parameter expansion instead of `sed`

### Code Organization

1. **Separation of concerns**:
   - `bin/git-acc`: CLI interface and command parsing
   - `lib/git-acc-core.sh`: Business logic and utilities

2. **Function ordering**:
   - Helper functions first
   - Command implementations
   - Main execution logic last

3. **Documentation**:
   - Brief comments for complex logic
   - No obvious comments (`# Set user name`)
   - Focus on why, not what

## Documentation

### Updating Documentation

When making changes, update relevant documentation:

1. **Code changes**: Update function comments if behavior changes
2. **New features**: Add to README.md and help text
3. **CLI changes**: Update help output and examples
4. **Installation**: Update INSTALL.md if installation process changes

### Documentation Style

- Use clear, concise language
- Include practical examples
- Maintain consistency with existing docs
- Test all code examples

## Submitting Changes

### Pull Request Process

1. **Ensure quality**:
   ```bash
   make validate       # Run all checks
   make test-integration  # Test built distribution
   ```

2. **Update documentation** as needed

3. **Create pull request**:
   - Use descriptive title following conventional commits
   - Include detailed description of changes
   - Reference any related issues
   - Add screenshots for UI changes (if applicable)

4. **Address feedback**:
   - Respond to review comments
   - Make requested changes
   - Keep commits focused and logical

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Other (please describe)

## Testing
- [ ] Added tests for new functionality
- [ ] All tests pass locally
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
```

### Review Process

All changes go through review:

1. **Automated checks**: CI runs tests and linting
2. **Code review**: Maintainer reviews for:
   - Code quality and style
   - Test coverage
   - Documentation
   - Backward compatibility
3. **Manual testing**: Complex changes get manual verification

## Release Process

### Automated Releases with Semantic Release

This project uses [semantic-release](https://semantic-release.gitbook.io/) for fully automated versioning and releases. The release process is driven by [Conventional Commits](https://www.conventionalcommits.org/) and requires no manual intervention.

### How It Works

1. **Conventional Commits Drive Releases**: Every commit message follows the conventional commit format
2. **Automatic Version Calculation**: semantic-release analyzes commits since the last release to determine the next version
3. **Automatic Release Creation**: When you push to `main`, semantic-release:
   - Calculates the next version based on commit types
   - Generates release notes from commit messages
   - Creates a Git tag
   - Builds and packages artifacts
   - Creates a GitHub release with artifacts
   - Updates the changelog

### Versioning

We use [Semantic Versioning](https://semver.org/) with automatic version bumps:

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes (`feat!:`, `BREAKING CHANGE:`)
- **MINOR** (1.0.0 → 1.1.0): New features (`feat:`)
- **PATCH** (1.0.0 → 1.0.1): Bug fixes (`fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`)

### For Contributors

**No manual release steps required!** Simply:

1. **Follow Conventional Commits**: Use proper commit message format
2. **Push to main**: Releases happen automatically
3. **Check the changelog**: `CHANGELOG.md` is automatically updated

### For Maintainers

The release process is fully automated, but you can:

1. **Monitor releases**: Check GitHub Actions for release status
2. **Review changelog**: Verify `CHANGELOG.md` is accurate
3. **Test locally**: Use `make release-check` to validate before pushing

### Release Artifacts

Each release automatically includes:
- `git-acc` - Standalone binary
- `git-acc.tar.gz` - Tarball package
- `git-acc.sha256` - Binary checksum
- `git-acc.tar.gz.sha256` - Tarball checksum

## Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Questions and general discussion
- **Pull Requests**: Code review and collaboration

### Asking Questions

When asking for help:

1. **Search existing issues** first
2. **Provide context**: OS, version, command used
3. **Include error output** if applicable
4. **Describe expected vs actual behavior**

### Reporting Bugs

Use our bug report template:

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce:
1. Run 'git-acc ...'
2. See error

**Expected behavior**
What you expected to happen.

**Environment:**
- OS: [e.g. Ubuntu 20.04]
- Bash version: [e.g. 5.0]
- git-acc version: [e.g. 0.1.0]

**Additional context**
Any other relevant information.
```

## Recognition

Contributors are recognized in:

- Git commit history
- Release notes for significant contributions
- README.md for major features

Thank you for contributing to git-acc! 🎉
