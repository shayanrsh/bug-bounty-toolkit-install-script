#!/bin/bash
# ==============================================================================
# Nuclei Plugin - Vulnerability Scanner
# ==============================================================================
# Plugin Name: nuclei
# Author: ProjectDiscovery
# Version: 1.0.0
# Description: Fast and customizable vulnerability scanner based on templates
# ==============================================================================

PLUGIN_NAME="nuclei"
PLUGIN_VERSION="1.0.0"
PLUGIN_AUTHOR="ProjectDiscovery"
PLUGIN_DESCRIPTION="Fast and customizable vulnerability scanner based on simple YAML templates"
PLUGIN_WEBSITE="https://github.com/projectdiscovery/nuclei"
PLUGIN_INSTALL_METHOD="go"
PLUGIN_GO_PACKAGE="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
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
    "category": "vulnerability_scanner"
}
EOF
}

plugin_install() {
    log_info "Installing Nuclei vulnerability scanner..."
    
    # Check for Go
    if ! command -v go &>/dev/null; then
        log_error "Go is required to install Nuclei"
        return 1
    fi
    
    # Install nuclei
    log_info "Installing nuclei via go install..."
    if ! go install -v "$PLUGIN_GO_PACKAGE" 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Failed to install nuclei"
        return 1
    fi
    
    # Verify installation
    if ! plugin_verify; then
        return 1
    fi
    
    # Download templates
    log_info "Downloading nuclei templates..."
    nuclei -update-templates -silent 2>&1 || log_warning "Template update failed (can retry later)"
    
    log_success "Nuclei installed successfully!"
    return 0
}

plugin_verify() {
    if ! command -v nuclei &>/dev/null; then
        log_error "Nuclei command not found in PATH"
        return 1
    fi
    
    local version
    version=$(nuclei -version 2>&1 | head -n1 || echo "unknown")
    log_success "Nuclei verified: $version"
    return 0
}

plugin_update() {
    log_info "Updating Nuclei..."
    
    # Update binary
    go install -v "$PLUGIN_GO_PACKAGE" 2>&1 || return 1
    
    # Update templates
    log_info "Updating nuclei templates..."
    nuclei -update-templates -silent 2>&1 || log_warning "Template update failed"
    
    log_success "Nuclei updated successfully"
    return 0
}

plugin_uninstall() {
    log_info "Uninstalling Nuclei..."
    
    local binary_path="$(go env GOPATH)/bin/nuclei"
    if [[ -f "$binary_path" ]]; then
        rm -f "$binary_path"
        log_success "Removed nuclei binary"
    fi
    
    # Optionally remove templates
    local templates_dir="$HOME/nuclei-templates"
    if [[ -d "$templates_dir" ]]; then
        if ui_confirm "Remove nuclei templates directory?" "n"; then
            rm -rf "$templates_dir"
            log_success "Removed nuclei templates"
        fi
    fi
    
    return 0
}

plugin_get_version() {
    if command -v nuclei &>/dev/null; then
        nuclei -version 2>&1 | grep -oP 'v?\d+\.\d+\.\d+' | head -n1 || echo "unknown"
    else
        echo "not installed"
    fi
}

plugin_health_check() {
    log_info "Running Nuclei health check..."
    
    if ! plugin_verify; then
        return 1
    fi
    
    # Check templates exist
    local templates_dir="$HOME/nuclei-templates"
    if [[ ! -d "$templates_dir" ]]; then
        log_warning "Nuclei templates not found at $templates_dir"
        log_info "Run: nuclei -update-templates"
    else
        local template_count
        template_count=$(find "$templates_dir" -name "*.yaml" 2>/dev/null | wc -l)
        log_success "Found $template_count nuclei templates"
    fi
    
    # Test basic functionality
    if nuclei --help &>/dev/null; then
        log_success "Nuclei help command works"
    else
        log_warning "Nuclei help command failed"
    fi
    
    return 0
}
