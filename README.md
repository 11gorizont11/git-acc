# git-acc

[![CI](https://github.com/11gorizont11/git-acc/actions/workflows/ci.yml/badge.svg)](https://github.com/11gorizont11/git-acc/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

A lightweight, robust CLI utility for managing multiple Git identities. Easily switch between different Git accounts for work, personal projects, and open source contributions.

## Features

- 🔀 **Easy Switching**: Switch between Git identities with a single command
- 💾 **Safe Backups**: Automatically backs up your `.gitconfig` before changes
- 🔑 **SSH Key Management**: Optional SSH key association with accounts
- 📄 **Import/Export**: Share account configurations across machines
- 🛡️ **Dry Run Mode**: Preview changes before applying them
- 📊 **JSON Output**: Machine-readable output for automation
- 🎨 **Colored Output**: Beautiful colored logs (red errors, blue info, yellow warnings)
- ✅ **Idempotent**: Safe to run multiple times
- 🧪 **Well Tested**: Comprehensive test suite with 40+ test cases

## Quick Start

### Installation

#### Direct download (recommended)
```bash
curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc -o /usr/local/bin/git-acc
chmod +x /usr/local/bin/git-acc
```

#### Verify installation
```bash
git-acc --version
```

#### From source
```bash
git clone https://github.com/11gorizont11/git-acc.git
cd git-acc
make install
```

### Basic Usage

```bash
# Add your work account
git-acc add --name "Work" --email "you@company.com"

# Add your personal account
git-acc add --name "Personal" --email "you@personal.com"

# List all accounts
git-acc list

# Switch to work account
git-acc switch Work

# Check current status
git-acc status

# Switch to personal account
git-acc switch Personal
```

## Usage

### Global Options

```
-h, --help        Show help message
-V, --version     Print version and exit
-v, --verbose     Enable verbose output
    --dry-run     Show what would be done without executing
    --json        Output in JSON format (where applicable)
```

### Commands

#### `list` - List all accounts
```bash
git-acc list                    # Human-readable format
git-acc --json list            # JSON format
```

#### `add` - Add a new account
```bash
# Interactive mode
git-acc add

# With flags
git-acc add --name "Work" --email "you@company.com"

# With SSH key
git-acc add --name "Work" --email "you@company.com" --ssh ~/.ssh/id_ed25519_work
```

#### `switch` - Switch to an account
```bash
git-acc switch Work
git-acc --dry-run switch Work   # Preview changes
```

#### `remove` - Remove an account
```bash
git-acc remove Work
git-acc --dry-run remove Work   # Preview changes
```

#### `status` - Show current Git identity
```bash
git-acc status                  # Human-readable format
git-acc --json status          # JSON format
```

#### `reset` - Reset Git config to match active account
```bash
git-acc reset                  # Sync Git config with active account
git-acc --dry-run reset        # Preview changes
```

#### `import/export` - Backup and restore accounts
```bash
# Export accounts
git-acc export accounts.json

# Import accounts
git-acc import accounts.json

# Export to stdout
git-acc export | jq .
```

#### `config` - Show configuration
```bash
git-acc config
```

#### `install/uninstall` - System installation
```bash
git-acc install     # Copy to /usr/local/bin
git-acc uninstall   # Remove from /usr/local/bin
```

## Examples

### Complete Workflow
```bash
# Set up accounts
git-acc add --name "Work" --email "jane@company.com" --ssh ~/.ssh/id_ed25519_work
git-acc add --name "Personal" --email "jane@example.com" --ssh ~/.ssh/id_ed25519_personal
git-acc add --name "OpenSource" --email "jane@contributors.org"

# Work on company project
git-acc switch Work
git clone git@github.com:company/project.git
cd project
# ... work on project ...
git commit -m "Add new feature"  # Commits as jane@company.com

# Switch to personal for side project
git-acc switch Personal
git clone git@github.com:jane/personal-project.git
cd personal-project
# ... work on project ...
git commit -m "Fix bug"  # Commits as jane@example.com

# Check what accounts you have
git-acc list
# Output:
# Configured accounts:
#
#   Work                 jane@company.com          ~/.ssh/id_ed25519_work *
#   Personal             jane@example.com          ~/.ssh/id_ed25519_personal
#   OpenSource           jane@contributors.org     no SSH key
#
# * Currently active account
```

### Backup and Restore
```bash
# Backup accounts before system reinstall
git-acc export ~/accounts-backup.json

# After reinstall, restore accounts
git-acc import ~/accounts-backup.json
git-acc list  # Verify accounts restored
```

### Automation and Scripting
```bash
# Get current account in JSON for scripts
current_account=$(git-acc --json status | jq -r '.active_account')

# List all account names for iteration
git-acc --json list | jq -r '.accounts[].name' | while read -r account; do
    echo "Account: $account"
done

# Dry run to see what would change
git-acc --dry-run switch Work
```

### SSH Key Management
```bash
# Add account and generate SSH key interactively
git-acc add
# Enter name: Work
# Enter email: you@company.com
# SSH key path: (press Enter)
# Generate new SSH key? y
# SSH key generated at ~/.ssh/id_ed25519_work

# Show generated public key
cat ~/.ssh/id_ed25519_work.pub
# Copy this to your Git provider (GitHub, GitLab, etc.)
```

### Account Names with Spaces

Account names can contain spaces and work with both quoted and unquoted syntax:

```bash
# Add account with spaces
git-acc add --name "John Doe" --email "john@example.com"

# Switch using quoted syntax
git-acc switch "John Doe"

# Switch using unquoted syntax (also works!)
git-acc switch John Doe

# Remove using either syntax
git-acc remove "John Doe"
git-acc remove John Doe
```

## Configuration

Configuration is stored in `${XDG_CONFIG_HOME:-$HOME/.config}/git-acc/`:

- `accounts.json` - Account definitions and active account
- `config.json` - Tool configuration

### Color Output

By default, `git-acc` displays colored output for better readability:

- 🔴 **Red**: Error messages
- 🔵 **Blue**: Info messages
- 🟡 **Yellow**: Warning messages
- ⚫ **Gray**: Verbose messages
- 🟢 **Green**: Success messages

#### Disabling Colors

Colors are automatically disabled when:
- Output is redirected to a file or pipe
- The `NO_COLOR` environment variable is set
- Running in a non-terminal environment

To disable colors manually:
```bash
export NO_COLOR=1
git-acc list  # Will show plain text output
```

### Account File Format
```json
{
  "accounts": [
    {
      "name": "Work",
      "email": "you@company.com",
      "ssh_key": "/home/user/.ssh/id_ed25519_work"
    },
    {
      "name": "Personal",
      "email": "you@personal.com",
      "ssh_key": null
    }
  ],
  "active": "Work"
}
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0    | Success |
| 1    | General error |
| 2    | Invalid usage/arguments |
| 3    | Missing dependency |
| 4    | Account not found |
| 5    | File operation error |

## Dependencies

- `bash` (4.4+)
- `git`
- `jq`

### Installing Dependencies

#### Ubuntu/Debian
```bash
sudo apt-get install git jq
```

#### macOS
```bash
brew install git jq
```

#### CentOS/RHEL/Fedora
```bash
sudo yum install git jq     # CentOS/RHEL
sudo dnf install git jq     # Fedora
```

## Development

### Building from Source
```bash
git clone https://github.com/11gorizont11/git-acc.git
cd git-acc

# Install development dependencies
make install-deps-ubuntu  # or install-deps-macos

# Run tests
make test

# Build distribution
make build

# Install development version
make install-dev
```

### Running Tests
```bash
# All tests
make test

# Just unit tests
make test-unit

# Integration tests
make test-integration

# Linting
make lint

# All checks
make validate
```

### Project Structure
```
git-acc/
├── bin/git-acc              # Main executable
├── lib/git-acc-core.sh      # Core functions library
├── tests/git-acc.bats       # Test suite
├── .github/workflows/       # CI/CD
├── Makefile                 # Build system
├── README.md               # This file
├── INSTALL.md              # Installation guide
├── CONTRIBUTING.md         # Development guide
└── LICENSE                 # MIT license
```

## Security

- Account data stored in user config directory with appropriate permissions
- Git config backups created before changes
- SSH keys referenced by path only (never stored or logged)
- No secrets transmitted or stored in plain text
- Dry run mode for safe previewing of changes

## Troubleshooting

### Common Issues

**"Missing required dependencies"**
```bash
# Install missing dependencies
sudo apt-get install git jq  # Ubuntu/Debian
brew install git jq           # macOS
```

**"Account not found"**
```bash
# List accounts to check spelling
git-acc list
```

**"Cannot write to /usr/local/bin"**
```bash
# Use sudo for system installation
sudo git-acc install
```

**"SSH key not working after switch"**
```bash
# Check SSH agent
ssh-add -l

# Add key to agent
ssh-add ~/.ssh/id_ed25519_work
```

### Debug Mode
```bash
# Enable verbose output
git-acc --verbose switch Work

# Test with dry run
git-acc --dry-run switch Work
```

### Backup Recovery
```bash
# Find git config backups
ls ~/.gitconfig.bak.*

# Restore from backup if needed
cp ~/.gitconfig.bak.20231201_143022 ~/.gitconfig
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### 🚀 Automatic Releases

This project uses **automatic semantic versioning** based on [Conventional Commits](CONVENTIONAL_COMMITS.md):

- Every push to `main` automatically creates a new release
- Version bumps are determined by commit message types:
  - `feat:` → Minor version (0.1.0 → 0.2.0)
  - `fix:` → Patch version (0.1.0 → 0.1.1)
  - `feat!:` → Major version (0.1.0 → 1.0.0)
- Release notes are generated from commit messages

**📖 [Read the Conventional Commits Guide](CONVENTIONAL_COMMITS.md)** for proper commit formatting.

### Quick Contribution Guide
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Use conventional commit messages (see [CONVENTIONAL_COMMITS.md](CONVENTIONAL_COMMITS.md))
5. Ensure all tests pass: `make validate`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

### v0.1.0 (Initial Release)
- ✅ Account management (add, remove, list, switch)
- ✅ Git config integration with automatic backups
- ✅ SSH key association and management
- ✅ Import/export functionality
- ✅ JSON output mode for automation
- ✅ Comprehensive dry-run support
- ✅ Extensive test suite (40+ tests)
- ✅ Cross-platform compatibility (Linux, macOS)
- ✅ CI/CD with GitHub Actions

## Support

- 📖 **Documentation**: This README and [INSTALL.md](INSTALL.md)
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/11gorizont11/git-acc/issues)
- 💡 **Feature Requests**: [GitHub Issues](https://github.com/11gorizont11/git-acc/issues)
- 🧪 **Development**: [CONTRIBUTING.md](CONTRIBUTING.md)

---

**Made with ❤️ by [Alex Olexyuk](https://github.com/alexolexyuk)**
