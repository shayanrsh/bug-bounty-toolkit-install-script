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
            # Wait for apt lock if needed
            util_wait_for_apt_lock || {
                log_error "Cannot proceed with package installation"
                return 1
            }

            if ! util_apt_update; then
                log_error "Failed to update package lists"
                return 1
            fi

            log_info "Installing ${#packages[@]} package(s): ${packages[*]}"
            if ! ui_stream_command "Installing ZSH packages" sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"; then
                log_error "Failed to install packages"
                return 1
            fi
            log_success "ZSH and packages installed successfully"
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
            if chsh -s /bin/zsh; then
                # Verify ZSH was set as default
                if grep -q "^$(whoami):" /etc/passwd | grep -q "/bin/zsh"; then
                    log_success "ZSH successfully set as default shell"
                else
                    local current_shell
                    current_shell=$(getent passwd "$(whoami)" | cut -d: -f7)
                    log_warning "ZSH set command executed, but current shell is still: $current_shell"
                    log_info "Please logout and login again for changes to take effect"
                fi
                log_info "Restart your terminal or run 'exec zsh' to use ZSH now"
            else
                log_error "Failed to set ZSH as default shell"
            fi
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
        ((current+=1))
        
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
    
    # Fetch latest Go version from go.dev
    log_info "Fetching latest Go version from go.dev..."
    local go_version
    go_version=$(curl -sSL 'https://go.dev/VERSION?m=text' 2>/dev/null | head -n1 | sed 's/go//')
    
    if [[ -z "$go_version" ]]; then
        log_warning "Failed to fetch latest version, using fallback version"
        go_version="1.23.3"
    fi
    
    log_info "Latest Go version: $go_version"
    local go_url="https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
    
    if util_command_exists go; then
        local current_version=$(go version | awk '{print $3}' | sed 's/go//')
        log_success "Go $current_version is already installed"
        
        if [[ "$current_version" == "$go_version" ]]; then
            util_setup_go_env
            return 0
        fi
        
        if [[ "$INTERACTIVE" == "true" ]]; then
            ui_confirm "Update Go from $current_version to $go_version?" "y" || {
                util_setup_go_env
                return 0
            }
        elif [[ "$FORCE_INSTALL" == "false" ]]; then
            util_setup_go_env
            return 0
        fi
    fi
    
    log_info "Installing Go $go_version..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would download: $go_url"
        log_info "[DRY RUN] Would install Go $go_version to /usr/local/go"
        log_info "[DRY RUN] Would configure environment variables"
        return 0
    fi
    
    local temp_file=$(util_create_temp_file "go-${go_version}.tar.gz")
    local checksum_url="https://go.dev/dl/go${go_version}.linux-amd64.tar.gz.sha256"
    local checksum_fallback_url="https://dl.google.com/go/go${go_version}.linux-amd64.tar.gz.sha256"
    
    # Download Go with checksum verification
    log_info "Downloading and verifying Go ${go_version}..."
    if ! util_download_verify "$go_url" "$temp_file" "$checksum_url" "Go ${go_version}" "$checksum_fallback_url"; then
        log_error "Failed to download or verify Go"
        rm -f "$temp_file"
        return 1
    fi
    
    # Remove old installation
    if [[ -d /usr/local/go ]]; then
        if ! ui_exec_with_progress "Removing old Go installation" \
            sudo rm -rf /usr/local/go; then
            log_warning "Failed to remove old Go installation (continuing...)"
        fi
    fi
    
    # Extract Go
    if ! ui_exec_with_progress "Extracting Go ${go_version}" \
        sudo tar -C /usr/local -xzf "$temp_file"; then
        log_error "Failed to extract Go"
        rm -f "$temp_file"
        return 1
    fi
    
    rm -f "$temp_file"
    
    # Verify installation
    if /usr/local/go/bin/go version &>/dev/null; then
        local installed_version=$(/usr/local/go/bin/go version | awk '{print $3}' | sed 's/go//')
        log_success "Go ${installed_version} installed successfully"
        
        # Setup environment variables
        util_setup_go_env
        
        # Add to manifest
        util_manifest_add_tool "languages" "go" "$installed_version" "/usr/local/go"
        rollback_add "tool_uninstall_go"
        return 0
    else
        log_error "Go installation verification failed"
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
    local rust_checksum=$(util_create_temp_file)
    
    # Download installer and checksum
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$rust_installer"; then
        log_error "Failed to download Rust installer"
        rm -f "$rust_installer" "$rust_checksum"
        return 1
    fi
    
    if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs.sha256 -o "$rust_checksum" 2>/dev/null; then
        log_warning "Could not download checksum, skipping verification"
    else
        # Verify checksum if available
        local expected_sum=$(cat "$rust_checksum" | awk '{print $1}')
        local actual_sum=$(sha256sum "$rust_installer" | awk '{print $1}')
        
        if [[ "$expected_sum" != "$actual_sum" ]]; then
            log_error "Checksum verification failed for Rust installer"
            log_error "Expected: $expected_sum"
            log_error "Got: $actual_sum"
            rm -f "$rust_installer" "$rust_checksum"
            return 1
        fi
        log_success "Checksum verified successfully"
    fi
    
    chmod +x "$rust_installer"
    "$rust_installer" -y --default-toolchain stable &>/dev/null &
    ui_spinner $! "Installing Rust"
    rm -f "$rust_installer" "$rust_checksum"
    
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
}

