#!/usr/bin/env bash

# Shared utility functions for clasp operations

# shellcheck source=./utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Pull changes from Google Apps Script
clasp_pull() {
    log_info "Pulling changes from Google Apps Script..."
    if npx clasp pull; then
        log_success "Successfully pulled changes from Google Apps Script"
        return 0
    else
        log_error "Failed to pull changes from Google Apps Script"
        return 1
    fi
}

# Push changes to Google Apps Script
clasp_push() {
    log_info "Pushing changes to Google Apps Script..."
    if npx clasp push; then
        log_success "Successfully pushed changes to Google Apps Script"
        return 0
    else
        log_error "Failed to push changes to Google Apps Script"
        return 1
    fi
}

# Deploy new version to Google Apps Script
clasp_deploy() {
    local new_version="$1"
    local release_description="$2"
    local full_description="${new_version}: ${release_description}"

    log_info "Deploying new version with description: \"$full_description\""

    if npx clasp deploy --description "$full_description"; then
        log_success "Successfully deployed version: ${new_version}"
    else
        log_error "Failed to deploy version: ${new_version}"
        exit 1
    fi
}

# Open the Google Apps Script project
clasp_open() {
    log_info "Opening Google Apps Script project..."
    npx clasp open
}

# Show deployment versions
clasp_versions() {
    log_info "Current deployment status:"
    npx clasp versions
} 