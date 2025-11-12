#!/bin/bash
# ==============================================================================
# Plugin System Architecture for Security Tools Installer
# ==============================================================================
# This module implements a plugin-based architecture for tool installation
# ==============================================================================

# Plugin directory
readonly PLUGINS_DIR="${SCRIPT_DIR}/plugins"
readonly USER_PLUGINS_DIR="${HOME}/.security-tools/plugins"

# Plugin registry
declare -A PLUGIN_REGISTRY=()
declare -A PLUGIN_METADATA=()

# ==============================================================================
# Plugin Interface
# ==============================================================================
# Each plugin must implement these functions:
#   - plugin_install()    : Install the tool
#   - plugin_verify()     : Verify installation
#   - plugin_update()     : Update the tool (optional)
#   - plugin_uninstall()  : Remove the tool (optional)
#   - plugin_info()       : Return metadata (optional)
# ==============================================================================

# Load a plugin from file
# Usage: plugin_load "plugin_name" "/path/to/plugin.sh"
plugin_load() {
    local plugin_name="$1"
    local plugin_file="$2"
    
    if [[ ! -f "$plugin_file" ]]; then
        log_error "Plugin file not found: $plugin_file"
        return 1
    fi
    
    log_debug "Loading plugin: $plugin_name from $plugin_file"
    
    # Source the plugin in a subshell to validate
    if ! (source "$plugin_file" && declare -f plugin_install >/dev/null); then
        log_error "Plugin $plugin_name does not implement required function: plugin_install"
        return 1
    fi
    
    # Source the plugin
    # shellcheck disable=SC1090
    source "$plugin_file"
    
    # Register plugin
    PLUGIN_REGISTRY["$plugin_name"]="$plugin_file"
    
    # Load metadata if available
    if declare -f plugin_info >/dev/null; then
        PLUGIN_METADATA["$plugin_name"]=$(plugin_info)
    fi
    
    log_success "Loaded plugin: $plugin_name"
    return 0
}

# Discover and load all plugins
plugin_discover() {
    log_info "Discovering plugins..."
    
    local plugin_dirs=("$PLUGINS_DIR" "$USER_PLUGINS_DIR")
    local loaded_count=0
    
    for dir in "${plugin_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            continue
        fi
        
        # Load all .sh files in plugins directory
        while IFS= read -r -d '' plugin_file; do
            local plugin_name
            plugin_name=$(basename "$plugin_file" .sh)
            
            if plugin_load "$plugin_name" "$plugin_file"; then
                ((loaded_count++))
            fi
        done < <(find "$dir" -maxdepth 1 -name "*.sh" -type f -print0 2>/dev/null)
    done
    
    log_info "Loaded $loaded_count plugin(s)"
}

# Install a tool using its plugin
# Usage: plugin_install_tool "plugin_name"
plugin_install_tool() {
    local plugin_name="$1"
    
    if [[ -z "${PLUGIN_REGISTRY[$plugin_name]}" ]]; then
        log_error "Plugin not found: $plugin_name"
        return 1
    fi
    
    log_info "Installing via plugin: $plugin_name"
    
    # Call plugin's install function
    if plugin_install; then
        log_success "Plugin installation completed: $plugin_name"
        return 0
    else
        log_error "Plugin installation failed: $plugin_name"
        return 1
    fi
}

# Verify a tool using its plugin
# Usage: plugin_verify_tool "plugin_name"
plugin_verify_tool() {
    local plugin_name="$1"
    
    if [[ -z "${PLUGIN_REGISTRY[$plugin_name]}" ]]; then
        log_error "Plugin not found: $plugin_name"
        return 1
    fi
    
    if ! declare -f plugin_verify >/dev/null; then
        log_warning "Plugin $plugin_name does not implement plugin_verify"
        return 0  # Assume success if not implemented
    fi
    
    if plugin_verify; then
        log_success "Plugin verification passed: $plugin_name"
        return 0
    else
        log_error "Plugin verification failed: $plugin_name"
        return 1
    fi
}

# Update a tool using its plugin
# Usage: plugin_update_tool "plugin_name"
plugin_update_tool() {
    local plugin_name="$1"
    
    if [[ -z "${PLUGIN_REGISTRY[$plugin_name]}" ]]; then
        log_error "Plugin not found: $plugin_name"
        return 1
    fi
    
    if ! declare -f plugin_update >/dev/null; then
        log_warning "Plugin $plugin_name does not implement plugin_update"
        log_info "Falling back to reinstall..."
        return plugin_install_tool "$plugin_name"
    fi
    
    log_info "Updating via plugin: $plugin_name"
    
    if plugin_update; then
        log_success "Plugin update completed: $plugin_name"
        return 0
    else
        log_error "Plugin update failed: $plugin_name"
        return 1
    fi
}

