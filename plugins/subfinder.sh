#!/bin/bash
# ==============================================================================
# Subfinder Plugin - Subdomain Discovery Tool
# ==============================================================================
# Plugin Name: subfinder
# Author: ProjectDiscovery
# Version: 1.0.0
# Description: Fast subdomain discovery tool using passive sources
# ==============================================================================

PLUGIN_NAME="subfinder"
PLUGIN_VERSION="1.0.0"
PLUGIN_AUTHOR="ProjectDiscovery"
PLUGIN_DESCRIPTION="Fast subdomain discovery tool using passive online sources"
PLUGIN_WEBSITE="https://github.com/projectdiscovery/subfinder"
PLUGIN_INSTALL_METHOD="go"
PLUGIN_GO_PACKAGE="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
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
    "category": "reconnaissance"
}
EOF
}

plugin_install() {
    log_info "Installing Subfinder..."
    
    # Check for Go
    if ! command -v go &>/dev/null; then
        log_error "Go is required to install Subfinder"
        return 1
    fi
    
    # Install subfinder
    log_info "Installing subfinder via go install..."
    if ! go install -v "$PLUGIN_GO_PACKAGE" 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Failed to install subfinder"
        return 1
    fi
    
    # Verify installation
    if plugin_verify; then
        log_success "Subfinder installed successfully!"
        log_info "Configuration file: ~/.config/subfinder/provider-config.yaml"
        return 0
    fi
    
    return 1
}

plugin_verify() {
    if ! command -v subfinder &>/dev/null; then
        log_error "Subfinder command not found in PATH"
        return 1
    fi
    
    local version
    version=$(subfinder -version 2>&1 | grep -oP 'v?\d+\.\d+\.\d+' || echo "unknown")
    log_success "Subfinder verified: $version"
    return 0
}

plugin_update() {
    log_info "Updating Subfinder..."
    go install -v "$PLUGIN_GO_PACKAGE" 2>&1 || return 1
    log_success "Subfinder updated successfully"
    return 0
}

plugin_uninstall() {
    log_info "Uninstalling Subfinder..."
    
    local binary_path="$(go env GOPATH)/bin/subfinder"
    if [[ -f "$binary_path" ]]; then
        rm -f "$binary_path"
        log_success "Removed subfinder binary"
    fi
    
    # Optionally remove config
    local config_dir="$HOME/.config/subfinder"
    if [[ -d "$config_dir" ]]; then
        if ui_confirm "Remove subfinder configuration?" "n"; then
            rm -rf "$config_dir"
            log_success "Removed subfinder configuration"
        fi
    fi
    
    return 0
}

plugin_get_version() {
    if command -v subfinder &>/dev/null; then
        subfinder -version 2>&1 | grep -oP 'v?\d+\.\d+\.\d+' | head -n1 || echo "unknown"
    else
        echo "not installed"
    fi
}

plugin_health_check() {
    log_info "Running Subfinder health check..."
    
    if ! plugin_verify; then
        return 1
    fi
    
    # Check for API keys configuration
    local config_file="$HOME/.config/subfinder/provider-config.yaml"
    if [[ -f "$config_file" ]]; then
        log_success "Provider config found at $config_file"
    else
        log_warning "No provider config found. API sources will be limited."
        log_info "Create config at: $config_file"
    fi
    
    # Test basic functionality
    if subfinder -h &>/dev/null; then
        log_success "Subfinder help command works"
    fi
    
    return 0
}
