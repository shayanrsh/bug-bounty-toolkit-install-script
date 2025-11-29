#!/bin/bash
# ==============================================================================
# FFUF Plugin - Web Fuzzer
# ==============================================================================
# Plugin Name: ffuf
# Author: joohoi
# Version: 1.0.0
# Description: Fast web fuzzer written in Go
# ==============================================================================

PLUGIN_NAME="ffuf"
PLUGIN_VERSION="1.0.0"
PLUGIN_AUTHOR="joohoi"
PLUGIN_DESCRIPTION="Fast web fuzzer written in Go - Fuzz Faster U Fool"
PLUGIN_WEBSITE="https://github.com/ffuf/ffuf"
PLUGIN_INSTALL_METHOD="go"
PLUGIN_GO_PACKAGE="github.com/ffuf/ffuf/v2@latest"
PLUGIN_DEPENDENCIES="go"

plugin_info() {
    cat << EOF
{
    "name": "$PLUGIN_NAME",
    "version": "$PLUGIN_VERSION",
    "author": "$PLUGIN_AUTHOR",
    "description": "$PLUGIN_DESCRIPTION",
    "website": "$PLUGIN_WEBSITE",
    "install_method": "$PLUGIN_INSTALL_METHOD",
    "category": "fuzzing"
}
EOF
}

plugin_install() {
    log_info "Installing FFUF..."
    
    # Check for Go
    if ! command -v go &>/dev/null; then
        log_error "Go is required to install FFUF"
        return 1
    fi
    
    # Install ffuf
    log_info "Installing ffuf via go install..."
    if ! go install -v "$PLUGIN_GO_PACKAGE" 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Failed to install ffuf"
        return 1
    fi
    
    # Verify installation
    if plugin_verify; then
        log_success "FFUF installed successfully!"
        log_info "Configuration file: ~/.ffufrc"
        return 0
    fi
    
    return 1
}

plugin_verify() {
    if ! command -v ffuf &>/dev/null; then
        log_error "FFUF command not found in PATH"
        return 1
    fi
    
    local version
    version=$(ffuf -V 2>&1 | head -n1 || echo "unknown")
    log_success "FFUF verified: $version"
    return 0
}

plugin_update() {
    log_info "Updating FFUF..."
    go install -v "$PLUGIN_GO_PACKAGE" 2>&1 || return 1
    log_success "FFUF updated successfully"
    return 0
}

plugin_uninstall() {
    log_info "Uninstalling FFUF..."
    
    local binary_path="$(go env GOPATH)/bin/ffuf"
    if [[ -f "$binary_path" ]]; then
        rm -f "$binary_path"
        log_success "Removed ffuf binary"
    fi
    
    return 0
}

plugin_get_version() {
    if command -v ffuf &>/dev/null; then
        ffuf -V 2>&1 | grep -oP 'v?\d+\.\d+\.\d+' | head -n1 || echo "unknown"
    else
        echo "not installed"
    fi
}

plugin_health_check() {
    log_info "Running FFUF health check..."
    
    if ! plugin_verify; then
        return 1
    fi
    
    # Check for wordlists
    local wordlists_dir="${WORDLISTS_DIR:-$HOME/wordlists}"
    if [[ -d "$wordlists_dir" ]]; then
        local wl_count
        wl_count=$(find "$wordlists_dir" -type f \( -name "*.txt" -o -name "*.lst" \) 2>/dev/null | wc -l)
        log_info "Found $wl_count wordlist files in $wordlists_dir"
    else
        log_warning "Wordlists directory not found: $wordlists_dir"
        log_info "Consider installing wordlists for better fuzzing"
    fi
    
    # Test basic functionality
    if ffuf -h &>/dev/null; then
        log_success "FFUF help command works"
    fi
    
    return 0
}
