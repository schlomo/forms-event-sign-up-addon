#!/usr/bin/env bash

# Forms Event Sign-up Addon Release Script
# Automates versioning, tagging, and deployment of the Google Apps Script addon.

set -euo pipefail

# Source the shared utility functions
# shellcheck source=./lib/utils.sh
source "$(dirname "$0")/lib/utils.sh"

# --- Main release functions ---

# Ensures the repository is in a clean state for release.
check_git_status() {
    log_info "Checking Git status..."
    if ! git diff-index --quiet HEAD --; then
        log_error "Working directory is not clean. Please commit or stash your changes before releasing."
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
    log_info "Syncing with remote repository..."
    git pull origin main
    # Pushing is a bit presumptive, but ensures the release is based on the absolute latest version.
    git push origin main
    log_success "Repository synced with remote."
}

# Bumps the version, creates a Git tag, and pushes to remote.
create_new_version() {
    log_info "Bumping version and creating Git tag..."
    # npm version patch will create a new version, commit, and tag.
    # The output is the new version tag (e.g., v1.0.1).
    local new_version_tag
    new_version_tag=$(npm version patch -m "chore(release): release %s")
    
    log_success "Version bumped to ${new_version_tag}."
    
    log_info "Pushing new version commit and tag to origin..."
    git push origin main --follow-tags
    
    log_success "Commit and tag pushed to remote."
    # Return the new version tag for use in the deployment description
    echo "${new_version_tag}"
}

# Pushes the latest code to Google Apps Script.
push_to_clasp() {
    log_info "Pushing latest code to Google Apps Script via clasp..."
    if clasp push; then
        log_success "Successfully pushed code to Google Apps Script."
    else
        log_error "Failed to push code to Google Apps Script."
        exit 1
    fi
}

# Creates a new deployment in Google Apps Script.
deploy_to_clasp() {
    local version_tag="$1"
    local description="$2"
    local full_description="${version_tag}: ${description}"

    log_info "Creating new deployment on Google Apps Script..."
    log_info "Description: ${full_description}"
    
    if clasp deploy --description "${full_description}"; then
        log_success "Successfully created new deployment."
    else
        log_error "Failed to create new deployment."
        exit 1
    fi
}


# --- Main Script ---

show_help() {
    echo "Usage: $0 \"<release_description>\""
    echo ""
    echo "This script automates the release process:"
    echo "1. Checks for a clean 'main' branch."
    echo "2. Bumps the patch version in package.json."
    echo "3. Commits the version change and creates a Git tag."
    echo "4. Pushes the code to Google Apps Script."
    echo "5. Creates a new deployment with the version and description."
    echo ""
    echo "Arguments:"
    echo "  release_description   A string describing the new version's changes."
    echo ""
}

main() {
    # Check for help flag
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_help
        exit 0
    fi

    # Check for description argument
    if [ -z "$1" ]; then
        log_error "Release description is required."
        show_help
        exit 1
    fi
    local release_description="$1"

    log_info "🚀 Starting new release process..."

    # 1. Pre-flight checks
    check_clasp
    check_directory
    check_auth
    check_git_status
    
    # 2. Sync with remote
    sync_with_remote

    # 3. Create version and tag
    local new_version
    new_version=$(create_new_version)

    # 4. Push code to Apps Script project
    push_to_clasp

    # 5. Create new deployment
    deploy_to_clasp "${new_version}" "${release_description}"

    log_success "🎉 Release ${new_version} complete and deployed successfully!"
}

# Run the main function with all script arguments
main "$@" 