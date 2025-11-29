#!/bin/bash
# ==============================================================================
# SQLMap Plugin - SQL Injection Tool
# ==============================================================================
# Plugin Name: sqlmap
# Author: sqlmapproject
# Version: 1.0.0
# Description: Automatic SQL injection and database takeover tool
# ==============================================================================

PLUGIN_NAME="sqlmap"
PLUGIN_VERSION="1.0.0"
PLUGIN_AUTHOR="sqlmapproject"
PLUGIN_DESCRIPTION="Automatic SQL injection and database takeover tool"
PLUGIN_WEBSITE="https://github.com/sqlmapproject/sqlmap"
PLUGIN_INSTALL_METHOD="python"
PLUGIN_PYTHON_REPO="https://github.com/sqlmapproject/sqlmap.git"
PLUGIN_DEPENDENCIES="python3 git"

plugin_info() {
    cat << EOF
{
    "name": "$PLUGIN_NAME",
    "version": "$PLUGIN_VERSION",
    "author": "$PLUGIN_AUTHOR",
    "description": "$PLUGIN_DESCRIPTION",
    "website": "$PLUGIN_WEBSITE",
    "install_method": "$PLUGIN_INSTALL_METHOD",
    "category": "exploitation"
}
EOF
}

plugin_install() {
    log_info "Installing SQLMap..."
    
    local tool_dir="${TOOLS_DIR:-$HOME/tools}/sqlmap"
    
    if [[ -d "$tool_dir" ]]; then
        log_info "SQLMap already installed at $tool_dir"
        log_info "Updating..."
        cd "$tool_dir" && git pull origin master 2>&1
        return $?
    fi
    
    # Clone repository
    log_info "Cloning SQLMap repository..."
    mkdir -p "$(dirname "$tool_dir")"
    
    if ! git clone --depth 1 "$PLUGIN_PYTHON_REPO" "$tool_dir" 2>&1; then
        log_error "Failed to clone SQLMap"
        return 1
    fi
    
    # Create wrapper script
    local wrapper_script="${SCRIPTS_DIR:-$HOME/tools/scripts}/sqlmap"
    mkdir -p "$(dirname "$wrapper_script")"
    
    cat > "$wrapper_script" << EOF
#!/bin/bash
# SQLMap wrapper script
python3 "$tool_dir/sqlmap.py" "\$@"
EOF
    chmod +x "$wrapper_script"
    
    # Verify installation
    if plugin_verify; then
        log_success "SQLMap installed successfully!"
        log_info "Usage: sqlmap -h or python3 $tool_dir/sqlmap.py -h"
        return 0
    fi
    
    return 1
}

plugin_verify() {
    local tool_dir="${TOOLS_DIR:-$HOME/tools}/sqlmap"
    
    if [[ ! -f "$tool_dir/sqlmap.py" ]]; then
        log_error "SQLMap not found at $tool_dir"
        return 1
    fi
    
    # Test that it runs
    if python3 "$tool_dir/sqlmap.py" --version &>/dev/null; then
        local version
        version=$(python3 "$tool_dir/sqlmap.py" --version 2>&1 | head -n1)
        log_success "SQLMap verified: $version"
        return 0
    fi
    
    log_error "SQLMap verification failed"
    return 1
}

plugin_update() {
    log_info "Updating SQLMap..."
    
    local tool_dir="${TOOLS_DIR:-$HOME/tools}/sqlmap"
    
    if [[ ! -d "$tool_dir" ]]; then
        log_error "SQLMap not installed"
        return 1
    fi
    
    cd "$tool_dir" || return 1
    git pull origin master 2>&1
    
    log_success "SQLMap updated successfully"
    return 0
}

plugin_uninstall() {
    log_info "Uninstalling SQLMap..."
    
    local tool_dir="${TOOLS_DIR:-$HOME/tools}/sqlmap"
    local wrapper_script="${SCRIPTS_DIR:-$HOME/tools/scripts}/sqlmap"
    
    if [[ -d "$tool_dir" ]]; then
        rm -rf "$tool_dir"
        log_success "Removed SQLMap directory"
    fi
    
    if [[ -f "$wrapper_script" ]]; then
        rm -f "$wrapper_script"
        log_success "Removed wrapper script"
    fi
    
    return 0
}

plugin_get_version() {
    local tool_dir="${TOOLS_DIR:-$HOME/tools}/sqlmap"
    
    if [[ -f "$tool_dir/sqlmap.py" ]]; then
        python3 "$tool_dir/sqlmap.py" --version 2>&1 | grep -oP '\d+\.\d+(\.\d+)?' | head -n1 || echo "unknown"
    else
        echo "not installed"
    fi
}

plugin_health_check() {
    log_info "Running SQLMap health check..."
    
    if ! plugin_verify; then
        return 1
    fi
    
    local tool_dir="${TOOLS_DIR:-$HOME/tools}/sqlmap"
    
    # Check for tamper scripts
    local tamper_count
    tamper_count=$(ls -1 "$tool_dir/tamper/"*.py 2>/dev/null | wc -l)
    log_info "Found $tamper_count tamper scripts"
    
    # Test help output
    if python3 "$tool_dir/sqlmap.py" -h &>/dev/null; then
        log_success "SQLMap help command works"
    else
        log_warning "SQLMap help command failed"
    fi
    
    log_success "SQLMap health check passed"
    return 0
}
