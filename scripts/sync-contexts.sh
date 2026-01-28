#!/bin/bash
set -euo pipefail

# Script: sync-contexts.sh
# Purpose: Pull CONTEXT.md files from project repositories into dev-ops
# Usage: ./sync-contexts.sh

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly PROJECTS_DIR="${REPO_ROOT}/projects"

# Configuration: Add your project repositories here
# Format: "repo_path:project_name"
declare -a REPOS=(
    # TODO: Add your actual repository paths
    # Example:
    # "${HOME}/projects/home-automation:home-automation"
    # "${HOME}/projects/network-monitoring:network-monitoring"
)

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

sync_context() {
    local repo_path="$1"
    local project_name="$2"
    
    log_info "Processing ${project_name}..."
    
    # Check if repo exists
    if [[ ! -d "${repo_path}" ]]; then
        log_error "Repository not found: ${repo_path}"
        return 1
    fi
    
    # Check if CONTEXT.md exists
    local context_file="${repo_path}/CONTEXT.md"
    if [[ ! -f "${context_file}" ]]; then
        log_info "No CONTEXT.md found in ${project_name}, skipping"
        return 0
    fi
    
    # Copy to projects directory
    local dest_file="${PROJECTS_DIR}/${project_name}.md"
    
    # Add header with metadata
    {
        echo "# ${project_name}"
        echo ""
        echo "**Source:** ${repo_path}"
        echo "**Last synced:** $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "---"
        echo ""
        cat "${context_file}"
    } > "${dest_file}"
    
    log_info "Synced ${project_name} context"
}

main() {
    log_info "Starting context sync..."
    
    # Ensure projects directory exists
    mkdir -p "${PROJECTS_DIR}"
    
    if [[ ${#REPOS[@]} -eq 0 ]]; then
        log_error "No repositories configured in REPOS array"
        log_info "Edit this script and add your project paths"
        exit 1
    fi
    
    # Sync each repository
    local synced=0
    local failed=0
    
    for repo_config in "${REPOS[@]}"; do
        IFS=':' read -r repo_path project_name <<< "${repo_config}"
        
        if sync_context "${repo_path}" "${project_name}"; then
            ((synced++))
        else
            ((failed++))
        fi
    done
    
    log_info "Sync complete: ${synced} synced, ${failed} failed"
    
    # Offer to commit if in git repo
    if [[ -d "${REPO_ROOT}/.git" ]]; then
        echo ""
        read -p "Commit changes to git? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "${REPO_ROOT}"
            git add "${PROJECTS_DIR}"
            git commit -m "Sync project contexts from external repos"
            log_info "Changes committed"
        fi
    fi
}

# Show usage if --help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat << EOF
Usage: $(basename "$0")

Syncs CONTEXT.md files from project repositories into dev-ops/projects/

Configuration:
Edit the REPOS array in this script to add your project repositories.
Format: "path/to/repo:project-name"

Example:
REPOS=(
    "\${HOME}/projects/home-automation:home-automation"
    "\${HOME}/projects/my-app:my-app"
)

The script will:
1. Look for CONTEXT.md in each repository
2. Copy it to projects/project-name.md with metadata header
3. Optionally commit changes to git

EOF
    exit 0
fi

main "$@"
