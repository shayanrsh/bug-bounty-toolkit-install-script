#!/bin/bash
# ==============================================================================
# Tool Verification Module
# ==============================================================================
# Purpose: Verify that installed tools are working correctly
# ==============================================================================

# Verification results
declare -A VERIFY_RESULTS=()
VERIFY_PASSED=0
VERIFY_FAILED=0
VERIFY_WARNINGS=0

# ==============================================================================
# Core Verification Functions
# ==============================================================================

# Verify a single tool
# Usage: verify_tool "tool_name" ["test_command"]
verify_tool() {
    local tool_name="$1"
    local test_command="${2:---version}"
    
    log_info "Verifying: $tool_name"
    
    # Check if command exists
    if ! command -v "$tool_name" &>/dev/null; then
        VERIFY_RESULTS["$tool_name"]="NOT_FOUND"
        ((VERIFY_FAILED++))
        log_error "✗ $tool_name: Command not found"
        return 1
    fi
    
    # Test the command
    local output
    local exit_code
    
    if timeout 10 "$tool_name" $test_command &>/dev/null; then
        exit_code=0
    else
        exit_code=$?
    fi
    
    if [[ $exit_code -eq 0 ]]; then
        local version
        version=$(util_get_tool_version "$tool_name" 2>/dev/null || echo "unknown")
        VERIFY_RESULTS["$tool_name"]="OK:$version"
        ((VERIFY_PASSED++))
        log_success "✓ $tool_name (v$version)"
        return 0
    else
        VERIFY_RESULTS["$tool_name"]="FAILED:$exit_code"
        ((VERIFY_WARNINGS++))
        log_warning "⚠ $tool_name: Test failed (exit code $exit_code)"
        return 1
    fi
}

# Verify Python tool (virtual environment based)
verify_python_tool() {
    local tool_name="$1"
    local tools_dir="${TOOLS_DIR:-$HOME/tools}"
    local tool_dir="$tools_dir/$tool_name"
    
    log_info "Verifying Python tool: $tool_name"
    
    if [[ ! -d "$tool_dir" ]]; then
        VERIFY_RESULTS["$tool_name"]="NOT_FOUND"
        ((VERIFY_FAILED++))
        log_error "✗ $tool_name: Directory not found at $tool_dir"
        return 1
    fi
    
    # Check for virtual environment
    local venv_paths=("$tool_dir/venv" "$tool_dir/${tool_name}Env")
    local venv_found=""
    
    for venv in "${venv_paths[@]}"; do
        if [[ -d "$venv" ]]; then
            venv_found="$venv"
            break
        fi
    done
    
    if [[ -z "$venv_found" ]]; then
        VERIFY_RESULTS["$tool_name"]="NO_VENV"
        ((VERIFY_WARNINGS++))
        log_warning "⚠ $tool_name: Virtual environment not found"
        return 1
    fi
    
    # Check for main script
    local main_scripts=("$tool_dir/${tool_name}.py" "$tool_dir/main.py" "$tool_dir/${tool_name}")
    local main_found=""
    
    for script in "${main_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            main_found="$script"
            break
        fi
    done
    
    if [[ -z "$main_found" ]]; then
        VERIFY_RESULTS["$tool_name"]="NO_MAIN"
        ((VERIFY_WARNINGS++))
        log_warning "⚠ $tool_name: Main script not found"
        return 1
    fi
    
    VERIFY_RESULTS["$tool_name"]="OK"
    ((VERIFY_PASSED++))
    log_success "✓ $tool_name"
    return 0
}

# Verify wordlist exists
verify_wordlist() {
    local wordlist_name="$1"
    local wordlists_dir="${WORDLISTS_DIR:-$HOME/wordlists}"
    local wordlist_path="$wordlists_dir/$wordlist_name"
    
    log_info "Verifying wordlist: $wordlist_name"
    
    if [[ -d "$wordlist_path" ]]; then
        local file_count
        file_count=$(find "$wordlist_path" -type f \( -name "*.txt" -o -name "*.lst" \) 2>/dev/null | wc -l)
        VERIFY_RESULTS["wordlist:$wordlist_name"]="OK:$file_count files"
        ((VERIFY_PASSED++))
        log_success "✓ $wordlist_name ($file_count files)"
        return 0
    elif [[ -f "$wordlist_path" ]]; then
        local line_count
        line_count=$(wc -l < "$wordlist_path" 2>/dev/null || echo "0")
        VERIFY_RESULTS["wordlist:$wordlist_name"]="OK:$line_count lines"
        ((VERIFY_PASSED++))
        log_success "✓ $wordlist_name ($line_count lines)"
        return 0
    else
        VERIFY_RESULTS["wordlist:$wordlist_name"]="NOT_FOUND"
        ((VERIFY_FAILED++))
        log_error "✗ $wordlist_name: Not found"
        return 1
    fi
}

