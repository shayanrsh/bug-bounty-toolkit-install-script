#!/bin/bash
# ==============================================================================
# Security Tools Installer - Core Logic Module
# ==============================================================================
# Purpose: Core installation orchestration, rollback, and main workflows
# ==============================================================================

# shellcheck disable=SC2155

# ==============================================================================
# Rollback Management
# ==============================================================================

rollback_add() {
    local function_name="$1"
    ROLLBACK_STACK+=("$function_name")
    log_debug "Added to rollback stack: $function_name"
}

rollback_execute() {
    if [[ ${#ROLLBACK_STACK[@]} -eq 0 ]]; then
        log_info "No rollback actions needed"
        return 0
    fi
    
    log_warning "Executing rollback..."
    
    # Execute in reverse order
    for ((i=${#ROLLBACK_STACK[@]}-1; i>=0; i--)); do
        local func="${ROLLBACK_STACK[$i]}"
        log_info "Rolling back: $func"
        
        if declare -f "$func" >/dev/null; then
            "$func" || log_error "Rollback function failed: $func"
        else
            log_warning "Rollback function not found: $func"
        fi
    done
    
    ROLLBACK_STACK=()
    log_success "Rollback completed"
}

rollback_clear() {
    ROLLBACK_STACK=()
    log_debug "Rollback stack cleared"
}

# ==============================================================================
# Pre-Installation Checks
# ==============================================================================

core_pre_install_checks() {
    ui_section_header "Pre-Installation Checks" "$CYAN"
    
    local checks_passed=true
    
    # System compatibility
    log_info "Checking system compatibility..."
    if ! util_check_ubuntu_version; then
        checks_passed=false
    fi
    
    # Disk space
    log_info "Checking disk space..."
    if ! util_check_disk_space; then
        if [[ "$SKIP_CHECKS" == "false" ]]; then
            checks_passed=false
        fi
    fi
    
    # Memory
    log_info "Checking memory..."
    util_check_memory || log_warning "Low memory detected"
    
    # Internet connectivity
    log_info "Checking internet connectivity..."
    if ! util_check_internet; then
        if [[ "$SKIP_CHECKS" == "false" ]]; then
            checks_passed=false
        fi
    fi
    
    # Sudo privileges
    log_info "Checking sudo privileges..."
    if ! util_check_sudo; then
        checks_passed=false
    fi
    
    # Prerequisites
    log_info "Checking prerequisites..."
    util_check_prerequisites
    
    # Display system info
    declare -A sys_info
    util_get_system_info sys_info
    
    log_info "System Information:"
    log_info "  OS: ${sys_info[os]}"
    log_info "  Kernel: ${sys_info[kernel]}"
    log_info "  Architecture: ${sys_info[arch]}"
    log_info "  Environment: ${sys_info[environment]}"
    log_info "  Memory: ${sys_info[memory]}"
    log_info "  Disk Space: ${sys_info[disk_space]}"
    
    if [[ "$checks_passed" == "false" ]]; then
        log_error "Pre-installation checks failed"
        
        if [[ "$FORCE_INSTALL" == "false" ]] && [[ "$INTERACTIVE" == "true" ]]; then
            ui_confirm "Continue anyway? (NOT RECOMMENDED)" "n" || return 1
        elif [[ "$FORCE_INSTALL" == "false" ]]; then
            return 1
        fi
        
        log_warning "Proceeding despite failed checks"
    fi
    
    log_success "Pre-installation checks completed"
    return 0
}

# ==============================================================================
# Installation Modes
# ==============================================================================

core_install_full() {
    log_info "Starting full installation..."
    
    local steps=(
        "tool_install_zsh:ZSH + Oh My ZSH"
        "tool_install_go:Go Programming Language"
        "tool_install_rust:Rust Programming Language"
        "tool_install_go_tools:Go Security Tools"
        "tool_install_python_tools:Python Security Tools"
        "tool_install_apt_tools:APT Tools"
        "tool_install_snap_tools:Snap Tools"
        "tool_install_pipx_tools:Pipx Tools"
        "tool_install_wordlists:Wordlists"
        "tool_create_helper_scripts:Helper Scripts"
    )
    
    core_execute_installation_steps steps
}

core_install_zsh_only() {
    log_info "Installing ZSH environment only..."
    
    local steps=(
        "tool_install_zsh:ZSH + Oh My ZSH"
        "tool_create_helper_scripts:Helper Scripts"
    )
    
    core_execute_installation_steps steps
}

core_install_tools_only() {
    log_info "Installing security tools only..."
    
    local steps=(
        "tool_install_go:Go Programming Language"
        "tool_install_rust:Rust Programming Language"
        "tool_install_go_tools:Go Security Tools"
        "tool_install_python_tools:Python Security Tools"
        "tool_install_apt_tools:APT Tools"
        "tool_install_snap_tools:Snap Tools"
        "tool_install_pipx_tools:Pipx Tools"
        "tool_create_helper_scripts:Helper Scripts"
    )
    
    core_execute_installation_steps steps
}

core_install_go_tools_only() {
    log_info "Installing Go tools only..."
    
    local steps=(
        "tool_install_go:Go Programming Language"
        "tool_install_go_tools:Go Security Tools"
    )
    
    core_execute_installation_steps steps
}

core_install_python_tools_only() {
    log_info "Installing Python tools only..."
    
    local steps=(
        "tool_install_python_tools:Python Security Tools"
    )
    
    core_execute_installation_steps steps
}

core_install_wordlists_only() {
    log_info "Installing wordlists only..."
    
    local steps=(
        "tool_install_wordlists:Wordlists"
    )
    
    core_execute_installation_steps steps
}

core_install_profile() {
    local profile="$1"
    
    if [[ -z "${PROFILES[$profile]}" ]]; then
        log_error "Unknown profile: $profile"
        return 1
    fi
    
    log_info "Installing profile: $profile"
    
    local profile_components="${PROFILES[$profile]}"
    
    if [[ "$profile_components" == "all" ]]; then
        core_install_full
        return $?
    fi
    
    IFS='|' read -ra components <<< "$profile_components"
    local steps=()
    
    for component in "${components[@]}"; do
        case "$component" in
            zsh) steps+=("tool_install_zsh:ZSH + Oh My ZSH") ;;
            go) steps+=("tool_install_go:Go Programming Language") ;;
            rust) steps+=("tool_install_rust:Rust Programming Language") ;;
            python_tools) steps+=("tool_install_python_tools:Python Security Tools") ;;
            go_tools) steps+=("tool_install_go_tools:Go Security Tools") ;;
            wordlists) steps+=("tool_install_wordlists:Wordlists") ;;
            build-essential) steps+=("tool_install_apt_tools:Development Tools") ;;
            nuclei) steps+=("tool_install_go_tools:Nuclei") ;;
            subfinder) steps+=("tool_install_go_tools:Subfinder") ;;
            httpx) steps+=("tool_install_go_tools:Httpx") ;;
        esac
    done
    
    steps+=("tool_create_helper_scripts:Helper Scripts")
    
    core_execute_installation_steps steps
}

