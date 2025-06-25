#!/usr/bin/env bash

# Forms Event Sign-up Addon Deployment Script
# This script handles the deployment workflow for the Google Apps Script addon

set -euo pipefail

# Source the shared utility functions
# shellcheck source=./lib/utils.sh
source "$(dirname "$0")/lib/utils.sh"

# Pull latest changes from Google Apps Script
pull_changes() {
    log_info "Pulling latest changes from Google Apps Script..."
    if npx clasp pull; then
        log_success "Successfully pulled changes from Google Apps Script"
    else
        log_error "Failed to pull changes from Google Apps Script"
        exit 1
    fi
}

# Push local changes to Google Apps Script
push_changes() {
    log_info "Pushing local changes to Google Apps Script..."
    if npx clasp push; then
        log_success "Successfully pushed changes to Google Apps Script"
    else
        log_error "Failed to push changes to Google Apps Script"
        exit 1
    fi
}

# Deploy new version
deploy_version() {
    local version_description="$1"
    log_info "Deploying new version: $version_description"
    
    if npx clasp deploy --description "$version_description"; then
        log_success "Successfully deployed version: $version_description"
    else
        log_error "Failed to deploy version: $version_description"
        exit 1
    fi
}

# Open Google Apps Script project
open_project() {
    log_info "Opening Google Apps Script project..."
    npx clasp open
}

# Show deployment status
show_status() {
    log_info "Current deployment status:"
    npx clasp versions
}

# Main deployment workflow
main() {
    local version_description="${1:-$(date +'%Y-%m-%d %H:%M:%S') deployment}"
    
    log_info "Starting deployment workflow..."
    
    # Pre-flight checks
    check_directory
    check_auth
    
    # Pull any remote changes first
    pull_changes
    
    # Push local changes
    push_changes
    
    # Deploy new version
    deploy_version "$version_description"
    
    # Show status
    show_status
    
    log_success "Deployment workflow completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "pull")
        check_directory
        check_auth
        pull_changes
        ;;
    "push")
        check_directory
        check_auth
        push_changes
        ;;
    "open")
        check_directory
        check_auth
        open_project
        ;;
    "status")
        check_directory
        check_auth
        show_status
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command] [version_description]"
        echo ""
        echo "Commands:"
        echo "  (no args)    Full deployment workflow"
        echo "  pull         Pull changes from Google Apps Script"
        echo "  push         Push changes to Google Apps Script"
        echo "  open         Open Google Apps Script project"
        echo "  status       Show deployment status"
        echo "  help         Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                                    # Deploy with timestamp"
        echo "  $0 'v1.2.3 - Bug fixes'              # Deploy with custom description"
        echo "  $0 pull                               # Pull remote changes"
        ;;
    *)
        main "$@"
        ;;
esac