# ==============================================================================
# Category Verification
# ==============================================================================

# Verify all Go tools
verify_go_tools() {
    ui_section_header "Verifying Go Tools" "$GREEN"
    
    if ! command -v go &>/dev/null; then
        log_error "Go is not installed"
        return 1
    fi
    
    local gobin="$(go env GOPATH)/bin"
    
    for tool in "${!GO_TOOLS[@]}"; do
        if [[ -f "$gobin/$tool" ]]; then
            verify_tool "$tool"
        else
            VERIFY_RESULTS["$tool"]="NOT_INSTALLED"
            log_warning "⚠ $tool: Not installed"
        fi
    done
}

# Verify all Python tools
verify_python_tools() {
    ui_section_header "Verifying Python Tools" "$YELLOW"
    
    for tool in "${!PYTHON_TOOLS[@]}"; do
        verify_python_tool "$tool"
    done
}

# Verify all Rust tools
verify_rust_tools() {
    ui_section_header "Verifying Rust Tools" "$CYAN"
    
    if ! command -v cargo &>/dev/null; then
        log_warning "Rust/Cargo is not installed"
        return 1
    fi
    
    for tool in "${!RUST_TOOLS[@]}"; do
        verify_tool "$tool"
    done
}

# Verify wordlists
verify_wordlists() {
    ui_section_header "Verifying Wordlists" "$PURPLE"
    
    for wordlist in "${!WORDLISTS[@]}"; do
        local wordlist_info="${WORDLISTS[$wordlist]}"
        IFS='|' read -r url type dest <<< "$wordlist_info"
        verify_wordlist "$dest"
    done
}

# Verify ZSH installation
verify_zsh() {
    ui_section_header "Verifying ZSH Environment" "$BLUE"
    
    verify_tool "zsh"
    
    # Check Oh My ZSH
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        VERIFY_RESULTS["oh-my-zsh"]="OK"
        ((VERIFY_PASSED++))
        log_success "✓ Oh My ZSH installed"
    else
        VERIFY_RESULTS["oh-my-zsh"]="NOT_FOUND"
        ((VERIFY_FAILED++))
        log_error "✗ Oh My ZSH not found"
    fi
    
    # Check Powerlevel10k
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ -d "$p10k_dir" ]]; then
        VERIFY_RESULTS["powerlevel10k"]="OK"
        ((VERIFY_PASSED++))
        log_success "✓ Powerlevel10k theme installed"
    else
        VERIFY_RESULTS["powerlevel10k"]="NOT_FOUND"
        ((VERIFY_WARNINGS++))
        log_warning "⚠ Powerlevel10k not found"
    fi
    
    # Check plugins
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
        if [[ -d "$plugins_dir/$plugin" ]]; then
            VERIFY_RESULTS["plugin:$plugin"]="OK"
            ((VERIFY_PASSED++))
            log_success "✓ Plugin: $plugin"
        else
            VERIFY_RESULTS["plugin:$plugin"]="NOT_FOUND"
            ((VERIFY_WARNINGS++))
            log_warning "⚠ Plugin not found: $plugin"
        fi
    done
}

# Verify languages
verify_languages() {
    ui_section_header "Verifying Programming Languages" "$PURPLE"
    
    # Go
    if command -v go &>/dev/null; then
        local go_version
        go_version=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
        VERIFY_RESULTS["go"]="OK:$go_version"
        ((VERIFY_PASSED++))
        log_success "✓ Go $go_version"
    else
        VERIFY_RESULTS["go"]="NOT_FOUND"
        ((VERIFY_FAILED++))
        log_error "✗ Go not found"
    fi
    
    # Rust
    if command -v rustc &>/dev/null; then
        local rust_version
        rust_version=$(rustc --version 2>/dev/null | awk '{print $2}')
        VERIFY_RESULTS["rust"]="OK:$rust_version"
        ((VERIFY_PASSED++))
        log_success "✓ Rust $rust_version"
    else
        VERIFY_RESULTS["rust"]="NOT_FOUND"
        ((VERIFY_WARNINGS++))
        log_warning "⚠ Rust not found"
    fi
    
    # Python
    if command -v python3 &>/dev/null; then
        local python_version
        python_version=$(python3 --version 2>/dev/null | awk '{print $2}')
        VERIFY_RESULTS["python3"]="OK:$python_version"
        ((VERIFY_PASSED++))
        log_success "✓ Python $python_version"
    else
        VERIFY_RESULTS["python3"]="NOT_FOUND"
        ((VERIFY_FAILED++))
        log_error "✗ Python3 not found"
    fi
}

