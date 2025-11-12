#!/bin/bash
# ==============================================================================
# Security Tools Installer - Tool Installation Module
# ==============================================================================
# Purpose: Tool-specific installation functions (modular plugin system)
# ==============================================================================

# shellcheck disable=SC2155,SC2317

# ==============================================================================
# ZSH Installation Module
# ==============================================================================

tool_install_zsh() {
    ui_section_header "Installing ZSH Environment" "$BLUE"
    
    # Install ZSH and required packages
    log_info "Installing ZSH and prerequisites..."
    
    local packages=()
    for pkg in "${!ZSH_PACKAGES[@]}"; do
        if ! util_package_installed "${ZSH_PACKAGES[$pkg]}"; then
            packages+=("${ZSH_PACKAGES[$pkg]}")
        fi
    done
    
    if [[ ${#packages[@]} -gt 0 ]]; then
        log_info "Installing ${#packages[@]} package(s): ${packages[*]}"
        
        if [[ "$DRY_RUN" == "false" ]]; then
            # Update package lists with progress
            if ! ui_exec_with_progress "Updating package lists" sudo apt-get update -qq; then
                log_warning "Package list update had warnings (continuing...)"
            fi
            
            # Install packages with progress
            if ! ui_exec_with_progress "Installing ZSH packages (${#packages[@]} packages)" \
                sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${packages[@]}"; then
                log_error "Failed to install packages"
                return 1
            fi
        else
            log_info "[DRY RUN] Would update package lists"
            log_info "[DRY RUN] Would install: ${packages[*]}"
        fi
    else
        log_success "All required packages already installed"
    fi
    
    # Verify ZSH installation
    if util_command_exists zsh; then
        local version=$(util_get_tool_version zsh)
        log_success "ZSH $version installed"
        util_manifest_add_tool "shell" "zsh" "$version" "/usr/bin/zsh"
    else
        log_error "ZSH installation failed"
        return 1
    fi
    
    # Install Oh My ZSH
    tool_install_ohmyzsh || return 1
    
    # Install ZSH plugins
    tool_install_zsh_plugins || return 1
    
    # Configure ZSH
    tool_configure_zsh || return 1
    
    # Set ZSH as default shell (following https://itsfoss.com/zsh-ubuntu/)
    if [[ "$DRY_RUN" == "false" ]] && [[ "$INTERACTIVE" == "true" ]]; then
        if ui_confirm "Set ZSH as default shell?" "y"; then
            chsh -s /bin/zsh
            log_success "ZSH set as default shell (restart required)"
        fi
    fi
    
    rollback_add "tool_uninstall_zsh"
    return 0
}

tool_install_ohmyzsh() {
    local ohmyzsh_dir="$HOME/.oh-my-zsh"
    
    if [[ -d "$ohmyzsh_dir" ]]; then
        log_warning "Oh My ZSH already installed"
        
        if [[ "$FORCE_INSTALL" == "true" ]]; then
            log_info "Updating Oh My ZSH..."
            if [[ "$DRY_RUN" == "false" ]]; then
                cd "$ohmyzsh_dir" && git pull origin master &>/dev/null &
                ui_spinner $! "Updating Oh My ZSH"
                cd - >/dev/null
            fi
        fi
        return 0
    fi
    
    log_info "Installing Oh My ZSH..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install Oh My ZSH"
        return 0
    fi
    
    local install_script=$(util_create_temp_file)
    
    if util_download "https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh" \
                     "$install_script" "Oh My ZSH installer"; then
        chmod +x "$install_script"
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$install_script" &>/dev/null &
        ui_spinner $! "Installing Oh My ZSH"
        rm -f "$install_script"
        
        log_success "Oh My ZSH installed"
        return 0
    else
        log_error "Failed to download Oh My ZSH installer"
        return 1
    fi
}

tool_install_zsh_plugins() {
    log_info "Installing ZSH plugins..."
    
    local total=${#ZSH_PLUGINS[@]}
    local current=0
    
    for plugin_name in "${!ZSH_PLUGINS[@]}"; do
        ((current++))
        
        local plugin_url="${ZSH_PLUGINS[$plugin_name]}"
        local plugin_dir
        
        if [[ "$plugin_name" == "powerlevel10k" ]]; then
            plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/$plugin_name"
        else
            plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name"
        fi
        
        ui_progress_bar "$current" "$total" "Installing $plugin_name"
        
        if [[ ! -d "$plugin_dir" ]]; then
            if [[ "$DRY_RUN" == "false" ]]; then
                util_git_clone "$plugin_url" "$plugin_dir" "$plugin_name" || log_warning "Failed to install $plugin_name"
            else
                log_info "[DRY RUN] Would install plugin: $plugin_name"
            fi
        else
            log_debug "$plugin_name already installed"
        fi
    done
    
    echo # New line after progress bar
    return 0
}

tool_configure_zsh() {
    log_info "Configuring ZSH..."
    
    local zshrc="$HOME/.zshrc"
    
    if [[ -f "$zshrc" ]]; then
        util_backup_file "$zshrc"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would configure ZSH"
        return 0
    fi
    
    cat > "$zshrc" << 'EOF'
# Oh My ZSH Configuration
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    command-not-found
    sudo
)

source $ZSH/oh-my-zsh.sh

# Go environment
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Rust environment
export PATH=$PATH:$HOME/.cargo/bin

# Python/Pipx environment
export PATH=$PATH:$HOME/.local/bin

# Tools directory
export PATH=$PATH:$HOME/tools:$HOME/tools/scripts

# Security Tools Aliases
[[ -f ~/.security_aliases ]] && source ~/.security_aliases

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run: p10k configure
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF
    
    log_success "ZSH configured"
    return 0
}

tool_uninstall_zsh() {
    log_warning "Uninstalling ZSH..."
    [[ "$DRY_RUN" == "false" ]] && rm -rf "$HOME/.oh-my-zsh" "$HOME/.zshrc"
}

# ==============================================================================
# Go Installation Module
# ==============================================================================

tool_install_go() {
    ui_section_header "Installing Go Programming Language" "$PURPLE"
    
    local go_version="1.22.4"
    local go_url="https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
    
    if util_command_exists go; then
        local current_version=$(util_get_tool_version go)
        log_success "Go $current_version is already installed"
        
        if [[ "$current_version" == "$go_version" ]]; then
            return 0
        fi
        
        if [[ "$INTERACTIVE" == "true" ]]; then
            ui_confirm "Update Go from $current_version to $go_version?" "n" || return 0
        elif [[ "$FORCE_INSTALL" == "false" ]]; then
            return 0
        fi
    fi
    
    log_info "Installing Go $go_version..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install Go $go_version"
        return 0
    fi
    
    local temp_file=$(util_create_temp_file)
    
    if util_download "$go_url" "$temp_file" "Go $go_version"; then
        log_info "Extracting Go..."
        
        sudo rm -rf /usr/local/go &>/dev/null &
        ui_spinner $! "Removing old Go installation"
        
        sudo tar -C /usr/local -xzf "$temp_file" &>/dev/null &
        ui_spinner $! "Extracting Go archive"
        
        rm -f "$temp_file"
        
        # Verify installation
        if /usr/local/go/bin/go version &>/dev/null; then
            util_add_to_path "/usr/local/go/bin"
            local version=$(util_get_tool_version go)
            log_success "Go $version installed successfully"
            util_manifest_add_tool "languages" "go" "$version" "/usr/local/go"
            rollback_add "tool_uninstall_go"
            return 0
        else
            log_error "Go installation verification failed"
            return 1
        fi
    else
        log_error "Failed to download Go"
        rm -f "$temp_file"
        return 1
    fi
}

tool_uninstall_go() {
    log_warning "Uninstalling Go..."
    [[ "$DRY_RUN" == "false" ]] && sudo rm -rf /usr/local/go
}

# ==============================================================================
# Rust Installation Module
# ==============================================================================

tool_install_rust() {
    ui_section_header "Installing Rust Programming Language" "$CYAN"
    
    if util_command_exists rustc; then
        local version=$(util_get_tool_version rustc)
        log_success "Rust $version is already installed"
        
        if [[ "$INTERACTIVE" == "true" ]]; then
            if ui_confirm "Update Rust to latest version?" "n"; then
                [[ "$DRY_RUN" == "false" ]] && rustup update
            fi
        fi
        return 0
    fi
    
    log_info "Installing Rust..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would install Rust"
        return 0
    fi
    
    local rust_installer=$(util_create_temp_file)
    
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$rust_installer"; then
        chmod +x "$rust_installer"
        "$rust_installer" -y --default-toolchain stable &>/dev/null &
        ui_spinner $! "Installing Rust"
        rm -f "$rust_installer"
        
        # Source Rust environment
        util_source_env "$HOME/.cargo/env"
        
        if util_command_exists rustc; then
            local version=$(util_get_tool_version rustc)
            log_success "Rust $version installed successfully"
            util_manifest_add_tool "languages" "rust" "$version" "$HOME/.cargo"
            rollback_add "tool_uninstall_rust"
            return 0
        else
            log_error "Rust installation verification failed"
            return 1
        fi
    else
        log_error "Failed to download Rust installer"
        rm -f "$rust_installer"
        return 1
    fi
}

tool_uninstall_rust() {
    log_warning "Uninstalling Rust..."
    [[ "$DRY_RUN" == "false" ]] && rustup self uninstall -y
}

# ==============================================================================
# Go Tools Installation Module
# ==============================================================================

tool_install_go_tools() {
    ui_section_header "Installing Go-based Security Tools" "$GREEN"
    
    # Ensure Go is installed
    if ! util_command_exists go; then
        log_error "Go is not installed. Installing Go first..."
        tool_install_go || return 1
    fi
    
    util_add_to_path "/usr/local/go/bin"
    util_add_to_path "$(go env GOPATH)/bin"
    
    local total=${#GO_TOOLS[@]}
    local current=0
    local failed_tools=()
    
    for tool_pkg in "${!GO_TOOLS[@]}"; do
        ((current++))
        
        local tool_info="${GO_TOOLS[$tool_pkg]}"
        local tool_path="${tool_info%%|*}"
        local description="${tool_info##*|}"
        
        ui_progress_bar "$current" "$total" "Installing $tool_pkg"
        
        log_info "Installing $tool_pkg: $description"
        
        if [[ "$DRY_RUN" == "false" ]]; then
            if go install -v "$tool_path" &>/dev/null; then
                log_success "$tool_pkg installed"
                local version=$(util_get_tool_version "$tool_pkg")
                util_manifest_add_tool "go_tools" "$tool_pkg" "$version" "$(go env GOPATH)/bin/$tool_pkg"
            else
                log_error "Failed to install $tool_pkg"
                failed_tools+=("$tool_pkg")
            fi
        else
            log_info "[DRY RUN] Would install: $tool_pkg"
        fi
    done
    
    echo # New line after progress bar
    
    if [[ ${#failed_tools[@]} -gt 0 ]]; then
        log_warning "Failed to install: ${failed_tools[*]}"
    fi
    
    rollback_add "tool_uninstall_go_tools"
    return 0
}

tool_uninstall_go_tools() {
    log_warning "Removing Go tools..."
    if [[ "$DRY_RUN" == "false" ]] && util_command_exists go; then
        local gobin="$(go env GOPATH)/bin"
        for tool in "${!GO_TOOLS[@]}"; do
            rm -f "$gobin/$tool"
        done
    fi
}

# ==============================================================================
# Python Tools Installation Module
# ==============================================================================

tool_install_python_tools() {
    ui_section_header "Installing Python-based Security Tools" "$YELLOW"
    
    mkdir -p "$TOOLS_DIR"
    local original_dir=$(pwd)
    
    local total=${#PYTHON_TOOLS[@]}
    local current=0
    
    for tool_name in "${!PYTHON_TOOLS[@]}"; do
        ((current++))
        
        local tool_info="${PYTHON_TOOLS[$tool_name]}"
        IFS='|' read -r install_type repo_url description requirements install_script <<< "$tool_info"
        
        ui_progress_bar "$current" "$total" "Installing $tool_name"
        
        local tool_dir="$TOOLS_DIR/$tool_name"
        
        if [[ -d "$tool_dir" ]]; then
            log_warning "$tool_name already installed at $tool_dir"
            continue
        fi
        
        log_info "Installing $tool_name: $description"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would install: $tool_name"
            continue
        fi
        
        # Clone repository
        if ! util_git_clone "$repo_url" "$tool_dir" "$tool_name"; then
            log_error "Failed to clone $tool_name"
            continue
        fi
        
        # Setup virtual environment if requirements exist
        if [[ -n "$requirements" ]] && [[ -f "$tool_dir/$requirements" ]]; then
            log_info "Creating virtual environment for $tool_name..."
            cd "$tool_dir" || continue
            
            python3 -m venv "${tool_name}Env" &>/dev/null &
            ui_spinner $! "Creating venv for $tool_name"
            
            # shellcheck disable=SC1091
            source "${tool_name}Env/bin/activate"
            pip install --upgrade pip setuptools wheel &>/dev/null
            pip install -r "$requirements" &>/dev/null &
            ui_spinner $! "Installing Python dependencies for $tool_name"
            
            # Run install script if exists
            if [[ -n "$install_script" ]] && [[ -f "$install_script" ]]; then
                bash "$install_script" &>/dev/null
            fi
            
            deactivate
            cd "$original_dir" || return 1
        fi
        
        log_success "$tool_name installed"
        util_manifest_add_tool "python_tools" "$tool_name" "git-latest" "$tool_dir"
    done
    
    echo # New line after progress bar
    
    rollback_add "tool_uninstall_python_tools"
    return 0
}

tool_uninstall_python_tools() {
    log_warning "Removing Python tools..."
    [[ "$DRY_RUN" == "false" ]] && rm -rf "$TOOLS_DIR"
}

# ==============================================================================
# Other Tools (APT, Snap, Pipx)
# ==============================================================================

tool_install_apt_tools() {
    ui_section_header "Installing Tools via APT" "$BLUE"
    
    local packages=()
    for pkg in "${!APT_TOOLS[@]}"; do
        if ! util_package_installed "$pkg"; then
            packages+=("$pkg")
        fi
    done
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_success "All APT tools already installed"
        return 0
    fi
    
    log_info "Installing APT packages: ${packages[*]}"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        sudo apt-get update -qq &
        ui_spinner $! "Updating package lists"
        
        sudo apt-get install -y "${packages[@]}" &>/dev/null &
        ui_spinner $! "Installing APT packages"
        
        log_success "APT tools installed"
    else
        log_info "[DRY RUN] Would install: ${packages[*]}"
    fi
    
    return 0
}

tool_install_snap_tools() {
    if util_is_wsl; then
        log_warning "WSL detected - snap tools may have limited functionality"
    fi
    
    for tool in "${!SNAP_TOOLS[@]}"; do
        if [[ "$DRY_RUN" == "false" ]]; then
            if ! snap list "$tool" &>/dev/null; then
                log_info "Installing $tool via snap..."
                sudo snap install "$tool" &>/dev/null &
                ui_spinner $! "Installing $tool"
            fi
        else
            log_info "[DRY RUN] Would install snap: $tool"
        fi
    done
    
    return 0
}

tool_install_pipx_tools() {
    # Ensure pipx is installed
    if ! util_command_exists pipx; then
        log_info "Installing pipx..."
        [[ "$DRY_RUN" == "false" ]] && sudo apt-get install -y pipx &>/dev/null
        pipx ensurepath &>/dev/null
    fi
    
    for tool in "${!PIPX_TOOLS[@]}"; do
        if [[ "$DRY_RUN" == "false" ]]; then
            if ! pipx list 2>/dev/null | grep -q "^  package $tool "; then
                log_info "Installing $tool via pipx..."
                pipx install "$tool" &>/dev/null &
                ui_spinner $! "Installing $tool"
            fi
        else
            log_info "[DRY RUN] Would install pipx: $tool"
        fi
    done
    
    return 0
}

# ==============================================================================
# Wordlists Installation Module
# ==============================================================================

tool_install_wordlists() {
    ui_section_header "Installing Wordlists" "$PURPLE"
    
    mkdir -p "$WORDLISTS_DIR"
    local original_dir=$(pwd)
    cd "$WORDLISTS_DIR" || return 1
    
    local total=${#WORDLISTS[@]}
    local current=0
    
    for wordlist_name in "${!WORDLISTS[@]}"; do
        ((current++))
        
        local wordlist_info="${WORDLISTS[$wordlist_name]}"
        IFS='|' read -r url type dest <<< "$wordlist_info"
        
        ui_progress_bar "$current" "$total" "Installing $wordlist_name"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would install wordlist: $wordlist_name"
            continue
        fi
        
        case "$type" in
            git)
                if [[ ! -d "$dest" ]]; then
                    util_git_clone "$url" "$dest" "$wordlist_name"
                fi
                ;;
            file)
                local dir=$(dirname "$dest")
                mkdir -p "$dir"
                util_download "$url" "$dest" "$wordlist_name"
                ;;
            *)
                # ZIP file
                if [[ ! -d "$dest" ]]; then
                    local temp_zip=$(util_create_temp_file)
                    util_download "$url" "$temp_zip" "$wordlist_name"
                    unzip -q "$temp_zip" -d .
                    mv "$type" "$dest" 2>/dev/null || true
                    rm -f "$temp_zip"
                fi
                ;;
        esac
    done
    
    echo # New line
    cd "$original_dir" || return 1
    
    log_success "Wordlists installed at $WORDLISTS_DIR"
    rollback_add "tool_uninstall_wordlists"
    return 0
}

tool_uninstall_wordlists() {
    log_warning "Removing wordlists..."
    [[ "$DRY_RUN" == "false" ]] && rm -rf "$WORDLISTS_DIR"
}

# ==============================================================================
# Helper Scripts Creation
# ==============================================================================

tool_create_helper_scripts() {
    mkdir -p "$SCRIPTS_DIR"
    
    log_info "Creating helper scripts..."
    
    # Python environment activation helper
    cat > "$SCRIPTS_DIR/activate_python_tools.sh" << 'EOF'
#!/bin/bash
# Helper script to activate Python tool environments

TOOLS_DIR="$HOME/tools"

activate_tool() {
    local tool=$1
    local env_path="$TOOLS_DIR/$tool/${tool}Env/bin/activate"
    
    if [[ -f "$env_path" ]]; then
        source "$env_path"
        echo "✓ $tool environment activated"
    else
        echo "✗ Environment not found for $tool"
        return 1
    fi
}

# Auto-complete function names
list_tools() {
    echo "Available Python tools:"
    for dir in "$TOOLS_DIR"/*/; do
        local tool=$(basename "$dir")
        if [[ -d "$dir/${tool}Env" ]]; then
            echo "  - $tool"
        fi
    done
}

if [[ $# -eq 0 ]]; then
    list_tools
else
    activate_tool "$1"
fi
EOF
    
    chmod +x "$SCRIPTS_DIR/activate_python_tools.sh"
    
    # Security aliases
    cat > "$HOME/.security_aliases" << 'EOF'
# Security Tools Aliases
# Auto-generated by Security Tools Installer

# Nuclei
alias nuclei-update='nuclei -update-templates'

# Tool directories
alias tools='cd ~/tools && ls -la'
alias wordlists='cd ~/wordlists && ls -la'

# Python tool activation
alias activate-tool='source ~/tools/scripts/activate_python_tools.sh'

# Quick commands
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
EOF
    
    log_success "Helper scripts created"
    return 0
}
