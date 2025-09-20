#!/usr/bin/env bats

# Test setup and teardown
setup() {
    # Create temporary directories for testing
    export TEST_HOME="$(mktemp -d)"
    export HOME="${TEST_HOME}"
    export XDG_CONFIG_HOME="${TEST_HOME}/.config"

    # Set up test environment
    mkdir -p "${XDG_CONFIG_HOME}/git-acc"

    # Create a temporary git config
    export GIT_CONFIG_GLOBAL="${TEST_HOME}/.gitconfig"
    touch "${GIT_CONFIG_GLOBAL}"

    # Add our binary to PATH (handle different test running locations)
    if [[ -f "${PWD}/bin/git-acc" ]]; then
        export PATH="${PWD}/bin:${PATH}"
    elif [[ -f "${PWD}/../bin/git-acc" ]]; then
        export PATH="${PWD}/../bin:${PATH}"
    else
        echo "Error: Cannot find git-acc binary" >&2
        return 1
    fi

    # Create initial git config
    git config --global user.name "Test User"
    git config --global user.email "test@example.com"
}

teardown() {
    # Clean up temporary directories
    rm -rf "${TEST_HOME}"
}

# Helper functions
create_test_account() {
    local name="$1"
    local email="$2"
    local ssh_key="${3:-}"

    if [[ -n "${ssh_key}" ]]; then
        run git-acc add --name "${name}" --email "${email}" --ssh "${ssh_key}"
    else
        run git-acc add --name "${name}" --email "${email}"
    fi
}

# Basic functionality tests
@test "git-acc shows help when no command given" {
    run git-acc
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"No command specified"* ]]
}

@test "git-acc --help shows help message" {
    run git-acc --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Manage multiple Git identities"* ]]
    [[ "${output}" == *"Usage:"* ]]
    [[ "${output}" == *"Commands:"* ]]
    [[ "${output}" == *"Examples:"* ]]
}

@test "git-acc --version shows version" {
    run git-acc --version
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"git-acc 0.1.0"* ]]
}

@test "git-acc handles unknown command" {
    run git-acc invalid-command
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Unknown command: invalid-command"* ]]
}

@test "git-acc handles unknown global flag" {
    run git-acc --invalid-flag list
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Unknown option: --invalid-flag"* ]]
}

# List command tests
@test "list shows no accounts when empty" {
    run git-acc list
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"No accounts configured."* ]]
    [[ "${output}" == *"Use 'git-acc add' to add your first account."* ]]
}

@test "list shows accounts after adding some" {
    create_test_account "Work" "work@company.com"
    create_test_account "Personal" "me@personal.com"

    run git-acc list
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Work"* ]]
    [[ "${output}" == *"work@company.com"* ]]
    [[ "${output}" == *"Personal"* ]]
    [[ "${output}" == *"me@personal.com"* ]]
}

@test "list --json returns valid JSON" {
    create_test_account "Work" "work@company.com"

    run git-acc --json list
    [ "${status}" -eq 0 ]

    # Validate JSON structure
    echo "${output}" | jq empty
    echo "${output}" | jq -e '.accounts[0].name == "Work"'
    echo "${output}" | jq -e '.accounts[0].email == "work@company.com"'
}

# Add command tests
@test "add requires name and email" {
    run git-acc add
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Account name and email are required"* ]]
}

@test "add with invalid email fails" {
    run git-acc add --name "Test" --email "invalid-email"
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Invalid email format"* ]]
}

@test "add creates account successfully" {
    run git-acc add --name "Work" --email "work@company.com"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Account 'Work' added successfully"* ]]

    # Verify account was created
    run git-acc list
    [[ "${output}" == *"Work"* ]]
    [[ "${output}" == *"work@company.com"* ]]
}

@test "add prevents duplicate account names" {
    create_test_account "Work" "work@company.com"

    run git-acc add --name "Work" --email "another@company.com"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Account 'Work' already exists"* ]]
}

@test "add with SSH key validates file exists" {
    run git-acc add --name "Test" --email "test@example.com" --ssh "/nonexistent/key"
    [ "${status}" -eq 5 ]
    [[ "${output}" == *"SSH key file not found"* ]]
}

@test "add --dry-run shows what would be done" {
    run git-acc --dry-run add --name "Test" --email "test@example.com"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"[DRY-RUN] Would add account"* ]]

    # Verify account wasn't actually created
    run git-acc list
    [[ "${output}" == *"No accounts configured"* ]]
}

# Remove command tests
@test "remove requires account name" {
    run git-acc remove
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Account name required"* ]]
}

@test "remove non-existent account fails" {
    run git-acc remove "NonExistent"
    [ "${status}" -eq 4 ]
    [[ "${output}" == *"Account 'NonExistent' not found"* ]]
}

