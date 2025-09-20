# Installation Guide

This guide covers various ways to install `git-acc` on different systems.

## Quick Install (Recommended)

### One-liner for most systems
```bash
curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc -o /usr/local/bin/git-acc && chmod +x /usr/local/bin/git-acc
```

### Verify installation
```bash
git-acc --version
git-acc --help
```

## Installation Methods

### Method 1: Direct Download

Download the latest release directly from GitHub:

```bash
# Download to /usr/local/bin (requires sudo on most systems)
sudo curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc -o /usr/local/bin/git-acc
sudo chmod +x /usr/local/bin/git-acc

# Or download to user directory (no sudo required)
mkdir -p ~/bin
curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc -o ~/bin/git-acc
chmod +x ~/bin/git-acc

# Add ~/bin to PATH if not already there
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Method 2: Using git-acc's built-in installer

```bash
# Download and run the installer
curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc -o git-acc
chmod +x git-acc
sudo ./git-acc install

# Or install to user directory
./git-acc install --prefix=$HOME
```

### Method 3: From Source

```bash
# Clone the repository
git clone https://github.com/11gorizont11/git-acc.git
cd git-acc

# Install dependencies (see dependencies section below)
make check-deps

# Build and install
make build
sudo make install

# Or install to user directory
make build
make install PREFIX=$HOME
```

### Method 4: Using Make

If you have the source code:

```bash
# System-wide installation
sudo make install

# User installation
make install PREFIX=$HOME

# Development installation (symlink)
make install-dev
```

## Dependencies

Before installing, ensure you have the required dependencies:

### Required Dependencies
- `bash` (version 4.4 or later)
- `git`
- `jq`

### Installing Dependencies

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install git jq

# For development/building from source
sudo apt-get install shellcheck bats
```

#### CentOS/RHEL/Fedora
```bash
# CentOS/RHEL 7-8
sudo yum install git jq

# CentOS/RHEL 9+ / Fedora
sudo dnf install git jq

# For development
sudo dnf install ShellCheck bats
```

#### macOS
```bash
# Using Homebrew
brew install git jq

# For development
brew install shellcheck bats-core
```

#### Alpine Linux
```bash
apk add git jq bash

# For development
apk add shellcheck bats
```

#### Arch Linux
```bash
sudo pacman -S git jq

# For development
sudo pacman -S shellcheck bats
```

## Platform-Specific Instructions

### Linux

#### System-wide installation
```bash
sudo curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc -o /usr/local/bin/git-acc
sudo chmod +x /usr/local/bin/git-acc
```

#### User installation
```bash
mkdir -p ~/.local/bin
curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc -o ~/.local/bin/git-acc
chmod +x ~/.local/bin/git-acc

# Ensure ~/.local/bin is in PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### macOS

#### Using Homebrew (if available)
```bash
# Note: This would require creating a Homebrew formula
# For now, use direct download method
```

#### Direct installation
```bash
# System-wide
sudo curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc -o /usr/local/bin/git-acc
sudo chmod +x /usr/local/bin/git-acc

# User installation
mkdir -p ~/bin
curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc -o ~/bin/git-acc
chmod +x ~/bin/git-acc

# Add to PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc  # or ~/.bash_profile
source ~/.zshrc
```

### Windows (WSL/Git Bash)

#### Windows Subsystem for Linux (WSL)
Follow the Linux installation instructions within your WSL environment.

#### Git Bash
```bash
# Download to a directory in PATH
curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc -o /usr/bin/git-acc
chmod +x /usr/bin/git-acc
```

## Docker Installation

### Using Docker
```bash
# Create a Docker image
cat > Dockerfile << 'EOF'
FROM alpine:latest
RUN apk add --no-cache bash git jq curl
RUN curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc -o /usr/local/bin/git-acc && \
    chmod +x /usr/local/bin/git-acc
ENTRYPOINT ["git-acc"]
EOF

docker build -t git-acc .

# Use as an alias
alias git-acc='docker run --rm -v $HOME/.gitconfig:/root/.gitconfig -v $HOME/.config:/root/.config git-acc'
```

## Package Managers

### Future Plans

We plan to support the following package managers in future releases:

- **Homebrew**: `brew install alexolexyuk/tap/git-acc`
- **Snap**: `sudo snap install git-acc`
- **AUR (Arch)**: `yay -S git-acc`
- **APT Repository**: `sudo apt install git-acc`

## Verification

### Verify Installation
```bash
# Check version
git-acc --version

