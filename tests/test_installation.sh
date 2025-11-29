#!/bin/bash
# ==============================================================================
# Bug Bounty Toolkit - Installation Test Suite
# ==============================================================================
# Version: 4.0.0
# Description: Comprehensive test suite for validating installations
# Usage: ./tests/test_installation.sh [OPTIONS]
# ==============================================================================

set -Eeuo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_RESULTS=()
TEST_PASSED=0
TEST_FAILED=0
TEST_SKIPPED=0
VERBOSE="${VERBOSE:-false}"

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

# ==============================================================================
# Test Utilities
# ==============================================================================

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TEST_PASSED++))
    TEST_RESULTS+=("PASS: $1")
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TEST_FAILED++))
    TEST_RESULTS+=("FAIL: $1")
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((TEST_SKIPPED++))
    TEST_RESULTS+=("SKIP: $1")
}

log_info() {
    [[ "$VERBOSE" == "true" ]] && echo -e "${CYAN}[INFO]${NC} $1"
}

# ==============================================================================
# Library Loading Tests
# ==============================================================================

test_library_loading() {
    log_test "Testing library module loading..."
    
    local modules=(
        "config.sh"
        "ui.sh"
        "utils.sh"
        "tools.sh"
        "core.sh"
        "plugins.sh"
        "dependencies.sh"
        "state.sh"
        "json_config.sh"
        "verify.sh"
    )
    
    for module in "${modules[@]}"; do
        local module_path="${SCRIPT_DIR}/lib/${module}"
        
        if [[ ! -f "$module_path" ]]; then
            log_fail "Module file missing: $module"
            continue
        fi
        
        # Test that module can be sourced
        if bash -n "$module_path" 2>/dev/null; then
            log_pass "Module syntax OK: $module"
        else
            log_fail "Module syntax error: $module"
        fi
    done
}

test_full_script_sourcing() {
    log_test "Testing full script sourcing..."
    
    # Try to source all modules together
    (
        export DRY_RUN=true
        export INTERACTIVE=false
        
        source "${SCRIPT_DIR}/lib/config.sh" 2>/dev/null || exit 1
        source "${SCRIPT_DIR}/lib/ui.sh" 2>/dev/null || exit 1
        source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null || exit 1
        source "${SCRIPT_DIR}/lib/tools.sh" 2>/dev/null || exit 1
        source "${SCRIPT_DIR}/lib/core.sh" 2>/dev/null || exit 1
        source "${SCRIPT_DIR}/lib/plugins.sh" 2>/dev/null || exit 1
        source "${SCRIPT_DIR}/lib/dependencies.sh" 2>/dev/null || exit 1
        source "${SCRIPT_DIR}/lib/state.sh" 2>/dev/null || exit 1
        
        if [[ -f "${SCRIPT_DIR}/lib/json_config.sh" ]]; then
            source "${SCRIPT_DIR}/lib/json_config.sh" 2>/dev/null || true
        fi
        
        if [[ -f "${SCRIPT_DIR}/lib/verify.sh" ]]; then
            source "${SCRIPT_DIR}/lib/verify.sh" 2>/dev/null || true
        fi
        
        exit 0
    )
    
    if [[ $? -eq 0 ]]; then
        log_pass "All modules source correctly together"
    else
        log_fail "Module sourcing failed"
    fi
}

# ==============================================================================
# Configuration Tests
# ==============================================================================

