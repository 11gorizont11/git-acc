.PHONY: build test lint clean install uninstall package help

VERSION := $(shell grep '^VERSION=' bin/git-acc | cut -d'"' -f2)
PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

# Default target
all: build

help: ## Show this help message
	@echo "git-acc Makefile"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build single-file distribution
	@echo "Building git-acc v$(VERSION)..."
	@mkdir -p dist
	@# Create header with shebang and metadata
	@echo '#!/usr/bin/env bash' > dist/git-acc
	@echo '# git-acc - Manage multiple Git identities' >> dist/git-acc
	@echo '# Version: $(VERSION)' >> dist/git-acc
	@echo '# Built: $(shell date -u +"%Y-%m-%d %H:%M:%S UTC")' >> dist/git-acc
	@echo '# Source: https://github.com/alexolexyuk/git-acc' >> dist/git-acc
	@echo '' >> dist/git-acc
	@# Add the core library first (without shebang)
	@tail -n +2 lib/git-acc-core.sh >> dist/git-acc
	@echo '' >> dist/git-acc
	@echo '# === Main Script ===' >> dist/git-acc
	@echo '' >> dist/git-acc
	@# Add main script (without shebang and library sourcing section)
	@sed '1d; /^# Source core functions if available/,/^fi$$/d' bin/git-acc >> dist/git-acc
	@chmod +x dist/git-acc
	@echo "Built dist/git-acc ($(shell wc -l < dist/git-acc) lines)"

test: ## Run all tests
	@echo "Running ShellCheck..."
	@shellcheck bin/git-acc lib/git-acc-core.sh || (echo "ShellCheck failed"; exit 1)
	@echo "Running Bats tests..."
	@cd tests && bats git-acc.bats

test-unit: ## Run unit tests only
	@echo "Running Bats tests..."
	@cd tests && bats git-acc.bats

lint: ## Run linting tools
	@echo "Running ShellCheck on main script..."
	@shellcheck bin/git-acc
	@echo "Running ShellCheck on library..."
	@shellcheck lib/git-acc-core.sh
	@echo "Checking for common issues..."
	@# Check for trailing whitespace
	@if grep -n '[[:space:]]$$' bin/git-acc lib/git-acc-core.sh; then \
		echo "Trailing whitespace found"; exit 1; \
	fi
	@# Check for tabs (we prefer spaces)
	@if grep -n '	' bin/git-acc lib/git-acc-core.sh; then \
		echo "Tabs found (use spaces)"; exit 1; \
	fi
	@echo "Linting passed!"

test-integration: build ## Run integration tests with built distribution
	@echo "Testing built distribution..."
	@export PATH="$$PWD/dist:$$PATH" && \
	export XDG_CONFIG_HOME="$$(mktemp -d)" && \
	git-acc --version && \
	git-acc --help > /dev/null && \
	git-acc list && \
	git-acc add --name "Build-Test" --email "test@build.com" && \
	git-acc switch "Build-Test" && \
	git-acc status && \
	git-acc remove "Build-Test" && \
	echo "Integration tests passed!"

package: build ## Create release package
	@echo "Creating release package..."
	@mkdir -p dist
	@# Create tarball
	@tar -czf dist/git-acc-$(VERSION).tar.gz \
		-C . \
		--transform 's,^,git-acc-$(VERSION)/,' \
		bin/ lib/ tests/ README.md LICENSE INSTALL.md CONTRIBUTING.md Makefile
	@# Create standalone script tarball
	@tar -czf dist/git-acc.tar.gz -C dist git-acc
	@# Generate checksums
	@cd dist && sha256sum git-acc > git-acc.sha256
	@cd dist && sha256sum git-acc-$(VERSION).tar.gz > git-acc-$(VERSION).tar.gz.sha256
	@cd dist && sha256sum git-acc.tar.gz > git-acc.tar.gz.sha256
	@echo "Package created: dist/git-acc-$(VERSION).tar.gz"
	@echo "Standalone: dist/git-acc.tar.gz"
	@echo "Checksums generated"

install: build ## Install to system
	@echo "Installing git-acc to $(BINDIR)..."
	@install -d $(BINDIR)
	@install -m 755 dist/git-acc $(BINDIR)/git-acc
	@echo "Installed git-acc to $(BINDIR)/git-acc"
	@echo "Run 'git-acc --help' to get started"

install-dev: ## Install development version (symlink)
	@echo "Installing development version to $(BINDIR)..."
	@install -d $(BINDIR)
	@ln -sf $(PWD)/bin/git-acc $(BINDIR)/git-acc
	@echo "Development version symlinked to $(BINDIR)/git-acc"

uninstall: ## Uninstall from system
	@echo "Uninstalling git-acc from $(BINDIR)..."
	@rm -f $(BINDIR)/git-acc
	@echo "Uninstalled git-acc"

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf dist/
	@echo "Cleaned!"