@test "remove existing account succeeds" {
    create_test_account "Work" "work@company.com"

    # Non-interactive removal (simulate 'y' response)
    run git-acc remove "Work" <<< "y"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Account 'Work' removed successfully"* ]]

    # Verify account was removed
    run git-acc list
    [[ "${output}" == *"No accounts configured"* ]]
}

@test "remove --dry-run shows what would be done" {
    create_test_account "Work" "work@company.com"

    run git-acc --dry-run remove "Work"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"[DRY-RUN] Would remove account: Work"* ]]

    # Verify account wasn't actually removed
    run git-acc list
    [[ "${output}" == *"Work"* ]]
}

# Switch command tests
@test "switch requires account name" {
    run git-acc switch
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Account name required"* ]]
}

@test "switch to non-existent account fails" {
    run git-acc switch "NonExistent"
    [ "${status}" -eq 4 ]
    [[ "${output}" == *"Account 'NonExistent' not found"* ]]
}

@test "switch to existing account succeeds" {
    create_test_account "Work" "work@company.com"

    run git-acc switch "Work"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Switched to account 'Work' <work@company.com>"* ]]

    # Verify git config was updated
    name=$(git config --global user.name)
    email=$(git config --global user.email)
    [ "${name}" = "Work" ]
    [ "${email}" = "work@company.com" ]
}

@test "switch creates backup of git config" {
    create_test_account "Work" "work@company.com"

    # Create initial git config
    git config --global user.name "Original User"
    git config --global user.email "original@example.com"

    run git-acc switch "Work"
    [ "${status}" -eq 0 ]

    # Check that backup was created
    backup_files=("${HOME}"/.gitconfig.bak.*)
    [ -f "${backup_files[0]}" ]
}

@test "switch to already active account is idempotent" {
    create_test_account "Work" "work@company.com"

    # Switch once
    git-acc switch "Work"

    # Switch again
    run git-acc switch "Work"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Account 'Work' is already active"* ]]
}

@test "switch --dry-run shows what would be done" {
    create_test_account "Work" "work@company.com"

    # Store original values
    original_name=$(git config --global user.name)
    original_email=$(git config --global user.email)

    run git-acc --dry-run switch "Work"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"[DRY-RUN]"* ]]

    # Verify git config wasn't changed
    current_name=$(git config --global user.name)
    current_email=$(git config --global user.email)
    [ "${current_name}" = "${original_name}" ]
    [ "${current_email}" = "${original_email}" ]
}

# Status command tests
@test "status shows current git identity" {
    git config --global user.name "Test User"
    git config --global user.email "test@example.com"

    run git-acc status
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Test User"* ]]
    [[ "${output}" == *"test@example.com"* ]]
    [[ "${output}" == *"Active account: none"* ]]
}

@test "status shows active account after switch" {
    create_test_account "Work" "work@company.com"
    git-acc switch "Work"

    run git-acc status
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Work"* ]]
    [[ "${output}" == *"work@company.com"* ]]
    [[ "${output}" == *"Active account: Work"* ]]
}

@test "status --json returns valid JSON" {
    git config --global user.name "Test User"
    git config --global user.email "test@example.com"

    run git-acc --json status
    [ "${status}" -eq 0 ]

    # Validate JSON structure
    echo "${output}" | jq empty
    echo "${output}" | jq -e '.current_git_identity.name == "Test User"'
    echo "${output}" | jq -e '.current_git_identity.email == "test@example.com"'
}

# Import/Export tests
@test "export outputs JSON to stdout" {
    create_test_account "Work" "work@company.com"

    run git-acc export
    [ "${status}" -eq 0 ]

    # Validate JSON output
    echo "${output}" | jq empty
    echo "${output}" | jq -e '.accounts[0].name == "Work"'
}

@test "export to file writes JSON file" {
    create_test_account "Work" "work@company.com"
    local export_file="${TEST_HOME}/export.json"

    run git-acc export "${export_file}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Accounts exported to ${export_file}"* ]]

    # Verify file was created and contains valid JSON
    [ -f "${export_file}" ]
    cat "${export_file}" | jq empty
}

@test "import requires file argument" {
    run git-acc import
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Import file required"* ]]
}

@test "import non-existent file fails" {
    run git-acc import "/nonexistent/file.json"
    [ "${status}" -eq 5 ]
    [[ "${output}" == *"Import file not found"* ]]
}

