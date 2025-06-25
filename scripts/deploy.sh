#!/usr/bin/env bash

# Forms Event Sign-up Addon Deployment Script
# This script handles the deployment workflow for the Google Apps Script addon

set -euo pipefail

# Source the shared utility functions
# shellcheck source=./lib/utils.sh
source "$(dirname "$0")/lib/utils.sh"
# shellcheck source=./lib/clasp-utils.sh
source "$(dirname "$0")/lib/clasp-utils.sh"

# Check for local changes
check_local_changes() {
    if [[ -n "$(git status --porcelain)" ]]; then
        log_warning "You have uncommitted local changes. Consider committing them first."
        git status
        # We don't exit here, just warn, as this isn't a formal release script.
    fi
}

# Get the current version from package.json
get_package_version() {
    # Using grep and sed to avoid a dependency on jq
    grep '"version":' package.json | sed -E 's/.*"version": "([^"]+)".*/\1/'
}

# Main deployment workflow
main() {
    local custom_description="${1:-Manual deployment}"
    local pkg_version
    pkg_version=$(get_package_version)
    local full_description="v${pkg_version}: ${custom_description}"
    
    log_info "Starting deployment workflow..."
    
    # Pre-flight checks
    check_directory
    check_auth
    check_local_changes
    
    # Pull any remote changes first
    clasp_pull
    
    # Push local changes
    clasp_push
    
    # Deploy new version
    clasp_deploy "$full_description"
    
    # Show status
    clasp_versions
    
    log_success "Deployment workflow completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "pull")
        check_directory
        check_auth
        clasp_pull
        ;;
    "push")
        check_directory
        check_auth
        clasp_push
        ;;
    "open")
        check_directory
        check_auth
        clasp_open
        ;;
    "status")
        check_directory
        check_auth
        clasp_versions
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
        echo "  $0                                    # Deploy with default description"
        echo "  $0 'UI bug fixes'                    # Deploy with custom description"
        echo "  $0 pull                               # Pull remote changes"
        ;;
    *)
        main "$@"
        ;;
esac