core_install_custom() {
    ui_menu_custom
    
    read -p "Enter component numbers (space-separated): " -a selections
    
    local steps=()
    
    for selection in "${selections[@]}"; do
        case "$selection" in
            1) steps+=("tool_install_zsh:ZSH + Oh My ZSH") ;;
            2) steps+=("tool_install_go:Go Programming Language") ;;
            3) steps+=("tool_install_rust:Rust Programming Language") ;;
            4) steps+=("tool_install_go_tools:Go Security Tools") ;;
            5) steps+=("tool_install_python_tools:Python Security Tools") ;;
            6) steps+=("tool_install_rust:Rust + Rust Tools") ;;
            7) 
                steps+=("tool_install_apt_tools:APT Tools")
                steps+=("tool_install_snap_tools:Snap Tools")
                steps+=("tool_install_pipx_tools:Pipx Tools")
                ;;
            8) steps+=("tool_install_wordlists:Wordlists") ;;
            9) 
                core_install_full
                return $?
                ;;
            *)
                log_warning "Invalid selection: $selection"
                ;;
        esac
    done
    
    if [[ ${#steps[@]} -eq 0 ]]; then
        log_error "No valid components selected"
        return 1
    fi
    
    steps+=("tool_create_helper_scripts:Helper Scripts")
    
    core_execute_installation_steps steps
}

# ==============================================================================
# Installation Execution
# ==============================================================================

core_execute_installation_steps() {
    local -n steps_ref=$1
    
    local total_steps=${#steps_ref[@]}
    local current_step=0
    local start_time=$(date +%s)
    
    declare -a installed_tools=()
    local failed=false
    
    for step_info in "${steps_ref[@]}"; do
        ((current_step++))
        
        IFS=':' read -r function_name description <<< "$step_info"
        
        ui_step_header "$current_step" "$total_steps" "$description"
        
        # Show ETA
        if [[ $current_step -gt 1 ]]; then
            local eta=$(ui_eta "$start_time" "$current_step" "$total_steps")
            log_info "$eta"
        fi
        
        # Execute installation function
        if declare -f "$function_name" >/dev/null; then
            if "$function_name"; then
                installed_tools+=("$description")
                log_success "$description completed"
            else
                log_error "$description failed"
                failed=true
                
                if [[ "$INTERACTIVE" == "true" ]]; then
                    if ! ui_confirm "Continue with remaining steps?" "y"; then
                        log_warning "Installation aborted by user"
                        rollback_execute
                        return 1
                    fi
                else
                    log_error "Installation failed, executing rollback..."
                    rollback_execute
                    return 1
                fi
            fi
        else
            log_error "Installation function not found: $function_name"
            failed=true
        fi
        
        echo
    done
    
    # Show summary
    ui_show_summary installed_tools
    
    if [[ "$failed" == "true" ]]; then
        log_warning "Installation completed with errors"
        return 1
    fi
    
    log_success "All installation steps completed successfully"
    rollback_clear
    return 0
}

# ==============================================================================
# Update Operations
# ==============================================================================

core_update_tools() {
    ui_section_header "Updating Installed Tools" "$GREEN"
    
    log_info "Updating tools..."
    
    # Update Go tools
    if util_command_exists go; then
        log_info "Updating Go tools..."
        util_add_to_path "/usr/local/go/bin"
        util_add_to_path "$(go env GOPATH)/bin"
        
        for tool in "${!GO_TOOLS[@]}"; do
            local tool_path="${GO_TOOLS[$tool]%%|*}"
            log_info "Updating $tool..."
            
            if [[ "$DRY_RUN" == "false" ]]; then
                go install -v "$tool_path" &>/dev/null &
                ui_spinner $! "Updating $tool"
            else
                log_info "[DRY RUN] Would update: $tool"
            fi
        done
    fi
    
    # Update Python tools
    if [[ -d "$TOOLS_DIR" ]]; then
        for tool_dir in "$TOOLS_DIR"/*; do
            if [[ -d "$tool_dir/.git" ]]; then
                util_git_update "$tool_dir" "$(basename "$tool_dir")"
            fi
        done
    fi
    
    # Update Oh My ZSH
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Updating Oh My ZSH..."
        if [[ "$DRY_RUN" == "false" ]]; then
            cd "$HOME/.oh-my-zsh" && git pull &>/dev/null &
            ui_spinner $! "Updating Oh My ZSH"
            cd - >/dev/null
        fi
    fi
    
    # Update Nuclei templates
    if util_command_exists nuclei; then
        log_info "Updating Nuclei templates..."
        [[ "$DRY_RUN" == "false" ]] && nuclei -update-templates -silent
    fi
    
    log_success "Update completed"
}

# ==============================================================================
# Uninstall Operations
# ==============================================================================

core_uninstall_all() {
    ui_section_header "Uninstalling Security Tools" "$RED"
    
    log_warning "This will remove ALL installed security tools and configurations!"
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        if ! ui_confirm "Are you absolutely sure? Type 'yes' to confirm" "n"; then
            log_info "Uninstall cancelled"
            return 0
        fi
        
        read -p "Type 'DELETE' to confirm: " confirmation
        if [[ "$confirmation" != "DELETE" ]]; then
            log_info "Uninstall cancelled"
            return 0
        fi
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would uninstall all tools"
        return 0
    fi
    
    log_warning "Uninstalling tools..."
    
    # Remove tools directory
    if [[ -d "$TOOLS_DIR" ]]; then
        rm -rf "$TOOLS_DIR"
        log_success "Removed tools directory"
    fi
    
    # Remove wordlists
    if [[ -d "$WORDLISTS_DIR" ]]; then
        rm -rf "$WORDLISTS_DIR"
        log_success "Removed wordlists"
    fi
    
    # Remove configuration
    if [[ -f "$CONFIG_FILE" ]]; then
        rm -f "$CONFIG_FILE"
        log_success "Removed configuration"
    fi
    
    # Remove manifest
    if [[ -f "$MANIFEST_FILE" ]]; then
        rm -f "$MANIFEST_FILE"
        log_success "Removed manifest"
    fi
    
    # Optionally remove Oh My ZSH
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        if ui_confirm "Remove Oh My ZSH?" "n"; then
            rm -rf "$HOME/.oh-my-zsh" "$HOME/.zshrc" "$HOME/.p10k.zsh"
            log_success "Removed Oh My ZSH"
        fi
    fi
    
    log_success "Uninstall completed"
}

# ==============================================================================
# Dry Run Summary
# ==============================================================================

core_dry_run_summary() {
    ui_section_header "Dry Run Summary" "$YELLOW"
    
    echo -e "${CYAN}╭─ What Would Be Installed ────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│                                                                      │${NC}"
    echo -e "${CYAN}│ ${GREEN}✓${NC} ZSH + Oh My ZSH + Powerlevel10k theme                             ${CYAN}│${NC}"
    echo -e "${CYAN}│ ${GREEN}✓${NC} Go ${GO_VERSION:-1.22.4} (Programming Language)                    ${CYAN}│${NC}"
    echo -e "${CYAN}│ ${GREEN}✓${NC} Rust (Programming Language)                                        ${CYAN}│${NC}"
    echo -e "${CYAN}│ ${GREEN}✓${NC} ${#GO_TOOLS[@]} Go-based security tools                            ${CYAN}│${NC}"
    echo -e "${CYAN}│ ${GREEN}✓${NC} ${#PYTHON_TOOLS[@]} Python-based security tools                    ${CYAN}│${NC}"
    echo -e "${CYAN}│ ${GREEN}✓${NC} ${#APT_TOOLS[@]} APT packages                                      ${CYAN}│${NC}"
    echo -e "${CYAN}│ ${GREEN}✓${NC} ${#WORDLISTS[@]} Wordlist collections                              ${CYAN}│${NC}"
    echo -e "${CYAN}│                                                                      │${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────────────╯${NC}"
    echo
    
    echo -e "${YELLOW}Installation Locations:${NC}"
    echo -e "  Tools:     ${CYAN}$TOOLS_DIR${NC}"
    echo -e "  Wordlists: ${CYAN}$WORDLISTS_DIR${NC}"
    echo -e "  Scripts:   ${CYAN}$SCRIPTS_DIR${NC}"
    echo
}

# ==============================================================================
# Post-Installation
# ==============================================================================

core_post_install() {
    log_info "Running post-installation tasks..."
    
    # Save configuration
    config_save
    
    # Initialize manifest
    util_manifest_init
    
    # Show success banner
    ui_show_success_banner
    
    # Show next steps
    ui_show_next_steps
    
    log_success "Installation completed successfully!"
}
