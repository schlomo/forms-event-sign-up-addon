#!/usr/bin/env bash

# Forms Event Sign-up Addon Deployment Script
# This script handles the deployment workflow for the Google Apps Script addon

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if clasp is installed
check_clasp() {
    if ! command -v clasp &> /dev/null; then
        log_error "clasp is not installed. Please install it with: npm install -g @google/clasp"
        exit 1
    fi
}

# Check if we're in the right directory
check_directory() {
    if [[ ! -f ".clasp.json" ]]; then
        log_error "Not in a clasp project directory. Please run this from the project root."
        exit 1
    fi
}

# Check if user is logged in
check_auth() {
    if ! clasp login --status &> /dev/null; then
        log_warning "Not logged in to clasp. Please run: clasp login"
        exit 1
    fi
}

# Pull latest changes from Google Apps Script
pull_changes() {
    log_info "Pulling latest changes from Google Apps Script..."
    if clasp pull; then
        log_success "Successfully pulled changes from Google Apps Script"
    else
        log_error "Failed to pull changes from Google Apps Script"
        exit 1
    fi
}

# Push local changes to Google Apps Script
push_changes() {
    log_info "Pushing local changes to Google Apps Script..."
    if clasp push; then
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
    
    if clasp deploy --description "$version_description"; then
        log_success "Successfully deployed version: $version_description"
    else
        log_error "Failed to deploy version: $version_description"
        exit 1
    fi
}

# Open Google Apps Script project
open_project() {
    log_info "Opening Google Apps Script project..."
    clasp open
}

# Show deployment status
show_status() {
    log_info "Current deployment status:"
    clasp versions
}

# Main deployment workflow
main() {
    local version_description="${1:-$(date +'%Y-%m-%d %H:%M:%S') deployment}"
    
    log_info "Starting deployment workflow..."
    
    # Pre-flight checks
    check_clasp
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
        check_clasp
        check_directory
        check_auth
        pull_changes
        ;;
    "push")
        check_clasp
        check_directory
        check_auth
        push_changes
        ;;
    "open")
        check_clasp
        check_directory
        check_auth
        open_project
        ;;
    "status")
        check_clasp
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