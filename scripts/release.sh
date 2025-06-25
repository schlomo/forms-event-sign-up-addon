#!/usr/bin/env bash

# Forms Event Sign-up Addon Release Script
# Automates versioning, tagging, and deployment of the Google Apps Script addon.

set -euo pipefail

# Source the shared utility functions
# shellcheck source=./lib/utils.sh
source "$(dirname "$0")/lib/utils.sh"
# shellcheck source=./lib/clasp-utils.sh
source "$(dirname "$0")/lib/clasp-utils.sh"

# --- Main release functions ---

# Ensures the repository is in a clean state for release.
check_git_status() {
    log_info "Checking Git status..."
    if [[ -n "$(git status --porcelain)" ]]; then
        log_error "Working directory is not clean. Please commit or stash your changes before releasing."
        git status
        exit 1
    fi

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$current_branch" != "main" ]]; then
        log_error "You must be on the 'main' branch to create a release. You are currently on '$current_branch'."
        exit 1
    fi
    log_success "Git status is clean and on the main branch."
}

# Syncs the local repository with the remote.
sync_with_remote() {
    log_info "Pulling latest changes from remote repository..."
    git pull origin main
    log_success "Repository synced with remote."
}

# Bumps the version and creates a Git tag.
create_new_version() {
    log_info "Bumping version and creating Git tag..."
    # npm version patch will create a new version, commit, and tag.
    # The output is the new version tag (e.g., v1.0.1).
    local new_version_tag
    new_version_tag=$(npm version patch -m "chore(release): release %s")
    
    log_success "Version bumped to ${new_version_tag}."
    
    # Return the new version tag for use in the deployment description
    echo "${new_version_tag}"
}

# --- Main Script ---

show_help() {
    echo "Usage: $0 \"<release_description>\""
    echo ""
    echo "This script automates the release process:"
    echo "1. Checks for a clean 'main' branch."
    echo "2. Bumps the patch version in package.json."
    echo "3. Commits the version change and creates a Git tag locally."
    echo "4. Pushes the code to Google Apps Script."
    echo "5. Creates a new deployment with the version and description."
    echo "NOTE: This script does NOT push the new git commit and tag automatically."
    echo ""
    echo "Arguments:"
    echo "  release_description   A string describing the new version's changes."
    echo ""
}

main() {
    # Check for help flag
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    local release_description
    if [ -z "${1:-}" ]; then
        log_info "No release description provided. Using last commit message."
        release_description=$(git log -1 --pretty=%B)
    else
        release_description="$*"
    fi

    log_info "🚀 Starting new release process..."

    # 1. Pre-flight checks
    check_directory
    check_auth
    check_git_status
    
    # 2. Sync with remote
    sync_with_remote

    # 3. Create version and tag
    local new_version
    new_version=$(create_new_version)

    # 4. Push code to Apps Script project
    clasp_push

    # 5. Create new deployment
    clasp_deploy "${new_version}" "${release_description}"

    log_success "🎉 Release ${new_version} complete and deployed successfully!"
    log_info "Manually update the version in the Marketplace to: ${new_version//v}"
    log_warning "Don't forget to push the git commit and tag: git push"
}

# Run the main function with all script arguments
main "$@" 