# Uninstall a tool using its plugin
# Usage: plugin_uninstall_tool "plugin_name"
plugin_uninstall_tool() {
    local plugin_name="$1"
    
    if [[ -z "${PLUGIN_REGISTRY[$plugin_name]}" ]]; then
        log_error "Plugin not found: $plugin_name"
        return 1
    fi
    
    if ! declare -f plugin_uninstall >/dev/null; then
        log_warning "Plugin $plugin_name does not implement plugin_uninstall"
        return 1
    fi
    
    log_info "Uninstalling via plugin: $plugin_name"
    
    if plugin_uninstall; then
        log_success "Plugin uninstallation completed: $plugin_name"
        return 0
    else
        log_error "Plugin uninstallation failed: $plugin_name"
        return 1
    fi
}

# List all loaded plugins
plugin_list() {
    echo "Loaded Plugins:"
    echo "==============="
    
    for plugin_name in "${!PLUGIN_REGISTRY[@]}"; do
        local plugin_file="${PLUGIN_REGISTRY[$plugin_name]}"
        local metadata="${PLUGIN_METADATA[$plugin_name]:-No description}"
        
        echo "  • $plugin_name"
        echo "    File: $plugin_file"
        echo "    Info: $metadata"
        echo ""
    done
}

# Get plugin information
# Usage: plugin_get_info "plugin_name"
plugin_get_info() {
    local plugin_name="$1"
    
    if [[ -z "${PLUGIN_REGISTRY[$plugin_name]}" ]]; then
        return 1
    fi
    
    echo "${PLUGIN_METADATA[$plugin_name]:-No information available}"
}

# Create example plugin
plugin_create_example() {
    local example_file="$PLUGINS_DIR/example_tool.sh"
    
    mkdir -p "$PLUGINS_DIR"
    
    cat > "$example_file" << 'EOF'
#!/bin/bash
# Example Plugin for Security Tools Installer
# 
# This demonstrates the plugin interface that all plugins must implement

# Plugin metadata (optional but recommended)
plugin_info() {
    echo "Example Tool - A demonstration plugin"
}

# Required: Install the tool
plugin_install() {
    log_info "Installing example tool..."
    
    # Your installation logic here
    # Example: Download binary, compile from source, install via package manager
    
    if ! command -v example_tool >/dev/null 2>&1; then
        log_error "Installation failed"
        return 1
    fi
    
    log_success "Example tool installed successfully"
    return 0
}

# Required: Verify the tool is installed and working
plugin_verify() {
    if ! command -v example_tool >/dev/null 2>&1; then
        log_error "Example tool not found"
        return 1
    fi
    
    # Optional: Test that tool actually works
    if ! example_tool --version >/dev/null 2>&1; then
        log_error "Example tool is installed but not working"
        return 1
    fi
    
    log_success "Example tool verification passed"
    return 0
}

# Optional: Update the tool
plugin_update() {
    log_info "Updating example tool..."
    
    # Your update logic here
    # Example: Pull latest version, update via package manager
    
    log_success "Example tool updated successfully"
    return 0
}

# Optional: Uninstall the tool
plugin_uninstall() {
    log_info "Uninstalling example tool..."
    
    # Your uninstallation logic here
    # Example: Remove binary, clean up config files
    
    log_success "Example tool uninstalled successfully"
    return 0
}

# Optional: Get version information
plugin_get_version() {
    if command -v example_tool >/dev/null 2>&1; then
        example_tool --version 2>/dev/null | head -n1
    else
        echo "not installed"
    fi
}

# Optional: Health check
plugin_health_check() {
    if ! plugin_verify; then
        log_warning "Example tool failed health check"
        return 1
    fi
    
    log_success "Example tool is healthy"
    return 0
}
EOF
    
    chmod +x "$example_file"
    log_success "Created example plugin: $example_file"
}

# Initialize plugin system
plugin_init() {
    mkdir -p "$PLUGINS_DIR" "$USER_PLUGINS_DIR"
    
    # Create example if plugins dir is empty
    if [[ ! -f "$PLUGINS_DIR/example_tool.sh" ]]; then
        plugin_create_example
    fi
    
    # Discover and load plugins
    plugin_discover
}