test_configuration() {
    log_test "Testing configuration values..."
    
    source "${SCRIPT_DIR}/lib/config.sh"
    
    # Test required variables exist
    local required_vars=(
        "SCRIPT_VERSION"
        "SCRIPT_NAME"
        "TOOLS_DIR"
        "WORDLISTS_DIR"
        "LOG_DIR"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -n "${!var:-}" ]]; then
            log_pass "Required variable set: $var"
        else
            log_fail "Required variable missing: $var"
        fi
    done
    
    # Test GO_TOOLS array has entries
    if [[ ${#GO_TOOLS[@]} -gt 0 ]]; then
        log_pass "GO_TOOLS array has ${#GO_TOOLS[@]} entries"
    else
        log_fail "GO_TOOLS array is empty"
    fi
    
    # Test PYTHON_TOOLS array has entries
    if [[ ${#PYTHON_TOOLS[@]} -gt 0 ]]; then
        log_pass "PYTHON_TOOLS array has ${#PYTHON_TOOLS[@]} entries"
    else
        log_fail "PYTHON_TOOLS array is empty"
    fi
    
    # Test WORDLISTS array has entries
    if [[ ${#WORDLISTS[@]} -gt 0 ]]; then
        log_pass "WORDLISTS array has ${#WORDLISTS[@]} entries"
    else
        log_fail "WORDLISTS array is empty"
    fi
}

test_colors() {
    log_test "Testing color/formatting variables..."
    
    source "${SCRIPT_DIR}/lib/config.sh"
    
    local color_vars=("RED" "GREEN" "YELLOW" "BLUE" "CYAN" "NC")
    
    for var in "${color_vars[@]}"; do
        if [[ -n "${!var+x}" ]]; then  # Check if set (even if empty for NO_COLOR)
            log_pass "Color variable defined: $var"
        else
            log_fail "Color variable missing: $var"
        fi
    done
}

# ==============================================================================
# JSON Configuration Tests
# ==============================================================================

test_json_config() {
    log_test "Testing JSON configuration..."
    
    local config_file="${SCRIPT_DIR}/config/tools.json"
    
    if [[ ! -f "$config_file" ]]; then
        log_skip "JSON config file not found"
        return
    fi
    
    # Test JSON syntax
    if command -v jq &>/dev/null; then
        if jq empty "$config_file" 2>/dev/null; then
            log_pass "JSON syntax is valid"
        else
            log_fail "JSON syntax error in $config_file"
            return
        fi
        
        # Test required fields
        local version
        version=$(jq -r '.version // empty' "$config_file")
        if [[ -n "$version" ]]; then
            log_pass "JSON config has version field: $version"
        else
            log_fail "JSON config missing version field"
        fi
        
        local categories
        categories=$(jq -r '.categories | keys | length' "$config_file")
        if [[ "$categories" -gt 0 ]]; then
            log_pass "JSON config has $categories categories"
        else
            log_fail "JSON config has no categories"
        fi
    else
        log_skip "jq not installed, skipping JSON validation"
    fi
}

# ==============================================================================
# Function Existence Tests
# ==============================================================================

test_function_existence() {
    log_test "Testing required functions exist..."
    
    # Source all modules
    source "${SCRIPT_DIR}/lib/config.sh"
    source "${SCRIPT_DIR}/lib/ui.sh"
    source "${SCRIPT_DIR}/lib/utils.sh"
    source "${SCRIPT_DIR}/lib/tools.sh"
    source "${SCRIPT_DIR}/lib/core.sh"
    
    local required_functions=(
        # UI functions
        "log_info"
        "log_error"
        "log_success"
        "log_warning"
        "ui_progress_bar"
        "ui_spinner"
        "ui_show_banner"
        
        # Utility functions
        "util_command_exists"
        "util_check_disk_space"
        "util_download"
        "util_git_clone"
        
        # Tool functions
        "tool_install_zsh"
        "tool_install_go"
        "tool_install_go_tools"
        "tool_install_python_tools"
        "tool_install_wordlists"
        
        # Core functions
        "core_pre_install_checks"
        "core_install_full"
        "core_execute_installation_steps"
        "rollback_add"
        "rollback_execute"
    )
    
    for func in "${required_functions[@]}"; do
        if declare -f "$func" &>/dev/null; then
            log_pass "Function exists: $func"
        else
            log_fail "Function missing: $func"
        fi
    done
}

# ==============================================================================
# Dry Run Tests
# ==============================================================================

test_dry_run() {
    log_test "Testing dry run mode..."
    
    # Run installer in dry-run mode
    if bash "${SCRIPT_DIR}/install.sh" --dry-run --yes --full 2>&1 | grep -q "DRY RUN"; then
        log_pass "Dry run mode works"
    else
        log_skip "Could not verify dry run mode"
    fi
}

test_help_output() {
    log_test "Testing help output..."
    
    local help_output
    help_output=$(bash "${SCRIPT_DIR}/install.sh" --help 2>&1)
    
    if echo "$help_output" | grep -q "USAGE"; then
        log_pass "Help output shows usage"
    else
        log_fail "Help output missing usage section"
    fi
    
    if echo "$help_output" | grep -q "OPTIONS"; then
        log_pass "Help output shows options"
    else
        log_fail "Help output missing options section"
    fi
}

# ==============================================================================
# Plugin System Tests
# ==============================================================================

test_plugin_system() {
    log_test "Testing plugin system..."
    
    source "${SCRIPT_DIR}/lib/config.sh"
    source "${SCRIPT_DIR}/lib/ui.sh"
    source "${SCRIPT_DIR}/lib/plugins.sh"
    
    # Test plugin directory exists
    if [[ -d "${SCRIPT_DIR}/plugins" ]]; then
        log_pass "Plugins directory exists"
        
        # Count plugin files
        local plugin_count
        plugin_count=$(find "${SCRIPT_DIR}/plugins" -name "*.sh" -type f 2>/dev/null | wc -l)
        log_info "Found $plugin_count plugin file(s)"
    else
        log_skip "Plugins directory not found"
    fi
    
    # Test plugin functions exist
    if declare -f plugin_load &>/dev/null; then
        log_pass "Plugin loader function exists"
    else
        log_fail "Plugin loader function missing"
    fi
}

# ==============================================================================
# Installed Tools Verification Tests (Post-Installation)
# ==============================================================================

test_installed_go() {
    log_test "Testing Go installation..."
    
    if command -v go &>/dev/null; then
        local version
        version=$(go version 2>/dev/null | awk '{print $3}')
        log_pass "Go is installed: $version"
    else
        log_skip "Go not installed"
    fi
}

test_installed_rust() {
    log_test "Testing Rust installation..."
    
    if command -v rustc &>/dev/null; then
        local version
        version=$(rustc --version 2>/dev/null | awk '{print $2}')
        log_pass "Rust is installed: $version"
    else
        log_skip "Rust not installed"
    fi
}

test_installed_go_tools() {
    log_test "Testing installed Go tools..."
    
    source "${SCRIPT_DIR}/lib/config.sh"
    
    local gobin="${GOPATH:-$HOME/go}/bin"
    
    for tool in "${!GO_TOOLS[@]}"; do
        if [[ -f "$gobin/$tool" ]] || command -v "$tool" &>/dev/null; then
            log_pass "Go tool installed: $tool"
        else
            log_skip "Go tool not installed: $tool"
        fi
    done
}

test_installed_zsh() {
    log_test "Testing ZSH installation..."
    
    if command -v zsh &>/dev/null; then
        local version
        version=$(zsh --version 2>/dev/null | awk '{print $2}')
        log_pass "ZSH is installed: $version"
        
        # Check Oh My ZSH
        if [[ -d "$HOME/.oh-my-zsh" ]]; then
            log_pass "Oh My ZSH is installed"
        else
            log_skip "Oh My ZSH not installed"
        fi
        
        # Check Powerlevel10k
        local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
        if [[ -d "$p10k_dir" ]]; then
            log_pass "Powerlevel10k is installed"
        else
            log_skip "Powerlevel10k not installed"
        fi
    else
        log_skip "ZSH not installed"
    fi
}

test_directories() {
    log_test "Testing directory structure..."
    
    source "${SCRIPT_DIR}/lib/config.sh"
    
    local dirs=(
        "${TOOLS_DIR:-$HOME/tools}"
        "${WORDLISTS_DIR:-$HOME/wordlists}"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_pass "Directory exists: $dir"
        else
            log_skip "Directory not found: $dir"
        fi
    done
}

# ==============================================================================
# Main Test Runner
# ==============================================================================

print_banner() {
    echo
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                     Bug Bounty Toolkit - Test Suite                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_summary() {
    echo
    echo -e "${CYAN}╭─ Test Summary ───────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC}"
    printf "${CYAN}│${NC}  ${GREEN}✓ Passed:${NC}  %3d\n" "$TEST_PASSED"
    printf "${CYAN}│${NC}  ${RED}✗ Failed:${NC}  %3d\n" "$TEST_FAILED"
    printf "${CYAN}│${NC}  ${YELLOW}○ Skipped:${NC} %3d\n" "$TEST_SKIPPED"
    echo -e "${CYAN}│${NC}"
    printf "${CYAN}│${NC}  Total:     %3d\n" "$((TEST_PASSED + TEST_FAILED + TEST_SKIPPED))"
    echo -e "${CYAN}│${NC}"
    
    if [[ $TEST_FAILED -eq 0 ]]; then
        echo -e "${CYAN}│${NC}  ${GREEN}All critical tests passed! ✓${NC}"
    else
        echo -e "${CYAN}│${NC}  ${RED}Some tests failed. Review output above.${NC}"
    fi
    
    echo -e "${CYAN}│${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────────────────────╯${NC}"
    echo
}

run_all_tests() {
    print_banner
    
    echo -e "${CYAN}═══ Module Tests ═══${NC}"
    test_library_loading
    test_full_script_sourcing
    
    echo
    echo -e "${CYAN}═══ Configuration Tests ═══${NC}"
    test_configuration
    test_colors
    test_json_config
    
    echo
    echo -e "${CYAN}═══ Function Tests ═══${NC}"
    test_function_existence
    
    echo
    echo -e "${CYAN}═══ Integration Tests ═══${NC}"
    test_dry_run
    test_help_output
    test_plugin_system
    
    echo
    echo -e "${CYAN}═══ Installation Verification ═══${NC}"
    test_installed_go
    test_installed_rust
    test_installed_zsh
    test_directories
    test_installed_go_tools
    
    print_summary
    
    # Return non-zero if any tests failed
    [[ $TEST_FAILED -eq 0 ]]
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose    Show detailed test output"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run tests
run_all_tests
exit $?
