#!/bin/bash
set -euo pipefail

# Script: setup-env.sh
# Purpose: Bootstrap development environment on new system
# Usage: ./setup-env.sh

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

check_command() {
    local cmd="$1"
    if command -v "${cmd}" >/dev/null 2>&1; then
        log_info "✓ ${cmd} is installed"
        return 0
    else
        log_error "✗ ${cmd} is not installed"
        return 1
    fi
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing=0
    
    # Essential tools
    local essential=(git python3 bash)
    for cmd in "${essential[@]}"; do
        check_command "${cmd}" || ((missing++))
    done
    
    # Optional but recommended
    local optional=(aws jq terraform)
    for cmd in "${optional[@]}"; do
        if ! check_command "${cmd}"; then
            log_info "  (optional, install if needed)"
        fi
    done
    
    if [[ ${missing} -gt 0 ]]; then
        log_error "Missing ${missing} essential dependencies"
        return 1
    fi
    
    log_info "All essential dependencies present"
}

setup_git() {
    log_info "Setting up Git configuration..."
    
    # Check if git is configured
    if ! git config user.name >/dev/null 2>&1; then
        echo "Git user.name not set"
        read -p "Enter your name: " name
        git config --global user.name "${name}"
    else
        log_info "✓ Git user.name: $(git config user.name)"
    fi
    
    if ! git config user.email >/dev/null 2>&1; then
        echo "Git user.email not set"
        read -p "Enter your email: " email
        git config --global user.email "${email}"
    else
        log_info "✓ Git user.email: $(git config user.email)"
    fi
    
    # Set up SSH for GitHub if not present
    if [[ ! -f "${HOME}/.ssh/id_rsa" && ! -f "${HOME}/.ssh/id_ed25519" ]]; then
        echo ""
        echo "No SSH key found for GitHub"
        read -p "Generate new SSH key? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh-keygen -t ed25519 -C "$(git config user.email)"
            log_info "SSH key generated. Add to GitHub:"
            echo ""
            cat "${HOME}/.ssh/id_ed25519.pub"
            echo ""
        fi
    else
        log_info "✓ SSH key exists"
    fi
}

setup_aws() {
    if ! command -v aws >/dev/null 2>&1; then
        log_info "AWS CLI not installed, skipping AWS setup"
        return 0
    fi
    
    log_info "Setting up AWS credentials..."
    
    if [[ -f "${HOME}/.aws/credentials" ]]; then
        log_info "✓ AWS credentials already configured"
    else
        echo ""
        echo "AWS credentials not found"
        read -p "Configure AWS now? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            aws configure
        else
            log_info "Skipping AWS configuration"
        fi
    fi
}

setup_python() {
    log_info "Setting up Python environment..."
    
    # Check Python version
    local python_version
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    log_info "✓ Python ${python_version}"
    
    # Check if pip is available
    if ! python3 -m pip --version >/dev/null 2>&1; then
        log_error "pip not available"
        log_info "Install with: sudo apt install python3-pip  # Ubuntu/Debian"
        return 1
    fi
    
    log_info "✓ pip is available"
    
    # Suggest common packages
    echo ""
    echo "Common Python packages you might want:"
    echo "  - boto3 (AWS SDK)"
    echo "  - requests (HTTP)"
    echo "  - pyyaml (YAML parsing)"
    echo ""
    read -p "Install common packages? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        python3 -m pip install --user boto3 requests pyyaml
    fi
}

clone_dev_ops() {
    local repo_url="${1:-}"
    
    if [[ -z "${repo_url}" ]]; then
        log_info "Skipping dev-ops clone (no URL provided)"
        return 0
    fi
    
    log_info "Cloning dev-ops repository..."
    
    local clone_dir="${HOME}/dev-ops"
    if [[ -d "${clone_dir}" ]]; then
        log_info "✓ dev-ops already exists at ${clone_dir}"
    else
        git clone "${repo_url}" "${clone_dir}"
        log_info "✓ Cloned to ${clone_dir}"
    fi
}

setup_tailscale() {
    if ! command -v tailscale >/dev/null 2>&1; then
        log_info "Tailscale not installed"
        echo "Install from: https://tailscale.com/download"
        return 0
    fi
    
    log_info "Tailscale is installed"
    
    if tailscale status >/dev/null 2>&1; then
        log_info "✓ Tailscale is connected"
        tailscale status
    else
        echo ""
        read -p "Connect to Tailscale now? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo tailscale up
        fi
    fi
}

main() {
    log_info "Starting development environment setup"
    echo ""
    
    # Check dependencies
    if ! check_dependencies; then
        log_error "Please install missing dependencies and try again"
        exit 1
    fi
    
    echo ""
    setup_git
    
    echo ""
    setup_aws
    
    echo ""
    setup_python
    
    echo ""
    setup_tailscale
    
    echo ""
    log_info "Setup complete!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Clone dev-ops repo if not done: git clone <repo-url> ~/dev-ops"
    log_info "2. Review infrastructure/*.md for specific configurations"
    log_info "3. Clone your project repositories"
    log_info "4. Update projects/*.md with current status"
}

# Show usage if --help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat << EOF
Usage: $(basename "$0") [dev-ops-repo-url]

Bootstrap a new development environment with:
- Git configuration
- SSH keys for GitHub
- AWS CLI credentials
- Python environment
- Tailscale connection
- Optional: clone dev-ops repository

Arguments:
  dev-ops-repo-url    Optional URL to clone dev-ops repo

Example:
  $(basename "$0")
  $(basename "$0") git@github.com:username/dev-ops.git

EOF
    exit 0
fi

main "$@"