check-deps: ## Check for required dependencies
	@echo "Checking dependencies..."
	@command -v shellcheck >/dev/null 2>&1 || (echo "Missing: shellcheck"; exit 1)
	@command -v bats >/dev/null 2>&1 || (echo "Missing: bats"; exit 1)
	@command -v jq >/dev/null 2>&1 || (echo "Missing: jq"; exit 1)
	@command -v git >/dev/null 2>&1 || (echo "Missing: git"; exit 1)
	@echo "All dependencies found!"

check-security: ## Run security checks
	@echo "Running security checks..."
	@# Check for hardcoded secrets
	@if grep -r -E "(password|secret|key|token)" --include="*.sh" . | grep -v -E "(SSH|ssh_key|key_path|ssh-keygen|password.*::|test|example|GITHUB_TOKEN|function.*key|local.*key|public_key|private_key|validate_ssh_key|generate_ssh_key|get_ssh_public_key|ssh.*key|key.*ssh|export.*key)"; then \
		echo "Potential hardcoded secrets found!"; exit 1; \
	fi
	@# Check file permissions
	@find . -name "*.sh" -perm +002 2>/dev/null | grep . && (echo "World-writable scripts found!"; exit 1) || true
	@# Check for dangerous patterns
	@if grep -r "curl.*|.*sh" --include="*.sh" .; then \
		echo "Dangerous curl|sh pattern found!"; exit 1; \
	fi
	@echo "Security checks passed!"

format: ## Format shell scripts (requires shfmt)
	@if command -v shfmt >/dev/null 2>&1; then \
		echo "Formatting shell scripts..."; \
		shfmt -w -i 4 bin/git-acc lib/git-acc-core.sh; \
		echo "Formatted!"; \
	else \
		echo "shfmt not found, skipping formatting"; \
	fi

validate: lint test check-security ## Run all validation checks

release-check: validate package ## Validate everything is ready for release
	@echo "Performing release checks..."
	@# Check version consistency
	@if ! grep -q "$(VERSION)" README.md; then \
		echo "Version $(VERSION) not found in README.md"; exit 1; \
	fi
	@# Verify built script works
	@./dist/git-acc --version | grep -q "$(VERSION)" || (echo "Version mismatch in built script"; exit 1)
	@# Check that all files are present
	@test -f dist/git-acc || (echo "Missing dist/git-acc"; exit 1)
	@test -f dist/git-acc.tar.gz || (echo "Missing dist/git-acc.tar.gz"; exit 1)
	@test -f dist/git-acc.sha256 || (echo "Missing dist/git-acc.sha256"; exit 1)
	@echo "Release checks passed! Ready to release v$(VERSION)"

dev-setup: ## Set up development environment
	@echo "Setting up development environment..."
	@# Install git hooks
	@mkdir -p .git/hooks
	@echo '#!/bin/bash' > .git/hooks/pre-commit
	@echo 'make lint' >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Pre-commit hook installed"
	@echo "Run 'make check-deps' to verify dependencies"

demo: build ## Run a quick demo of the tool
	@echo "Running git-acc demo..."
	@export PATH="$$PWD/dist:$$PATH" && \
	export XDG_CONFIG_HOME="$$(mktemp -d)" && \
	echo "=== Version ===" && \
	git-acc --version && \
	echo -e "\n=== Help ===" && \
	git-acc --help | head -10 && \
	echo -e "\n=== Empty list ===" && \
	git-acc list && \
	echo -e "\n=== Adding accounts ===" && \
	git-acc add --name "Demo-Work" --email "work@demo.com" && \
	git-acc add --name "Demo-Personal" --email "personal@demo.com" && \
	echo -e "\n=== List with accounts ===" && \
	git-acc list && \
	echo -e "\n=== Switch account ===" && \
	git-acc switch "Demo-Work" && \
	echo -e "\n=== Status ===" && \
	git-acc status && \
	echo -e "\n=== JSON output ===" && \
	git-acc --json list | jq . && \
	echo -e "\nDemo completed!"

install-deps-ubuntu: ## Install dependencies on Ubuntu/Debian
	@echo "Installing dependencies for Ubuntu/Debian..."
	@sudo apt-get update
	@sudo apt-get install -y shellcheck bats jq git

install-deps-macos: ## Install dependencies on macOS
	@echo "Installing dependencies for macOS..."
	@brew install shellcheck bats-core jq git

watch-test: ## Watch files and run tests on changes (requires inotifywait)
	@if command -v inotifywait >/dev/null 2>&1; then \
		echo "Watching for changes... (Press Ctrl+C to stop)"; \
		while true; do \
			inotifywait -q -e modify bin/ lib/ tests/ && \
			echo "Files changed, running tests..." && \
			make test || true && \
			echo "Waiting for changes..."; \
		done; \
	else \
		echo "inotifywait not found. Install inotify-tools package."; \
	fi

# Development shortcuts
dev: install-dev ## Alias for install-dev
quick-test: lint test-unit ## Quick test (lint + unit tests only)
ci: validate test-integration ## Run CI-like checks locally
