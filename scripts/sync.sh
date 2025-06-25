#!/usr/bin/env bash

# Forms Event Sign-up Addon Sync Script
# This script handles bidirectional synchronization between local and Google Apps Script

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
        return 1
    fi
    return 0
}

# Sync in both directions
sync_bidirectional() {
    log_info "Starting bidirectional sync..."
    
    # First, pull any remote changes
    if clasp_pull; then
        # Check if there are any conflicts or new files
        if [[ -n "$(git status --porcelain)" ]]; then
            log_info "Remote changes detected. Review and commit if needed."
            git status
        fi
    fi
    
    # Then push local changes
    if clasp_push; then
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
        if clasp_push; then
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
        
        if clasp_pull; then
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
    npx clasp open --webapp
}

# Main sync workflow
main() {
    local sync_mode="${1:-bidirectional}"
    
    log_info "Starting sync workflow in $sync_mode mode..."
    
    # Pre-flight checks
    check_directory
    check_auth
    
    case "$sync_mode" in
        "bidirectional"|"both")
            sync_bidirectional
            ;;
        "pull"|"from-remote")
            clasp_pull
            ;;
        "push"|"to-remote")
            clasp_push
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