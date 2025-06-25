#!/usr/bin/env bash

# Shared utility functions for shell scripts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
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
    # a login status of 1 means logged out, 0 means logged in
    if ! npx clasp login --status &> /dev/null; then
        log_warning "Not logged in to clasp. Please run: npx clasp login"
        exit 1
    fi
} 