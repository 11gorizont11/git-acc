# git-acc v0.1.0 - Initial Release

## 🎉 Welcome to git-acc!

A lightweight, robust CLI utility for managing multiple Git identities. Perfect for developers who work across different Git accounts for work, personal projects, and open source contributions.

## ✨ Key Features

### 🔀 **Account Management**
- Add, remove, and list Git accounts
- Switch between accounts with a single command
- Automatic `.gitconfig` backup before changes
- Import/export account configurations

### 🎨 **User Experience**
- **Colored output** for better readability:
  - 🔴 Red error messages
  - 🔵 Blue info messages
  - 🟡 Yellow warnings
  - ⚫ Gray verbose output
- **Dry-run mode** to preview changes
- **JSON output** for automation and scripts
- **Interactive mode** with helpful prompts

### 🔐 **Security & Safety**
- SSH key association and management
- Idempotent operations (safe to run multiple times)
- Comprehensive input validation
- Respects `NO_COLOR` environment variable

### 🛠️ **Developer-Friendly**
- Comprehensive test suite (43+ tests)
- Cross-platform compatibility (Linux, macOS)
- Professional documentation
- GitHub Actions CI/CD pipeline

## 📦 Installation

### Quick Install
```bash
curl -L https://github.com/11gorizont11/git-acc/releases/download/v0.1.0/git-acc -o /usr/local/bin/git-acc
chmod +x /usr/local/bin/git-acc
```

### Verify Installation
```bash
git-acc --version
git-acc --help
```

## 🚀 Quick Start

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
```

## 📋 Available Commands

| Command | Description |
|---------|-------------|
| `list` | List all configured accounts |
| `add` | Add a new account (interactive or with flags) |
| `remove` | Remove an account by name |
| `switch` | Switch to an account (updates git config) |
| `status` | Show current git identity |
| `import` | Import accounts from JSON file |
| `export` | Export accounts to JSON |
| `config` | Show configuration |

## 🎯 Use Cases

- **Work/Personal Separation**: Keep your work and personal Git commits properly attributed
- **Multiple Clients**: Freelancers and consultants managing different client identities
- **Open Source Contributions**: Separate identity for open source vs. company work
- **Team Collaboration**: Consistent Git configuration across team members
- **Automated Workflows**: JSON output enables script integration

## 🔧 Advanced Features

### SSH Key Management
```bash
# Add account with SSH key
git-acc add --name "Work" --email "work@example.com" --ssh ~/.ssh/id_work

# Generate SSH key during account creation
git-acc add  # Follow interactive prompts
```

### Automation Support
```bash
# JSON output for scripts
git-acc --json list | jq '.accounts[].name'

# Dry-run mode
git-acc --dry-run switch Work
```

### Import/Export
```bash
# Backup accounts
git-acc export accounts-backup.json

# Restore on new machine
git-acc import accounts-backup.json
```

## 📊 Technical Details

- **Language**: Bash (4.4+)
- **Dependencies**: `git`, `jq`
- **Size**: Single file (~1000 lines)
- **Tests**: 43 comprehensive test cases
- **Platforms**: Linux, macOS, WSL

## 🔒 Security

- No hardcoded secrets or credentials
- SSH keys referenced by path only (never stored)
- Input validation and sanitization
- Follows security best practices for CLI tools

## 📚 Documentation

- [Installation Guide](INSTALL.md) - Detailed installation instructions
- [Contributing Guide](CONTRIBUTING.md) - Development and contribution guidelines
- [README](README.md) - Complete feature documentation

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:
- Development setup
- Code style guidelines
- Testing requirements
- Pull request process

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the need for better Git identity management
- Built with love for the developer community
- Tested extensively for production readiness

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/11gorizont11/git-acc/issues)
- 💡 **Feature Requests**: [GitHub Issues](https://github.com/11gorizont11/git-acc/issues)
- 📖 **Documentation**: [README.md](README.md)

---

**Happy Git account management!** 🎯