# Check help
git-acc --help

# Test basic functionality
git-acc list  # Should show "No accounts configured"
```

### Verify Checksum (Recommended)
```bash
# Download checksum file
curl -L https://github.com/11gorizont11/git-acc/releases/latest/download/git-acc.sha256 -o git-acc.sha256

# Verify downloaded file
sha256sum -c git-acc.sha256
```

## Post-Installation Setup

### 1. Initialize Configuration
```bash
# Create first account
git-acc add --name "Default" --email "your@email.com"
```

### 2. Set up Shell Completion (Optional)

#### Bash
```bash
# Add to ~/.bashrc
cat >> ~/.bashrc << 'EOF'
# git-acc completion
_git_acc_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case ${prev} in
        git-acc)
            opts="list add remove switch status import export config install uninstall --help --version --verbose --dry-run --json"
            ;;
        switch|remove)
            opts="$(git-acc --json list 2>/dev/null | jq -r '.accounts[].name' 2>/dev/null)"
            ;;
        *)
            return 0
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}
complete -F _git_acc_completion git-acc
EOF

source ~/.bashrc
```

#### Zsh
```bash
# Add to ~/.zshrc
cat >> ~/.zshrc << 'EOF'
# git-acc completion
_git_acc() {
    local state
    _arguments \
        '1: :->commands' \
        '*: :->args' \
        && return 0

    case $state in
        commands)
            _values 'commands' \
                'list[List accounts]' \
                'add[Add account]' \
                'remove[Remove account]' \
                'switch[Switch account]' \
                'status[Show status]' \
                'import[Import accounts]' \
                'export[Export accounts]' \
                'config[Show config]' \
                'install[Install to system]' \
                'uninstall[Uninstall from system]'
            ;;
        args)
            case $words[2] in
                switch|remove)
                    local accounts
                    accounts=($(git-acc --json list 2>/dev/null | jq -r '.accounts[].name' 2>/dev/null))
                    _values 'accounts' $accounts
                    ;;
            esac
            ;;
    esac
}
compdef _git_acc git-acc
EOF

source ~/.zshrc
```

## Uninstallation

### Remove the binary
```bash
# If installed system-wide
sudo rm /usr/local/bin/git-acc

# If installed in user directory
rm ~/bin/git-acc
# or
rm ~/.local/bin/git-acc

# Using git-acc's built-in uninstaller
git-acc uninstall
```

### Remove configuration (optional)
```bash
# Remove all configuration and accounts
rm -rf ~/.config/git-acc

# Remove any git config backups (optional)
rm ~/.gitconfig.bak.*
```

## Troubleshooting Installation

### Permission Denied
```bash
# If you get permission denied during installation:
sudo chown $(whoami) /usr/local/bin
# or install to user directory instead
```

### Command Not Found
```bash
# Check if installation directory is in PATH
echo $PATH

# Add to PATH if needed
export PATH="/usr/local/bin:$PATH"

# Make permanent by adding to shell rc file
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
```

### Dependencies Missing
```bash
# Check for missing dependencies
which git jq bash

# Install missing dependencies using your system's package manager
```

### Version Mismatch
```bash
# If git-acc --version shows old version:
which git-acc  # Check which version is being found
hash -r        # Refresh bash's command cache
```

### WSL Issues
```bash
# In WSL, ensure you have the required packages
sudo apt-get update
sudo apt-get install git jq

# Check that you're using bash, not sh
echo $SHELL
```

## Development Installation

For development and contributing:

```bash
# Clone and set up development environment
git clone https://github.com/11gorizont11/git-acc.git
cd git-acc

# Install development dependencies
make install-deps-ubuntu  # or install-deps-macos

# Set up development environment
make dev-setup

# Install development version (symlink)
make install-dev

# Run tests
make test
```

## Security Considerations

- Always verify checksums when downloading releases
- Review the script before installation if security is a concern
- The script only modifies git configuration and creates config files in your home directory
- No network requests are made during normal operation
- SSH keys are referenced by path only, never stored or transmitted

## Support

If you encounter installation issues:

1. Check this guide for troubleshooting steps
2. Ensure all dependencies are installed
3. Try the alternative installation methods
4. Open an issue on GitHub with:
   - Your operating system and version
   - Error messages
   - Output of `which git jq bash`