@test "import valid JSON file succeeds" {
    # Create test import file
    local import_file="${TEST_HOME}/import.json"
    cat > "${import_file}" <<EOF
{
  "accounts": [
    {"name": "Imported", "email": "imported@example.com", "ssh_key": null}
  ],
  "active": null
}
EOF

    run git-acc import "${import_file}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Imported 1 accounts"* ]]

    # Verify account was imported
    run git-acc list
    [[ "${output}" == *"Imported"* ]]
    [[ "${output}" == *"imported@example.com"* ]]
}

@test "import creates backup of existing accounts" {
    create_test_account "Original" "original@example.com"

    # Create test import file
    local import_file="${TEST_HOME}/import.json"
    cat > "${import_file}" <<EOF
{
  "accounts": [
    {"name": "Imported", "email": "imported@example.com", "ssh_key": null}
  ],
  "active": null
}
EOF

    run git-acc import "${import_file}"
    [ "${status}" -eq 0 ]

    # Check that backup was created
    backup_files=("${XDG_CONFIG_HOME}/git-acc/accounts.json.bak."*)
    [ -f "${backup_files[0]}" ]
}

# Verbose flag tests
@test "verbose flag shows additional output" {
    create_test_account "Work" "work@company.com"

    run git-acc --verbose switch "Work"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"[VERBOSE]"* ]]
}

# Config command tests
@test "config shows current configuration" {
    run git-acc config
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Current configuration:"* ]]
    [[ "${output}" == *"backup_gitconfig: true"* ]]
    [[ "${output}" == *"ssh_management: true"* ]]
}

# Integration tests
@test "full workflow: add, switch, status, remove" {
    # Add account
    run git-acc add --name "TestFlow" --email "test@flow.com"
    [ "${status}" -eq 0 ]

    # List to verify
    run git-acc list
    [[ "${output}" == *"TestFlow"* ]]

    # Switch to account
    run git-acc switch "TestFlow"
    [ "${status}" -eq 0 ]

    # Check status
    run git-acc status
    [[ "${output}" == *"TestFlow"* ]]
    [[ "${output}" == *"test@flow.com"* ]]
    [[ "${output}" == *"Active account: TestFlow"* ]]

    # Remove account
    run git-acc remove "TestFlow" <<< "y"
    [ "${status}" -eq 0 ]

    # Verify removal
    run git-acc list
    [[ "${output}" == *"No accounts configured"* ]]
}

@test "multiple accounts workflow" {
    # Add multiple accounts
    create_test_account "Work" "work@company.com"
    create_test_account "Personal" "me@personal.com"
    create_test_account "OpenSource" "me@opensource.org"

    # List all accounts
    run git-acc list
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Work"* ]]
    [[ "${output}" == *"Personal"* ]]
    [[ "${output}" == *"OpenSource"* ]]

    # Switch between accounts
    git-acc switch "Work"
    name=$(git config --global user.name)
    email=$(git config --global user.email)
    [ "${name}" = "Work" ]
    [ "${email}" = "work@company.com" ]

    git-acc switch "Personal"
    name=$(git config --global user.name)
    email=$(git config --global user.email)
    [ "${name}" = "Personal" ]
    [ "${email}" = "me@personal.com" ]

    # Check status shows correct active account
    run git-acc status
    [[ "${output}" == *"Active account: Personal"* ]]
}

# Error handling tests
@test "handles missing jq dependency gracefully" {
    # This test would require mocking or temporarily removing jq
    # For now, we'll skip it as it's environment-dependent
    skip "Dependency mocking not implemented"
}

@test "handles corrupted accounts file" {
    # Create corrupted JSON file
    echo "invalid json content" > "${XDG_CONFIG_HOME}/git-acc/accounts.json"

    run git-acc list
    [ "${status}" -ne 0 ]
}

# Edge cases
@test "handles empty account name" {
    run git-acc add --name "" --email "test@example.com"
    [ "${status}" -eq 2 ]
}

@test "handles very long account names" {
    local long_name="$(printf 'a%.0s' {1..100})"
    run git-acc add --name "${long_name}" --email "test@example.com"
    [ "${status}" -eq 0 ]
}

@test "handles special characters in account names" {
    run git-acc add --name "Work-Account_2023" --email "test@example.com"
    [ "${status}" -eq 0 ]

    run git-acc add --name "Work Account" --email "test@example.com"
    [ "${status}" -eq 2 ]  # Should fail due to space
}

@test "preserves SSH key information correctly" {
    # Create a dummy SSH key file
    local ssh_key="${TEST_HOME}/.ssh/test_key"
    mkdir -p "$(dirname "${ssh_key}")"
    touch "${ssh_key}"

    run git-acc add --name "WithSSH" --email "test@example.com" --ssh "${ssh_key}"
    [ "${status}" -eq 0 ]

    run git-acc list
    [[ "${output}" == *"${ssh_key}"* ]]
}

