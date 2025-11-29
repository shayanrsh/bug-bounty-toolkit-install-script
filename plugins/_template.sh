#!/bin/bash
# ==============================================================================
# Plugin Template for Security Tools Installer
# ==============================================================================
# Copy this file and rename it to create a new plugin.
# Replace all instances of "TOOL_NAME" with your actual tool name.
#
# Plugin Name: TOOL_NAME
# Author: Your Name
# Version: 1.0.0
# Description: Brief description of what this tool does
# ==============================================================================

# Plugin metadata
PLUGIN_NAME="TOOL_NAME"
PLUGIN_VERSION="1.0.0"
PLUGIN_AUTHOR="Your Name"
PLUGIN_DESCRIPTION="Brief description of what this tool does"
PLUGIN_WEBSITE="https://github.com/author/tool"

# Installation method: go, rust, python, binary, apt, snap, git
PLUGIN_INSTALL_METHOD="go"

# For Go tools
PLUGIN_GO_PACKAGE="github.com/author/tool@latest"

# For Python tools
PLUGIN_PYTHON_REPO=""
PLUGIN_PYTHON_REQUIREMENTS=""

# For binary tools
PLUGIN_BINARY_URL=""
PLUGIN_BINARY_CHECKSUM_URL=""

# Dependencies (space-separated)
PLUGIN_DEPENDENCIES=""

# ==============================================================================
# Required Functions
# ==============================================================================

# Return plugin metadata as JSON-like string
plugin_info() {
    cat << EOF
{
    "name": "$PLUGIN_NAME",
    "version": "$PLUGIN_VERSION",
    "author": "$PLUGIN_AUTHOR",
    "description": "$PLUGIN_DESCRIPTION",
    "website": "$PLUGIN_WEBSITE",
    "install_method": "$PLUGIN_INSTALL_METHOD"
}
EOF
}

# Install the tool
plugin_install() {
    log_info "Installing $PLUGIN_NAME..."
    
    # Check dependencies first
    if ! plugin_check_dependencies; then
        log_error "Dependencies not satisfied for $PLUGIN_NAME"
        return 1
    fi
    
    case "$PLUGIN_INSTALL_METHOD" in
        go)
            plugin_install_go
            ;;
        rust)
            plugin_install_rust
            ;;
        python)
            plugin_install_python
            ;;
        binary)
            plugin_install_binary
            ;;
        apt)
            plugin_install_apt
            ;;
        git)
            plugin_install_git
            ;;
        *)
            log_error "Unknown installation method: $PLUGIN_INSTALL_METHOD"
            return 1
            ;;
    esac
    
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        if plugin_verify; then
            log_success "$PLUGIN_NAME installed successfully"
            return 0
        else
            log_error "$PLUGIN_NAME installation verification failed"
            return 1
        fi
    fi
    
    return $result
}

# Verify installation
plugin_verify() {
    log_info "Verifying $PLUGIN_NAME installation..."
    
    # Check if command exists
    if ! command -v "$PLUGIN_NAME" &>/dev/null; then
        log_error "$PLUGIN_NAME command not found in PATH"
        return 1
    fi
    
    # Try to run with version flag
    if ! "$PLUGIN_NAME" --version &>/dev/null && \
       ! "$PLUGIN_NAME" -version &>/dev/null && \
       ! "$PLUGIN_NAME" version &>/dev/null; then
        log_warning "$PLUGIN_NAME is installed but version check failed"
        # Still consider it successful if the binary exists
    fi
    
    log_success "$PLUGIN_NAME verification passed"
    return 0
}

# ==============================================================================
# Optional Functions
# ==============================================================================

# Update the tool
plugin_update() {
    log_info "Updating $PLUGIN_NAME..."
    
    case "$PLUGIN_INSTALL_METHOD" in
        go)
            go install -v "$PLUGIN_GO_PACKAGE" 2>&1
            ;;
        rust)
            cargo install "$PLUGIN_NAME" --force 2>&1
            ;;
        python)
            cd "$TOOLS_DIR/$PLUGIN_NAME" 2>/dev/null && git pull origin main 2>&1
            ;;
        apt)
            sudo apt-get update && sudo apt-get upgrade -y "$PLUGIN_NAME"
            ;;
        *)
            log_warning "Update not implemented for $PLUGIN_INSTALL_METHOD"
            return 1
            ;;
    esac
    
    return $?
}

# Uninstall the tool
plugin_uninstall() {
    log_info "Uninstalling $PLUGIN_NAME..."
    
    case "$PLUGIN_INSTALL_METHOD" in
        go)
            local binary_path="$(go env GOPATH)/bin/$PLUGIN_NAME"
            if [[ -f "$binary_path" ]]; then
                rm -f "$binary_path"
                log_success "Removed $binary_path"
            fi
            ;;
        rust)
            cargo uninstall "$PLUGIN_NAME" 2>/dev/null || true
            ;;
        python)
            rm -rf "$TOOLS_DIR/$PLUGIN_NAME"
            ;;
        apt)
            sudo apt-get remove -y "$PLUGIN_NAME"
            ;;
        binary)
            rm -f "$HOME/.local/bin/$PLUGIN_NAME"
            ;;
        *)
            log_warning "Uninstall not implemented for $PLUGIN_INSTALL_METHOD"
            return 1
            ;;
    esac
    
    log_success "$PLUGIN_NAME uninstalled"
    return 0
}