# ==============================================================================
# Full Verification
# ==============================================================================

# Run full verification of all installed components
verify_all() {
    ui_section_header "Full Installation Verification" "$CYAN"
    
    VERIFY_PASSED=0
    VERIFY_FAILED=0
    VERIFY_WARNINGS=0
    VERIFY_RESULTS=()
    
    verify_zsh
    verify_languages
    verify_go_tools
    verify_python_tools
    verify_rust_tools
    verify_wordlists
    
    verify_show_summary
}

# Show verification summary
verify_show_summary() {
    echo
    ui_section_header "Verification Summary" "$CYAN"
    
    local total=$((VERIFY_PASSED + VERIFY_FAILED + VERIFY_WARNINGS))
    
    echo -e "${CYAN}╭─ Results ────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC}"
    printf "${CYAN}│${NC}  ${GREEN}✓ Passed:${NC}   %3d / %d\n" "$VERIFY_PASSED" "$total"
    printf "${CYAN}│${NC}  ${RED}✗ Failed:${NC}   %3d / %d\n" "$VERIFY_FAILED" "$total"
    printf "${CYAN}│${NC}  ${YELLOW}⚠ Warnings:${NC} %3d / %d\n" "$VERIFY_WARNINGS" "$total"
    echo -e "${CYAN}│${NC}"
    
    if [[ $VERIFY_FAILED -eq 0 && $VERIFY_WARNINGS -eq 0 ]]; then
        echo -e "${CYAN}│${NC}  ${GREEN}All verifications passed! ✓${NC}"
    elif [[ $VERIFY_FAILED -eq 0 ]]; then
        echo -e "${CYAN}│${NC}  ${YELLOW}Some warnings detected, but all critical checks passed.${NC}"
    else
        echo -e "${CYAN}│${NC}  ${RED}Some verifications failed. Review the output above.${NC}"
    fi
    
    echo -e "${CYAN}│${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────────────╯${NC}"
    echo
    
    if [[ $VERIFY_FAILED -gt 0 ]]; then
        return 1
    fi
    return 0
}

# ==============================================================================
# Quick Health Check
# ==============================================================================

# Quick health check for critical tools
verify_quick_health() {
    log_info "Running quick health check..."
    
    local critical_tools=("go" "nuclei" "subfinder" "httpx")
    local failed=0
    
    for tool in "${critical_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            log_success "✓ $tool is available"
        else
            log_warning "✗ $tool is not available"
            ((failed++))
        fi
    done
    
    if [[ $failed -eq 0 ]]; then
        log_success "Quick health check passed"
        return 0
    else
        log_warning "$failed critical tool(s) not available"
        return 1
    fi
}

# ==============================================================================
# Post-Installation Verification
# ==============================================================================

# Called after installation to verify everything works
verify_post_install() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Skipping post-installation verification"
        return 0
    fi
    
    ui_section_header "Post-Installation Verification" "$GREEN"
    
    # Quick check of critical components
    local checks_passed=true
    
    # Check PATH is properly configured
    log_info "Checking PATH configuration..."
    
    local go_bin="/usr/local/go/bin"
    if [[ ":$PATH:" == *":$go_bin:"* ]]; then
        log_success "Go binary path is in PATH"
    else
        log_warning "Go binary path not in PATH. Add to shell config: export PATH=\$PATH:$go_bin"
    fi
    
    local gopath_bin="$(go env GOPATH 2>/dev/null)/bin"
    if [[ -n "$gopath_bin" && ":$PATH:" == *":$gopath_bin:"* ]]; then
        log_success "GOPATH bin is in PATH"
    else
        log_warning "GOPATH bin not in PATH. Add to shell config: export PATH=\$PATH:\$GOPATH/bin"
    fi
    
    # Check tools directory exists
    if [[ -d "${TOOLS_DIR:-$HOME/tools}" ]]; then
        log_success "Tools directory exists: ${TOOLS_DIR:-$HOME/tools}"
    else
        log_warning "Tools directory not found"
    fi
    
    # Check wordlists directory exists
    if [[ -d "${WORDLISTS_DIR:-$HOME/wordlists}" ]]; then
        log_success "Wordlists directory exists: ${WORDLISTS_DIR:-$HOME/wordlists}"
    else
        log_warning "Wordlists directory not found"
    fi
    
    # Run quick health check
    verify_quick_health
    
    log_success "Post-installation verification complete"
    return 0
}

# Export functions
export -f verify_tool verify_python_tool verify_wordlist
export -f verify_go_tools verify_python_tools verify_rust_tools
export -f verify_all verify_show_summary verify_quick_health
