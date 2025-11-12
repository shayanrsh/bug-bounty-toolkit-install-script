#!/bin/bash

# ==============================================================================
# Security Tools Installer - Main Entry Point
# ==============================================================================
# Description: Professional, modular security tools installation framework
# Version: 3.0.0
# Author: Bug Bounty Community
# License: MIT
#
# Usage: ./install.sh [OPTIONS]
#
# ==============================================================================

set -uo pipefail
IFS=$'\n\t'

# ==============================================================================
# Source Library Modules
# ==============================================================================

# Detect if script is being run from curl pipe
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
if [[ "$SCRIPT_SOURCE" =~ ^/dev/fd/ ]] || [[ "$SCRIPT_SOURCE" =~ ^/proc/self/fd/ ]]; then
    # Script is being piped from curl, need to clone the repository
    echo "=========================================="
    echo "Bug Bounty Toolkit Installer"
    echo "=========================================="
    echo ""
    echo "Detected installation via curl pipe..."
    echo "Cloning repository to temporary directory..."
    echo ""
    
    INSTALL_DIR="/tmp/bug-bounty-toolkit-$$"
    REPO_URL="https://github.com/shayanrsh/bug-bounty-toolkit-install-script.git"
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo "Git not found. Installing git..."
        sudo apt-get update -qq && sudo apt-get install -y git -qq || {
            echo "ERROR: Failed to install git"
            exit 1
        }
    fi
    
    # Clone repository to temp directory
    echo "Downloading repository..."
    git clone -q "$REPO_URL" "$INSTALL_DIR" 2>/dev/null || {
        echo "ERROR: Failed to clone repository from $REPO_URL"
        exit 1
    }
    
    echo "Repository cloned successfully!"
    echo "Starting installation..."
    echo ""
    
    # Change to install directory and run the script
    cd "$INSTALL_DIR" || exit 1
    exec bash install.sh "$@"
fi

# Normal execution from downloaded repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Check if lib directory exists
if [[ ! -d "$LIB_DIR" ]]; then
    echo "ERROR: Library directory not found: $LIB_DIR"
    echo "Please clone the full repository:"
    echo "  git clone https://github.com/shayanrsh/bug-bounty-toolkit-install-script.git"
    echo "  cd bug-bounty-toolkit-install-script"
    echo "  ./install.sh"
    exit 1
fi

# Source all library modules
source "${LIB_DIR}/config.sh"  || { echo "Failed to load config module"; exit 1; }
source "${LIB_DIR}/ui.sh"      || { echo "Failed to load UI module"; exit 1; }
source "${LIB_DIR}/utils.sh"   || { echo "Failed to load utils module"; exit 1; }
source "${LIB_DIR}/tools.sh"   || { echo "Failed to load tools module"; exit 1; }
source "${LIB_DIR}/core.sh"    || { echo "Failed to load core module"; exit 1; }

# ==============================================================================
# Error Handling
# ==============================================================================

cleanup() {
    log_debug "Cleanup function called"
    util_cleanup_temp
}

error_handler() {
    local line_no=$1
    local exit_code=$2
    
    log_error "Script failed at line $line_no with exit code $exit_code"
    ui_show_error "Installation failed unexpectedly" "Check the log file for details: $LOG_FILE"
    
    if [[ ${#ROLLBACK_STACK[@]} -gt 0 ]]; then
        log_warning "Rollback available."
        if [[ "$INTERACTIVE" == "true" ]]; then
            if ui_confirm "Execute rollback?" "y"; then
                rollback_execute
            fi
        fi
    fi
    
    cleanup
    exit "$exit_code"
}

trap 'error_handler $LINENO $?' ERR
trap cleanup EXIT

# ==============================================================================
# Global Variables
# ==============================================================================

INSTALL_MODE=""
INTERACTIVE="true"
DRY_RUN="false"
FORCE="false"
QUIET="false"
VERBOSE="false"
DEBUG="false"
SKIP_CHECKS="false"
PROFILE=""

# ==============================================================================
# Help Function
# ==============================================================================

show_help() {
    cat << 'EOF'
Security Tools Installer v3.0.0

USAGE:
    ./install.sh [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show version information
    -d, --dry-run          Preview installation without making changes
    -f, --force            Force installation (skip confirmations)
    --full                 Full installation (default)
    --zsh-only             Install ZSH environment only
    --tools-only           Install security tools only
    --go-tools             Install Go-based tools only
    --python-tools         Install Python-based tools only
    --wordlists            Install wordlists only
    --profile=PROFILE      Use profile (minimal/full/pentest/developer)
    --update               Update existing tools
    --uninstall            Uninstall all tools

EXAMPLES:
    ./install.sh                    # Interactive menu
    ./install.sh --full             # Full installation
    ./install.sh --dry-run --full   # Preview installation

GitHub: https://github.com/shayanrsh/bug-bounty-toolkit-install-script

EOF
}

show_version() {
    echo "Security Tools Installer v${SCRIPT_VERSION}"
    echo "License: MIT"
}

# ==============================================================================
# Argument Parsing
# ==============================================================================

parse_arguments() {
    if [[ $# -eq 0 ]]; then
        INSTALL_MODE="interactive"
        return 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) show_help; exit 0 ;;
            -v|--version) show_version; exit 0 ;;
            -d|--dry-run) DRY_RUN="true"; shift ;;
            -f|--force) FORCE="true"; shift ;;
            --full) INSTALL_MODE="full"; shift ;;
            --zsh-only) INSTALL_MODE="zsh"; shift ;;
            --tools-only) INSTALL_MODE="tools"; shift ;;
            --go-tools) INSTALL_MODE="go_tools"; shift ;;
            --python-tools) INSTALL_MODE="python_tools"; shift ;;
            --wordlists) INSTALL_MODE="wordlists"; shift ;;
            --custom) INSTALL_MODE="custom"; shift ;;
            --profile=*) PROFILE="${1#*=}"; INSTALL_MODE="profile"; shift ;;
            --update) INSTALL_MODE="update"; shift ;;
            --uninstall) INSTALL_MODE="uninstall"; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done
}