# Get current version
plugin_get_version() {
    if ! command -v "$PLUGIN_NAME" &>/dev/null; then
        echo "not installed"
        return 1
    fi
    
    local version=""
    
    # Try different version flags
    version=$("$PLUGIN_NAME" --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+(\.\d+)?' || true)
    
    if [[ -z "$version" ]]; then
        version=$("$PLUGIN_NAME" -version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+(\.\d+)?' || true)
    fi
    
    if [[ -z "$version" ]]; then
        version=$("$PLUGIN_NAME" version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+(\.\d+)?' || true)
    fi
    
    echo "${version:-unknown}"
}

# Health check
plugin_health_check() {
    log_info "Running health check for $PLUGIN_NAME..."
    
    # Basic verification
    if ! plugin_verify; then
        return 1
    fi
    
    # Add tool-specific health checks here
    # Example: Run a basic command to test functionality
    # if ! "$PLUGIN_NAME" --help &>/dev/null; then
    #     log_error "$PLUGIN_NAME help command failed"
    #     return 1
    # fi
    
    log_success "$PLUGIN_NAME health check passed"
    return 0
}

# ==============================================================================
# Internal Helper Functions
# ==============================================================================

plugin_check_dependencies() {
    if [[ -z "$PLUGIN_DEPENDENCIES" ]]; then
        return 0
    fi
    
    local missing=()
    for dep in $PLUGIN_DEPENDENCIES; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        return 1
    fi
    
    return 0
}

plugin_install_go() {
    if [[ -z "$PLUGIN_GO_PACKAGE" ]]; then
        log_error "PLUGIN_GO_PACKAGE not set"
        return 1
    fi
    
    if ! command -v go &>/dev/null; then
        log_error "Go is not installed. Install Go first."
        return 1
    fi
    
    log_info "Installing via go install: $PLUGIN_GO_PACKAGE"
    go install -v "$PLUGIN_GO_PACKAGE" 2>&1
    return $?
}

plugin_install_rust() {
    if ! command -v cargo &>/dev/null; then
        log_error "Rust/Cargo is not installed. Install Rust first."
        return 1
    fi
    
    log_info "Installing via cargo: $PLUGIN_NAME"
    cargo install "$PLUGIN_NAME" 2>&1
    return $?
}

plugin_install_python() {
    if [[ -z "$PLUGIN_PYTHON_REPO" ]]; then
        log_error "PLUGIN_PYTHON_REPO not set"
        return 1
    fi
    
    local tool_dir="$TOOLS_DIR/$PLUGIN_NAME"
    
    if [[ -d "$tool_dir" ]]; then
        log_info "$PLUGIN_NAME already cloned, updating..."
        cd "$tool_dir" && git pull origin main 2>&1
        return $?
    fi
    
    log_info "Cloning $PLUGIN_NAME repository..."
    git clone --depth 1 "$PLUGIN_PYTHON_REPO" "$tool_dir" 2>&1 || return 1
    
    cd "$tool_dir" || return 1
    
    # Create virtual environment
    python3 -m venv venv || return 1
    source venv/bin/activate
    
    pip install --upgrade pip
    
    if [[ -n "$PLUGIN_PYTHON_REQUIREMENTS" && -f "$PLUGIN_PYTHON_REQUIREMENTS" ]]; then
        pip install -r "$PLUGIN_PYTHON_REQUIREMENTS"
    elif [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
    fi
    
    deactivate
    return 0
}

plugin_install_binary() {
    if [[ -z "$PLUGIN_BINARY_URL" ]]; then
        log_error "PLUGIN_BINARY_URL not set"
        return 1
    fi
    
    local temp_file="/tmp/$PLUGIN_NAME-download"
    local install_dir="$HOME/.local/bin"
    
    mkdir -p "$install_dir"
    
    log_info "Downloading $PLUGIN_NAME binary..."
    if ! curl -L -o "$temp_file" "$PLUGIN_BINARY_URL" 2>&1; then
        log_error "Failed to download $PLUGIN_NAME"
        return 1
    fi
    
    # Verify checksum if provided
    if [[ -n "$PLUGIN_BINARY_CHECKSUM_URL" ]]; then
        local expected_checksum
        expected_checksum=$(curl -sL "$PLUGIN_BINARY_CHECKSUM_URL" | awk '{print $1}')
        local actual_checksum
        actual_checksum=$(sha256sum "$temp_file" | awk '{print $1}')
        
        if [[ "$expected_checksum" != "$actual_checksum" ]]; then
            log_error "Checksum verification failed"
            rm -f "$temp_file"
            return 1
        fi
        log_success "Checksum verified"
    fi
    
    # Handle archive or direct binary
    if [[ "$temp_file" == *.tar.gz || "$temp_file" == *.tgz ]]; then
        tar -xzf "$temp_file" -C "$install_dir"
    elif [[ "$temp_file" == *.zip ]]; then
        unzip -o "$temp_file" -d "$install_dir"
    else
        mv "$temp_file" "$install_dir/$PLUGIN_NAME"
        chmod +x "$install_dir/$PLUGIN_NAME"
    fi
    
    rm -f "$temp_file"
    return 0
}

plugin_install_apt() {
    log_info "Installing $PLUGIN_NAME via apt..."
    sudo apt-get update && sudo apt-get install -y "$PLUGIN_NAME"
    return $?
}

plugin_install_git() {
    if [[ -z "$PLUGIN_PYTHON_REPO" ]]; then
        log_error "Repository URL not set"
        return 1
    fi
    
    local tool_dir="$TOOLS_DIR/$PLUGIN_NAME"
    
    if [[ -d "$tool_dir" ]]; then
        log_info "$PLUGIN_NAME already cloned"
        return 0
    fi
    
    git clone --depth 1 "$PLUGIN_PYTHON_REPO" "$tool_dir" 2>&1
    return $?
}
