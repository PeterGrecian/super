#!/usr/bin/env bash
# sync-repos.sh - Pull, push, commit, and collect TODOs from all sibling repos
#
# Usage:
#   ./sync-repos.sh                 # Pull, push, and collect TODOs
#   ./sync-repos.sh pull            # Only pull
#   ./sync-repos.sh commit push     # Commit all changes and push
#   ./sync-repos.sh push            # Only push
#   ./sync-repos.sh commit          # Only commit uncommitted changes
#   ./sync-repos.sh collect         # Only collect TODOs
#   ./sync-repos.sh pull collect    # Pull and collect (no push)
#   ./sync-repos.sh commit push collect  # Commit, push, and collect

set -e

# Configuration
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
DO_PULL=false
DO_COMMIT=false
DO_PUSH=false
DO_COLLECT=false

if [ $# -eq 0 ]; then
    # Default: do all operations except commit (user must explicitly request commit)
    DO_PULL=true
    DO_PUSH=true
    DO_COLLECT=true
else
    for arg in "$@"; do
        case "$arg" in
            pull) DO_PULL=true ;;
            commit) DO_COMMIT=true ;;
            push) DO_PUSH=true ;;
            collect) DO_COLLECT=true ;;
            *)
                echo "Unknown option: $arg"
                echo "Usage: $0 [pull] [commit] [push] [collect]"
                exit 1
                ;;
        esac
    done
fi

# Find all sibling repos (exclude super itself)
REPOS=()
for dir in "$ROOT_DIR"/*/ ; do
    repo_name=$(basename "$dir")
    if [ "$repo_name" != "super" ] && [ -d "$dir/.git" ]; then
        REPOS+=("$dir")
    fi
done

echo -e "${BLUE}Found ${#REPOS[@]} repositories to sync${NC}"
echo ""

# Function to pull a repo
pull_repo() {
    local repo_dir="$1"
    local repo_name=$(basename "$repo_dir")

    cd "$repo_dir"
    if git pull --quiet 2>&1 | grep -q "Already up to date"; then
        echo -e "${GREEN}✓${NC} $repo_name (up to date)"
    else
        echo -e "${YELLOW}↓${NC} $repo_name (updated)"
    fi
}

# Function to commit changes in a repo
commit_repo() {
    local repo_dir="$1"
    local repo_name=$(basename "$repo_dir")

    cd "$repo_dir"

    # Check if there are uncommitted changes
    if ! git status --porcelain | grep -q .; then
        echo -e "${GREEN}✓${NC} $repo_name (nothing to commit)"
        return 0
    fi

    # Create commit message with timestamp and hostname
    local timestamp=$(date +'%Y-%m-%d %H:%M')
    local hostname=$(hostname -s 2>/dev/null || hostname)
    local commit_msg="sync ${timestamp} from ${hostname}"

    # Add all changes and commit
    if git add -A && git commit -m "$commit_msg" --quiet 2>&1; then
        echo -e "${YELLOW}✎${NC} $repo_name (committed)"
    else
        echo -e "${RED}✗${NC} $repo_name (commit failed)"
        return 1
    fi
}

# Function to push a repo
push_repo() {
    local repo_dir="$1"
    local repo_name=$(basename "$repo_dir")

    cd "$repo_dir"

    # Check if there's anything to push
    if git status --porcelain | grep -q .; then
        echo -e "${RED}✗${NC} $repo_name (uncommitted changes)"
        return 1
    fi

    # Check if local is ahead of remote
    local_ahead=$(git rev-list @{u}..HEAD 2>/dev/null | wc -l || echo "0")

    if [ "$local_ahead" -gt 0 ]; then
        if git push --quiet 2>&1; then
            echo -e "${YELLOW}↑${NC} $repo_name (pushed $local_ahead commits)"
        else
            echo -e "${RED}✗${NC} $repo_name (push failed)"
            return 1
        fi
    else
        echo -e "${GREEN}✓${NC} $repo_name (nothing to push)"
    fi
}

# Pull all repos in parallel
if [ "$DO_PULL" = true ]; then
    echo -e "${BLUE}=== Pulling all repos ===${NC}"

    PULL_PIDS=()
    for repo in "${REPOS[@]}"; do
        pull_repo "$repo" &
        PULL_PIDS+=($!)
    done

    # Wait for all pulls to complete
    for pid in "${PULL_PIDS[@]}"; do
        wait $pid
    done

    echo ""
fi

# Commit all repos in parallel
if [ "$DO_COMMIT" = true ]; then
    echo -e "${BLUE}=== Committing all repos ===${NC}"

    COMMIT_PIDS=()
    for repo in "${REPOS[@]}"; do
        commit_repo "$repo" &
        COMMIT_PIDS+=($!)
    done

    # Wait for all commits to complete
    for pid in "${COMMIT_PIDS[@]}"; do
        wait $pid || true  # Don't fail if some commits fail
    done

    echo ""
fi

# Push all repos in parallel
if [ "$DO_PUSH" = true ]; then
    echo -e "${BLUE}=== Pushing all repos ===${NC}"

    PUSH_PIDS=()
    for repo in "${REPOS[@]}"; do
        push_repo "$repo" &
        PUSH_PIDS+=($!)
    done

    # Wait for all pushes to complete
    for pid in "${PUSH_PIDS[@]}"; do
        wait $pid || true  # Don't fail if some pushes fail
    done

    echo ""
fi

# Collect TODOs
if [ "$DO_COLLECT" = true ]; then
    echo -e "${BLUE}=== Collecting TODOs ===${NC}"
    cd "$SUPER_DIR"
    python bin/collect-todos.py
    echo ""
fi

echo -e "${GREEN}Done!${NC}"
