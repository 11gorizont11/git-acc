#!/usr/bin/env bash
# git-acc-core.sh - Core functions for git-acc CLI utility
# This file contains reusable functions that can be sourced by the main script

# Validation functions
validate_email() {
    local email="$1"
    [[ "${email}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

validate_account_name() {
    local name="$1"
    # Account names should be non-empty and contain only safe characters (including spaces)
    [[ -n "${name}" && "${name}" =~ ^[A-Za-z0-9_[:space:]-]+$ ]]
}

validate_ssh_key() {
    local key_path="$1"
    [[ -f "${key_path}" && -r "${key_path}" ]]
}

# JSON manipulation helpers
get_account_by_name() {
    local accounts_file="$1"
    local name="$2"
    jq --arg name "${name}" '.accounts[] | select(.name == $name)' "${accounts_file}"
}

account_exists() {
    local accounts_file="$1"
    local name="$2"
    jq -e --arg name "${name}" '.accounts[] | select(.name == $name)' "${accounts_file}" > /dev/null
}

get_active_account() {
    local accounts_file="$1"
    jq -r '.active // "none"' "${accounts_file}"
}

count_accounts() {
    local accounts_file="$1"
    jq '.accounts | length' "${accounts_file}"
}

# File operation helpers
create_backup() {
    local source_file="$1"
    local backup_suffix="${2:-$(date +%Y%m%d_%H%M%S)}"
    local backup_file="${source_file}.bak.${backup_suffix}"

    if [[ -f "${source_file}" ]]; then
        cp "${source_file}" "${backup_file}"
        printf "%s" "${backup_file}"
    fi
}

safe_write_json() {
    local target_file="$1"
    local json_content="$2"
    local temp_file

    temp_file=$(mktemp)
    printf "%s" "${json_content}" > "${temp_file}"

    # Validate JSON before writing
    if jq empty "${temp_file}" 2>/dev/null; then
        mv "${temp_file}" "${target_file}"
        return 0
    else
        rm -f "${temp_file}"
        return 1
    fi
}

# Git configuration helpers
get_current_git_identity() {
    local name email
    name=$(git config --global user.name 2>/dev/null || echo "")
    email=$(git config --global user.email 2>/dev/null || echo "")

    printf '{"name": "%s", "email": "%s"}' "${name}" "${email}"
}

set_git_identity() {
    local name="$1"
    local email="$2"

    git config --global user.name "${name}"
    git config --global user.email "${email}"
}

# SSH key management helpers
generate_ssh_key() {
    local key_path="$1"
    local email="$2"
    local key_type="${3:-ed25519}"

    ssh-keygen -t "${key_type}" -C "${email}" -f "${key_path}" -N ""
}

get_ssh_public_key() {
    local private_key_path="$1"
    local public_key_path="${private_key_path}.pub"

    if [[ -f "${public_key_path}" ]]; then
        cat "${public_key_path}"
    fi
}

# Dependency checking
check_command() {
    local cmd="$1"
    command -v "${cmd}" &> /dev/null
}

check_required_commands() {
    local missing=()
    local required_commands=("git" "jq")

    for cmd in "${required_commands[@]}"; do
        if ! check_command "${cmd}"; then
            missing+=("${cmd}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        return 1
    fi

    return 0
}

# Output formatting helpers
format_account_list() {
    local accounts_file="$1"
    local active_account="$2"

    jq -r '.accounts[] | "\(.name)\t\(.email)\t\(.ssh_key // "no SSH key")"' "${accounts_file}" | \
    while IFS=$'\t' read -r name email ssh; do
        local marker=""
        if [[ "${name}" == "${active_account}" ]]; then
            marker=" *"
        fi
        printf "  %-20s %-30s %s%s\n" "${name}" "${email}" "${ssh}" "${marker}"
    done
}

# Configuration management
init_config_dir() {
    local config_dir="$1"
    local accounts_file="$2"
    local config_file="$3"

    mkdir -p "${config_dir}"

    # Initialize accounts file
    if [[ ! -f "${accounts_file}" ]]; then
        printf '{"accounts": [], "active": null}\n' > "${accounts_file}"
    fi

    # Initialize config file
    if [[ ! -f "${config_file}" ]]; then
        printf '{"backup_gitconfig": true, "ssh_management": true}\n' > "${config_file}"
    fi
}

# Color codes for logging (if not already defined)
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly YELLOW='\033[0;33m'
    readonly BLUE='\033[0;34m'
    readonly GREEN='\033[0;32m'
    readonly GRAY='\033[0;90m'
    readonly NC='\033[0m' # No Color
fi

# Check if colors should be disabled
core_should_use_colors() {
    # Disable colors if NO_COLOR env var is set, or output is not a terminal
    [[ -z "${NO_COLOR:-}" && -t 2 ]]
}

# Error handling
die() {
    local exit_code="$1"
    shift
    if core_should_use_colors; then
        printf "${RED}[ERROR]${NC} %s\n" "$*" >&2
    else
        printf "[ERROR] %s\n" "$*" >&2
    fi
    exit "${exit_code}"
}

warn() {
    if core_should_use_colors; then
        printf "${YELLOW}[WARNING]${NC} %s\n" "$*" >&2
    else
        printf "[WARNING] %s\n" "$*" >&2
    fi
}

info() {
    if core_should_use_colors; then
        printf "${BLUE}[INFO]${NC} %s\n" "$*"
    else
        printf "[INFO] %s\n" "$*"
    fi
}

success() {
    if core_should_use_colors; then
        printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"
    else
        printf "[SUCCESS] %s\n" "$*"
    fi
}

# String utilities
trim() {
    local var="$1"
    # Remove leading whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace
    var="${var%"${var##*[![:space:]]}"}"
    printf "%s" "${var}"
}

is_empty() {
    local str="$1"
    [[ -z "$(trim "${str}")" ]]
}

# Interactive input helpers
prompt_for_input() {
    local prompt="$1"
    local default="$2"
    local response

    if [[ -n "${default}" ]]; then
        read -rp "${prompt} [${default}]: " response
        response="${response:-${default}}"
    else
        read -rp "${prompt}: " response
    fi

    printf "%s" "${response}"
}

confirm() {
    local prompt="$1"
    local default="${2:-N}"
    local response

    if [[ "${default}" == "Y" ]]; then
        read -rp "${prompt} (Y/n): " response
        response="${response:-Y}"
    else
        read -rp "${prompt} (y/N): " response
        response="${response:-N}"
    fi

    [[ "${response}" =~ ^[Yy]$ ]]
}

# Account management helpers
add_account_to_file() {
    local accounts_file="$1"
    local name="$2"
    local email="$3"
    local ssh_key="$4"

    local new_account
    new_account=$(jq -n \
        --arg name "${name}" \
        --arg email "${email}" \
        --arg ssh "${ssh_key}" \
        '{name: $name, email: $email, ssh_key: (if $ssh == "" then null else $ssh end)}')

    local updated_accounts
    updated_accounts=$(jq --argjson account "${new_account}" '.accounts += [$account]' "${accounts_file}")

    safe_write_json "${accounts_file}" "${updated_accounts}"
}

remove_account_from_file() {
    local accounts_file="$1"
    local name="$2"

    local updated_accounts
    updated_accounts=$(jq --arg name "${name}" \
        '.accounts = (.accounts | map(select(.name != $name))) |
         if .active == $name then .active = null else . end' "${accounts_file}")

    safe_write_json "${accounts_file}" "${updated_accounts}"
}

set_active_account() {
    local accounts_file="$1"
    local name="$2"

    local updated_accounts
    updated_accounts=$(jq --arg name "${name}" '.active = $name' "${accounts_file}")

    safe_write_json "${accounts_file}" "${updated_accounts}"
}

# Version comparison (for future use)
version_compare() {
    local version1="$1"
    local version2="$2"

    # Simple version comparison (major.minor.patch)
    # Returns: 0 if equal, 1 if version1 > version2, 2 if version1 < version2

    IFS='.' read -ra v1_parts <<< "${version1}"
    IFS='.' read -ra v2_parts <<< "${version2}"

    local max_parts
    max_parts=$(( ${#v1_parts[@]} > ${#v2_parts[@]} ? ${#v1_parts[@]} : ${#v2_parts[@]} ))

    for ((i=0; i<max_parts; i++)); do
        local part1="${v1_parts[i]:-0}"
        local part2="${v2_parts[i]:-0}"

        if ((part1 > part2)); then
            return 1
        elif ((part1 < part2)); then
            return 2
        fi
    done

    return 0
}

# Cleanup helpers
cleanup_temp_files() {
    local pattern="${1:-/tmp/git-acc.*}"
    find /tmp -name "git-acc.*" -type f -mtime +1 -delete 2>/dev/null || true
}

# Export functions for use in main script
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Being sourced, export functions
    export -f validate_email validate_account_name validate_ssh_key
    export -f get_account_by_name account_exists get_active_account count_accounts
    export -f create_backup safe_write_json
    export -f get_current_git_identity set_git_identity
    export -f generate_ssh_key get_ssh_public_key
    export -f check_command check_required_commands
    export -f format_account_list
    export -f init_config_dir
    export -f die warn info success core_should_use_colors
    export -f trim is_empty
    export -f prompt_for_input confirm
    export -f add_account_to_file remove_account_from_file set_active_account
    export -f version_compare cleanup_temp_files
fi