# ==============================================================================
# Interactive Menu
# ==============================================================================

interactive_menu() {
    ui_show_banner
    
    echo ""
    echo "Bug Bounty Toolkit Installer Menu"
    echo "=================================="
    echo ""
    echo "  1) Full Installation"
    echo "  2) ZSH Environment Only"
    echo "  3) Security Tools Only"
    echo "  4) Go Tools Only"
    echo "  5) Python Tools Only"
    echo "  6) Wordlists Only"
    echo "  7) Minimal Profile"
    echo "  8) Pentest Profile"
    echo "  9) Developer Profile"
    echo " 10) Custom Installation"
    echo " 11) Update Existing Tools"
    echo ""
    echo "  u) Uninstall All"
    echo "  q) Quit"
    echo ""
    
    read -rp "Select an option: " choice
    
    case "$choice" in
        1) INSTALL_MODE="full" ;;
        2) INSTALL_MODE="zsh" ;;
        3) INSTALL_MODE="tools" ;;
        4) INSTALL_MODE="go_tools" ;;
        5) INSTALL_MODE="python_tools" ;;
        6) INSTALL_MODE="wordlists" ;;
        7) INSTALL_MODE="profile"; PROFILE="minimal" ;;
        8) INSTALL_MODE="profile"; PROFILE="pentest" ;;
        9) INSTALL_MODE="profile"; PROFILE="developer" ;;
        10) INSTALL_MODE="custom" ;;
        11) INSTALL_MODE="update" ;;
        u|U) INSTALL_MODE="uninstall" ;;
        q|Q) exit 0 ;;
        *) echo "Invalid option"; exit 1 ;;
    esac
}

# ==============================================================================
# Main Function
# ==============================================================================

main() {
    util_init_logging
    parse_arguments "$@"
    
    if [[ -z "$INSTALL_MODE" ]]; then
        interactive_menu
    fi
    
    if [[ "$INSTALL_MODE" != "interactive" ]] && [[ "$QUIET" != "true" ]]; then
        ui_show_banner
    fi
    
    if [[ "$SKIP_CHECKS" != "true" ]] && [[ "$INSTALL_MODE" != "update" ]] && [[ "$INSTALL_MODE" != "uninstall" ]]; then
        log_info "Running pre-installation checks..."
        if ! core_pre_install_checks; then
            log_error "Pre-installation checks failed"
            exit 1
        fi
    fi
    
    case "$INSTALL_MODE" in
        full) core_install_full ;;
        zsh) core_install_zsh ;;
        tools) core_install_tools ;;
        go_tools) core_install_go_tools ;;
        python_tools) core_install_python_tools ;;
        wordlists) core_install_wordlists ;;
        profile) core_install_profile "$PROFILE" ;;
        custom) core_install_custom ;;
        update) core_update_tools ;;
        uninstall) core_uninstall_all ;;
        *) log_error "Invalid installation mode"; exit 1 ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        ui_show_completion
        config_save
        util_generate_manifest
        log_success "Installation completed successfully!"
    else
        log_error "Installation failed"
        exit 1
    fi
}

# ==============================================================================
# Entry Point
# ==============================================================================

main "$@"