tool_uninstall_rust() {
    log_warning "Uninstalling Rust..."
    [[ "$DRY_RUN" == "false" ]] && rustup self uninstall -y
}

# ==============================================================================
# Rust Tools Installation Module
# ==============================================================================

tool_install_rust_tools() {
    ui_section_header "Installing Rust-based Security Tools" "$CYAN"
    
    # Ensure Rust is installed
    if ! util_command_exists cargo; then
        log_error "Rust/Cargo is not installed. Installing Rust first..."
        tool_install_rust || return 1
    fi
    
    # Source Rust environment
    util_source_env "$HOME/.cargo/env"
    
    local failed_tools=()
    local start_time=$(date +%s)
    
    mapfile -t rust_tool_names < <(printf "%s\n" "${!RUST_TOOLS[@]}" | sort)
    local total=${#rust_tool_names[@]}
    local current=0
    
    log_info "Installing $total Rust-based security tools..."
    echo ""
    
    for tool_pkg in "${rust_tool_names[@]}"; do
        ((current+=1))
        
        local tool_info="${RUST_TOOLS[$tool_pkg]}"
        IFS='|' read -r install_method package description <<< "$tool_info"
        local progress_label="Installing ${tool_pkg}"
        
        log_info "[$current/$total] $tool_pkg: $description"
        
        if [[ "$DRY_RUN" == "false" ]]; then
            if ui_run_with_live_progress "$current" "$total" "$progress_label" cargo install "$package"; then
                local tool_binary="$HOME/.cargo/bin/$tool_pkg"
                if [[ -f "$tool_binary" ]]; then
                    local version=$(util_get_tool_version "$tool_pkg" 2>/dev/null || echo "latest")
                    util_manifest_add_tool "rust_tools" "$tool_pkg" "$version" "$tool_binary"
                    echo -e "    ${DIM}Binary: $tool_binary${NC}"
                    echo -e "    ${DIM}Version: $version${NC}"
                else
                    log_error "Binary missing after installation: $tool_pkg"
                    echo -e "    ${RED}✗${NC} Binary not found at $HOME/.cargo/bin/$tool_pkg"
                    failed_tools+=("$tool_pkg")
                fi
            else
                failed_tools+=("$tool_pkg")
            fi
        else
            log_info "[DRY RUN] Would install: $package via cargo"
            ui_progress_finalize "$current" "$total" "$current" "$ICON_INFO" "$BLUE" "$progress_label" " ${DIM}[DRY RUN]${NC}"
        fi
        
        echo ""
    done
    
    echo ""
    
    # Summary
    local elapsed=$(($(date +%s) - start_time))
    local success_count=$((total - ${#failed_tools[@]}))
    
    log_info "═══════════════════════════════════════"
    log_info "Rust Tools Installation Summary:"
    log_success "  Successful: $success_count/$total tools"
    if [[ ${#failed_tools[@]} -gt 0 ]]; then
        log_error "  Failed: ${#failed_tools[@]} tools"
        log_warning "  Failed tools: ${failed_tools[*]}"
    fi
    log_info "  Time elapsed: ${elapsed}s"
    log_info "═══════════════════════════════════════"
    
    rollback_add "tool_uninstall_rust_tools"
    return 0
}

tool_uninstall_rust_tools() {
    log_warning "Removing Rust tools..."
    if [[ "$DRY_RUN" == "false" ]] && util_command_exists cargo; then
        for tool in "${!RUST_TOOLS[@]}"; do
            cargo uninstall "$tool" 2>/dev/null || true
        done
    fi
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

    # Ensure Go environment is set up
    util_setup_go_env

    # Install system dependencies for specific tools
    log_info "Checking system dependencies..."
    local deps_needed=()

    # naabu requires libpcap
    if [[ -n "${GO_TOOLS[naabu]}" ]]; then
        if ! dpkg -l | grep -q libpcap-dev; then
            deps_needed+=("libpcap-dev")
        fi
    fi

    # Install dependencies if needed
    if [[ ${#deps_needed[@]} -gt 0 ]]; then
        log_info "Installing system dependencies: ${deps_needed[*]}"
        util_wait_for_apt_lock || {
            log_warning "APT lock could not be acquired for dependency install"
            return 1
        }
        if ! ui_stream_command "Installing system dependencies" sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${deps_needed[@]}"; then
            log_warning "Some dependencies may have failed (continuing...)"
        fi
    fi

    local failed_tools=()
    local start_time=$(date +%s)

    mapfile -t go_tool_names < <(printf "%s\n" "${!GO_TOOLS[@]}" | sort)
    local total=${#go_tool_names[@]}
    
    log_info "Installing $total Go-based security tools..."
    
    # IMPROVEMENT: Option to install in parallel
    local parallel_jobs=1
    if [[ "${GO_TOOLS_PARALLEL:-false}" == "true" ]]; then
        parallel_jobs=$(nproc 2>/dev/null || echo 2)
        ((parallel_jobs > 4)) && parallel_jobs=4  # Limit to 4 parallel jobs
        log_info "Using ${parallel_jobs} parallel installation jobs"
    fi
    
    if [[ $parallel_jobs -gt 1 ]] && command -v xargs &>/dev/null; then
        # Parallel installation
        log_info "Installing tools in parallel (${parallel_jobs} jobs)..."
        printf "%s\n" "${go_tool_names[@]}" | xargs -P "$parallel_jobs" -I {} bash -c '
            tool_pkg="$1"
            tool_info="${GO_TOOLS[$tool_pkg]}"
            tool_path="${tool_info%%|*}"
            
            if go install -v "$tool_path" 2>&1 | grep -v "^#"; then
                echo "✓ $tool_pkg installed successfully"
            else
                echo "✗ $tool_pkg installation failed" >&2
                exit 1
            fi
        ' _ {} || {
            log_warning "Some parallel installations may have failed"
        }
        
        # Verify installations
        for tool_pkg in "${go_tool_names[@]}"; do
            local tool_binary="$(go env GOPATH)/bin/$tool_pkg"
            if [[ -f "$tool_binary" ]]; then
                local version=$(util_get_tool_version "$tool_pkg" 2>/dev/null || echo "latest")
                util_manifest_add_tool "go_tools" "$tool_pkg" "$version" "$tool_binary"
            else
                failed_tools+=("$tool_pkg")
            fi
        done
    else
        # Sequential installation (original behavior)
        local current=0
        echo ""

        for tool_pkg in "${go_tool_names[@]}"; do
            ((current+=1))

            local tool_info="${GO_TOOLS[$tool_pkg]}"
            local tool_path="${tool_info%%|*}"
            local description="${tool_info##*|}"
            local progress_label="Installing ${tool_pkg}"

            log_info "[$current/$total] $tool_pkg: $description"

            if [[ "$DRY_RUN" == "false" ]]; then
                if ui_run_with_live_progress "$current" "$total" "$progress_label" go install -v "$tool_path"; then
                    local tool_binary="$(go env GOPATH)/bin/$tool_pkg"
                    if [[ -f "$tool_binary" ]]; then
                        local version=$(util_get_tool_version "$tool_pkg" 2>/dev/null || echo "latest")
                        util_manifest_add_tool "go_tools" "$tool_pkg" "$version" "$tool_binary"
                        echo -e "    ${DIM}Binary: $tool_binary${NC}"
                        echo -e "    ${DIM}Version: $version${NC}"
                    else
                        log_error "Binary missing after installation: $tool_pkg"
                        echo -e "    ${RED}✗${NC} Binary not found at $(go env GOPATH)/bin/$tool_pkg"
                        failed_tools+=("$tool_pkg")
                    fi
                else
                    failed_tools+=("$tool_pkg")
                fi
            else
                log_info "[DRY RUN] Would install: $tool_path"
                ui_progress_finalize "$current" "$total" "$current" "$ICON_INFO" "$BLUE" "$progress_label" " ${DIM}[DRY RUN]${NC}"
            fi

            echo ""
        done
    fi

    echo ""

    # Summary
    local elapsed=$(($(date +%s) - start_time))
    local success_count=$((total - ${#failed_tools[@]}))

    log_info "═══════════════════════════════════════"
    log_info "Installation Summary:"
    log_success "  Successful: $success_count/$total tools"
    if [[ ${#failed_tools[@]} -gt 0 ]]; then
        log_error "  Failed: ${#failed_tools[@]} tools"
        log_warning "  Failed tools: ${failed_tools[*]}"
        
        # Offer retry for failed tools
        if [[ "$INTERACTIVE" == "true" ]] && ui_confirm "Retry failed tools?" "y"; then
            log_info "Retrying ${#failed_tools[@]} failed tools..."
            local retry_failed=()
            
            for tool_pkg in "${failed_tools[@]}"; do
                local tool_info="${GO_TOOLS[$tool_pkg]}"
                local tool_path="${tool_info%%|*}"
                
                log_info "Retrying: $tool_pkg"
                if go install -v "$tool_path" 2>&1 | tee -a "$LOG_FILE"; then
                    log_success "✓ $tool_pkg installed on retry"
                    local tool_binary="$(go env GOPATH)/bin/$tool_pkg"
                    local version=$(util_get_tool_version "$tool_pkg" 2>/dev/null || echo "latest")
                    util_manifest_add_tool "go_tools" "$tool_pkg" "$version" "$tool_binary"
                else
                    log_error "✗ $tool_pkg failed again"
                    retry_failed+=("$tool_pkg")
                fi
            done
            
            if [[ ${#retry_failed[@]} -eq 0 ]]; then
                log_success "All failed tools successfully installed on retry!"
            else
                log_warning "Still failed after retry: ${retry_failed[*]}"
            fi
        fi
    fi
    log_info "  Time elapsed: ${elapsed}s"
    log_info "═══════════════════════════════════════"

    rollback_add "tool_uninstall_go_tools"
    
    # Return success even if some tools failed (non-fatal)
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
    local failed_tools=()
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  Installing Python Tools with Virtual Environments    ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    for tool_name in "${!PYTHON_TOOLS[@]}"; do
        ((current+=1))
        
        local tool_info="${PYTHON_TOOLS[$tool_name]}"
        IFS='|' read -r install_type repo_url description requirements install_script <<< "$tool_info"
        
        # Show progress header
        local percent=$((current * 100 / total))
        local filled=$((percent * 50 / 100))
        local empty=$((50 - filled))
        
        # Generate progress bar characters
        local filled_bar=$(printf "█%.0s" $(seq 1 "$filled" 2>/dev/null))
        local empty_bar=$(printf "░%.0s" $(seq 1 "$empty" 2>/dev/null))
        
        # Color based on percentage
        local bar_color="$RED"
        [[ $percent -ge 75 ]] && bar_color="$GREEN"
        [[ $percent -ge 50 && $percent -lt 75 ]] && bar_color="$YELLOW"
        [[ $percent -ge 25 && $percent -lt 50 ]] && bar_color="$BLUE"
        
        printf "\n${CYAN}[${bar_color}%s${CYAN}%s${NC}] %3d%% (%d/%d) ${YELLOW}🐍${NC}  Installing ${CYAN}%s${NC}...\n" \
            "$filled_bar" "$empty_bar" "$percent" "$current" "$total" "$tool_name"
        
        log_info "[$current/$total] $tool_name: $description"
        
        local tool_dir="$TOOLS_DIR/$tool_name"
        
        if [[ -d "$tool_dir" ]]; then
            log_warning "$tool_name already installed at $tool_dir"
            continue
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "  ${DIM}[DRY RUN] Would install: $tool_name${NC}"
            continue
        fi
        
        # Clone repository with real-time output
        echo -e "  ${BLUE}↓${NC} Cloning repository..."
        if ! git clone --depth 1 "$repo_url" "$tool_dir" 2>&1 | grep -E "(Cloning|Receiving|Resolving)" | while IFS= read -r line; do
            echo -e "    ${DIM}${line}${NC}"
        done; then
            log_error "Failed to clone $tool_name"
            failed_tools+=("$tool_name")
            continue
        fi
        
        # Navigate to tool directory
        cd "$tool_dir" || {
            log_error "Failed to navigate to $tool_dir"
            failed_tools+=("$tool_name")
            continue
        }
        
        # Create virtual environment
        echo -e "  ${YELLOW}⚙${NC} Creating virtual environment..."
        if ! python3 -m venv venv 2>&1 | grep -v "^$"; then
            log_error "Failed to create virtual environment for $tool_name"
            cd "$original_dir" || return 1
            failed_tools+=("$tool_name")
            continue
        fi
        
        # Activate virtual environment
        echo -e "  ${GREEN}✓${NC} Activating virtual environment..."
        source venv/bin/activate || {
            log_error "Failed to activate virtual environment for $tool_name"
            cd "$original_dir" || return 1
            failed_tools+=("$tool_name")
            continue
        }
        
        # Upgrade pip in venv
        echo -e "  ${BLUE}↑${NC} Upgrading pip..."
        pip install --upgrade pip 2>&1 | grep -E "(Successfully|Requirement already)" | while IFS= read -r line; do
            echo -e "    ${DIM}${line}${NC}"
        done
        
        # Install requirements if exist
        if [[ -f "requirements.txt" ]]; then
            echo -e "  ${YELLOW}⚙${NC} Installing Python dependencies from requirements.txt..."
            if pip install --upgrade -r requirements.txt 2>&1 | grep -E "(Successfully installed|Requirement already|Collecting)" | while IFS= read -r line; do
                echo -e "    ${DIM}${line}${NC}"
            done; then
                echo -e "  ${GREEN}✓${NC} Dependencies installed successfully"
            else
                echo -e "  ${RED}✗${NC} Failed to install dependencies for $tool_name"
                deactivate
                cd "$original_dir" || return 1
                failed_tools+=("$tool_name")
                continue
            fi
        fi
        
        # Run install script if exists
        if [[ -n "$install_script" ]] && [[ -f "$install_script" ]]; then
            echo -e "  ${YELLOW}⚙${NC} Running installation script..."
            bash "$install_script" 2>&1 | while IFS= read -r line; do
                echo -e "    ${DIM}${line}${NC}"
            done
        fi
        
        # Deactivate virtual environment
        deactivate
        echo -e "  ${GREEN}✓${NC} Successfully installed ${CYAN}$tool_name${NC}"
        echo -e "  ${DIM}Location: $tool_dir${NC}"
        echo -e "  ${DIM}To use: cd $tool_dir && source venv/bin/activate${NC}"
        
        # Return to original directory
        cd "$original_dir" || return 1
        
        util_manifest_add_tool "python_tools" "$tool_name" "git-latest" "$tool_dir"
    done
    
    echo ""
    
    # Summary
    local success_count=$((total - ${#failed_tools[@]}))
    log_info "═══════════════════════════════════════"
    log_info "Python Tools Installation Summary:"
    log_success "  Successful: $success_count/$total tools"
    if [[ ${#failed_tools[@]} -gt 0 ]]; then
        log_error "  Failed: ${#failed_tools[@]} tools"
        log_warning "  Failed tools: ${failed_tools[*]}"
    fi
    log_info "═══════════════════════════════════════"
    
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
        util_wait_for_apt_lock || {
            log_error "Unable to acquire APT lock"
            return 1
        }
        if ! util_apt_update; then
            log_error "Failed to update package lists"
            return 1
        fi
        if ! ui_stream_command "Installing APT packages" sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"; then
            log_error "Failed to install APT packages"
            return 1
        fi
        log_success "APT tools installed"
    else
        log_info "[DRY RUN] Would install: ${packages[*]}"
    fi
    
    return 0
}

tool_install_snap_tools() {
    if util_is_wsl; then
        log_warning "WSL detected - snap tools may have limited functionality"
        log_warning "Skipping snap installations on WSL (systemd required)"
        ui_info "Snap tools skipped on WSL"
        return 0
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
        if [[ "$DRY_RUN" == "false" ]]; then
            util_wait_for_apt_lock || return 1
            if ! ui_stream_command "Installing pipx" sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y pipx; then
                log_error "Failed to install pipx"
                return 1
            fi
        fi
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
        ((current+=1))
        
        local wordlist_info="${WORDLISTS[$wordlist_name]}"
        IFS='|' read -r url type dest <<< "$wordlist_info"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would install wordlist: $wordlist_name"
            continue
        fi
        
        log_info "Installing wordlist [$current/$total]: $wordlist_name"

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
