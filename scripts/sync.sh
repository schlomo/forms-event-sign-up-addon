#!/usr/bin/env bash

# Forms Event Sign-up Addon Sync Script
# This script handles bidirectional synchronization between local and Google Apps Script

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

# Check for local changes
check_local_changes() {
    if [[ -n "$(git status --porcelain)" ]]; then
        log_warning "You have uncommitted local changes. Consider committing them first."
        return 1
    fi
    return 0
}

# Pull changes from Google Apps Script
pull_from_remote() {
    log_info "Pulling changes from Google Apps Script..."
    if clasp pull; then
        log_success "Successfully pulled changes from Google Apps Script"
        return 0
    else
        log_error "Failed to pull changes from Google Apps Script"
        return 1
    fi
}

# Push changes to Google Apps Script
push_to_remote() {
    log_info "Pushing changes to Google Apps Script..."
    if clasp push; then
        log_success "Successfully pushed changes to Google Apps Script"
        return 0
    else
        log_error "Failed to push changes to Google Apps Script"
        return 1
    fi
}

# Sync in both directions
sync_bidirectional() {
    log_info "Starting bidirectional sync..."
    
    # First, pull any remote changes
    if pull_from_remote; then
        # Check if there are any conflicts or new files
        if [[ -n "$(git status --porcelain)" ]]; then
            log_info "Remote changes detected. Review and commit if needed."
            git status
        fi
    fi
    
    # Then push local changes
    if push_to_remote; then
        log_success "Bidirectional sync completed successfully!"
    else
        log_error "Bidirectional sync failed during push phase"
        exit 1
    fi
}

# Force sync (overwrite remote with local)
force_sync_local() {
    log_warning "Force syncing local changes to remote (this will overwrite remote changes)"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if push_to_remote; then
            log_success "Force sync completed successfully!"
        else
            log_error "Force sync failed"
            exit 1
        fi
    else
        log_info "Force sync cancelled"
    fi
}

# Force sync (overwrite local with remote)
force_sync_remote() {
    log_warning "Force syncing remote changes to local (this will overwrite local changes)"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Stash any local changes
        if [[ -n "$(git status --porcelain)" ]]; then
            log_info "Stashing local changes..."
            git stash
        fi
        
        if pull_from_remote; then
            log_success "Force sync completed successfully!"
        else
            log_error "Force sync failed"
            exit 1
        fi
    else
        log_info "Force sync cancelled"
    fi
}

# Show sync status
show_status() {
    log_info "Sync status:"
    echo "Local changes:"
    git status --short
    echo ""
    echo "Remote project info:"
    clasp open --webapp
}

# Main sync workflow
main() {
    local sync_mode="${1:-bidirectional}"
    
    log_info "Starting sync workflow in $sync_mode mode..."
    
    # Pre-flight checks
    check_clasp
    check_directory
    check_auth
    
    case "$sync_mode" in
        "bidirectional"|"both")
            sync_bidirectional
            ;;
        "pull"|"from-remote")
            pull_from_remote
            ;;
        "push"|"to-remote")
            push_to_remote
            ;;
        "force-local")
            force_sync_local
            ;;
        "force-remote")
            force_sync_remote
            ;;
        "status")
            show_status
            ;;
        *)
            log_error "Unknown sync mode: $sync_mode"
            echo "Available modes: bidirectional, pull, push, force-local, force-remote, status"
            exit 1
            ;;
    esac
}

# Handle script arguments
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "Usage: $0 [mode]"
        echo ""
        echo "Sync modes:"
        echo "  bidirectional  Sync in both directions (default)"
        echo "  pull           Pull changes from Google Apps Script"
        echo "  push           Push changes to Google Apps Script"
        echo "  force-local    Force push local changes (overwrites remote)"
        echo "  force-remote   Force pull remote changes (overwrites local)"
        echo "  status         Show sync status"
        echo "  help           Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                    # Bidirectional sync"
        echo "  $0 pull               # Pull from remote"
        echo "  $0 force-local        # Force push local changes"
        ;;
    *)
        main "$@"
        ;;
esac 