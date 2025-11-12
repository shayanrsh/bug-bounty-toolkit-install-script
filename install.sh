#!/bin/bash#!/bin/bash#!/bin/bash



# ==============================================================================# ==============================================================================# ==============================================================================

# Security Tools Installer - Main Entry Point

# ==============================================================================# Security Tools Installer - Main Entry Point# Security Tools Installer - Main Entry Point

# Description: Professional, modular security tools installation framework

# Version: 3.0.0# ==============================================================================# ==============================================================================

# Author: Bug Bounty Community

# License: MIT# Description: Professional, modular security tools installation framework# Description: Professional, modular security tools installation framework

#

# Architecture:# Version: 3.0.0# Version: 3.0.0

#   - Modular plugin-based system for easy tool additions

#   - Robust error handling with rollback capabilities# Author: DevOps Security Team# Author: DevOps Security Team

#   - Professional UI/UX with progress indicators

#   - Support for multiple installation profiles# License: MIT# License: MIT

#   - Dry-run mode for preview

#   - Comprehensive logging and manifest generation##

#

# Usage:# Architecture:# Architecture:

#   ./install.sh [OPTIONS]

##   - Modular plugin-based system for easy tool additions#   - Modular plugin-based system for easy tool additions

# Options:

#   -h, --help              Show help message#   - Robust error handling with rollback capabilities#   - Robust error handling with rollback capabilities

#   -v, --version           Show version

#   -d, --dry-run          Preview installation without making changes#   - Professional UI/UX with progress indicators#   - Professional UI/UX with progress indicators

#   -f, --force            Force installation (skip confirmations)

#   -q, --quiet            Quiet mode (minimal output)#   - Support for multiple installation profiles#   - Support for multiple installation profiles

#   -V, --verbose          Verbose mode (detailed output)

#   --debug                Enable debug mode#   - Dry-run mode for preview#   - Dry-run mode for preview

#   --no-interactive       Non-interactive mode

#   --skip-checks          Skip system requirement checks#   - Comprehensive logging and manifest generation#   - Comprehensive logging and manifest generation

#   --full                 Full installation (default)

#   --zsh-only             Install ZSH environment only##

#   --tools-only           Install security tools only

#   --go-tools             Install Go tools only# Usage:# Usage:

#   --python-tools         Install Python tools only

#   --wordlists            Install wordlists only#   ./install.sh [OPTIONS]#   ./install.sh [OPTIONS]

#   --profile=PROFILE      Install using profile (minimal/full/pentest/developer)

#   --update               Update existing tools##

#   --uninstall            Uninstall all tools

#   --custom               Custom installation (interactive selection)# Options:# Options:

#

# Examples:#   -h, --help              Show help message#   -h, --help              Show help message

#   ./install.sh                    # Interactive menu

#   ./install.sh --full             # Full installation#   -v, --version           Show version#   -v, --version           Show version

#   ./install.sh --dry-run --full   # Preview full installation

#   ./install.sh --profile=pentest  # Install pentest profile#   -d, --dry-run          Preview installation without making changes#   -d, --dry-run          Preview installation without making changes

#   ./install.sh --update           # Update existing tools

##   -f, --force            Force installation (skip confirmations)#   -f, --force            Force installation (skip confirmations)

# ==============================================================================

#   -q, --quiet            Quiet mode (minimal output)#   -q, --quiet            Quiet mode (minimal output)

set -uo pipefail

IFS=$'\n\t'#   -V, --verbose          Verbose mode (detailed output)#   -V, --verbose          Verbose mode (detailed output)



# ==============================================================================#   --debug                Enable debug mode#   --debug                Enable debug mode

# Source Library Modules

# ==============================================================================#   --no-interactive       Non-interactive mode#   --no-interactive       Non-interactive mode



SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"#   --skip-checks          Skip system requirement checks#   --skip-checks          Skip system requirement checks

LIB_DIR="${SCRIPT_DIR}/lib"

#   --full                 Full installation (default)#   --full                 Full installation (default)

# Check if lib directory exists

if [[ ! -d "$LIB_DIR" ]]; then#   --zsh-only             Install ZSH environment only#   --zsh-only             Install ZSH environment only

    echo "ERROR: Library directory not found: $LIB_DIR"

    exit 1#   --tools-only           Install security tools only#   --tools-only           Install security tools only

fi

#   --go-tools             Install Go tools only#   --go-tools             Install Go tools only

# Source all library modules

# shellcheck disable=SC1091#   --python-tools         Install Python tools only#   --python-tools         Install Python tools only

source "${LIB_DIR}/config.sh"  || { echo "Failed to load config module"; exit 1; }

# shellcheck disable=SC1091#   --wordlists            Install wordlists only#   --wordlists            Install wordlists only

source "${LIB_DIR}/ui.sh"      || { echo "Failed to load UI module"; exit 1; }

# shellcheck disable=SC1091#   --profile=PROFILE      Install using profile (minimal/full/pentest/developer)#   --profile=PROFILE      Install using profile (minimal/full/pentest/developer)

source "${LIB_DIR}/utils.sh"   || { echo "Failed to load utils module"; exit 1; }

# shellcheck disable=SC1091#   --update               Update existing tools#   --update               Update existing tools

source "${LIB_DIR}/tools.sh"   || { echo "Failed to load tools module"; exit 1; }

# shellcheck disable=SC1091#   --uninstall            Uninstall all tools#   --uninstall            Uninstall all tools

source "${LIB_DIR}/core.sh"    || { echo "Failed to load core module"; exit 1; }

#   --custom               Custom installation (interactive selection)#   --custom               Custom installation (interactive selection)

# ==============================================================================

# Error Handling and Cleanup##

# ==============================================================================

# Examples:# Examples:

cleanup() {

    log_debug "Cleanup function called"#   ./install.sh                    # Interactive menu#   ./install.sh                    # Interactive menu

    util_cleanup_temp

}#   ./install.sh --full             # Full installation#   ./install.sh --full             # Full installation



error_handler() {#   ./install.sh --dry-run --full   # Preview full installation#   ./install.sh --dry-run --full   # Preview full installation

    local line_no=$1

    local exit_code=$2#   ./install.sh --profile=pentest  # Install pentest profile#   ./install.sh --profile=pentest  # Install pentest profile

    

    log_error "Script failed at line $line_no with exit code $exit_code"#   ./install.sh --update           # Update existing tools#   ./install.sh --update           # Update existing tools

    ui_show_error "Installation failed unexpectedly" \

        "Check the log file for details: $LOG_FILE"##

    

    if [[ ${#ROLLBACK_STACK[@]} -gt 0 ]]; then# ==============================================================================# ==============================================================================

        log_warning "Rollback available."

        if [[ "$INTERACTIVE" == "true" ]]; then

            if ui_confirm "Execute rollback?" "y"; then

                rollback_executeset -uo pipefailset -uo pipefail

            fi

        fiIFS=$'\n\t'IFS=$'\n\t'

    fi

    

    cleanup

    exit "$exit_code"# ==============================================================================# Script configuration

}

# Source Library Modulesreadonly SCRIPT_VERSION="2.0"

# Set up error handling

trap 'error_handler $LINENO $?' ERR# ==============================================================================readonly LOG_FILE="/tmp/security-tools-install.log"

trap cleanup EXIT

readonly CONFIG_FILE="$HOME/.security-tools-config"

# ==============================================================================

# Global VariablesSCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================

LIB_DIR="${SCRIPT_DIR}/lib"# Trap errors and cleanup

INSTALL_MODE=""

INTERACTIVE="true"trap 'log_error "Script failed at line $LINENO. Exit code: $?"' ERR

DRY_RUN="false"

FORCE="false"# Check if lib directory existstrap 'cleanup' EXIT

QUIET="false"

VERBOSE="false"if [[ ! -d "$LIB_DIR" ]]; then

DEBUG="false"

SKIP_CHECKS="false"    echo "ERROR: Library directory not found: $LIB_DIR"# Colors for output

PROFILE=""

    exit 1readonly RED='\033[0;31m'

# ==============================================================================

# Help and Version Functionsfireadonly GREEN='\033[0;32m'

# ==============================================================================

readonly YELLOW='\033[1;33m'

show_help() {

    cat << EOF# Source all library modulesreadonly BLUE='\033[0;34m'

${BOLD}${CYAN}Security Tools Installer v${SCRIPT_VERSION}${NC}

# shellcheck disable=SC1091readonly PURPLE='\033[0;35m'

${BOLD}USAGE:${NC}

    $0 [OPTIONS]source "${LIB_DIR}/config.sh"  || { echo "Failed to load config module"; exit 1; }readonly CYAN='\033[0;36m'



${BOLD}OPTIONS:${NC}# shellcheck disable=SC1091readonly NC='\033[0m' # No Color

    ${GREEN}-h, --help${NC}              Show this help message

    ${GREEN}-v, --version${NC}           Show version informationsource "${LIB_DIR}/ui.sh"      || { echo "Failed to load UI module"; exit 1; }

    ${GREEN}-d, --dry-run${NC}           Preview installation without making changes

    ${GREEN}-f, --force${NC}             Force installation (skip confirmations)# shellcheck disable=SC1091# Global variables

    ${GREEN}-q, --quiet${NC}             Quiet mode (minimal output)

    ${GREEN}-V, --verbose${NC}           Verbose mode (detailed output)source "${LIB_DIR}/utils.sh"   || { echo "Failed to load utils module"; exit 1; }USER_HOME=""

    ${GREEN}--debug${NC}                 Enable debug mode

    ${GREEN}--no-interactive${NC}        Non-interactive mode# shellcheck disable=SC1091TOTAL_STEPS=0

    ${GREEN}--skip-checks${NC}           Skip system requirement checks

source "${LIB_DIR}/tools.sh"   || { echo "Failed to load tools module"; exit 1; }CURRENT_STEP=0

${BOLD}INSTALLATION MODES:${NC}

    ${GREEN}--full${NC}                  Install everything (default)# shellcheck disable=SC1091

    ${GREEN}--zsh-only${NC}              Install ZSH environment only

    ${GREEN}--tools-only${NC}            Install security tools onlysource "${LIB_DIR}/core.sh"    || { echo "Failed to load core module"; exit 1; }# Cleanup function

    ${GREEN}--go-tools${NC}              Install Go-based tools only

    ${GREEN}--python-tools${NC}          Install Python-based tools onlycleanup() {

    ${GREEN}--wordlists${NC}             Install wordlists only

    ${GREEN}--custom${NC}                Custom installation (interactive selection)# ==============================================================================    log_info "Cleaning up temporary files..."



${BOLD}PROFILES:${NC}# Error Handling and Cleanup    # Add any cleanup operations here

    ${GREEN}--profile=minimal${NC}       Essential tools only

    ${GREEN}--profile=full${NC}          All available tools (same as --full)# ==============================================================================}

    ${GREEN}--profile=pentest${NC}       Pentesting-focused configuration

    ${GREEN}--profile=developer${NC}     Development environment



${BOLD}MANAGEMENT:${NC}cleanup() {# Progress bar configuration

    ${GREEN}--update${NC}                Update existing tools

    ${GREEN}--uninstall${NC}             Uninstall all tools    log_debug "Cleanup function called"readonly PROGRESS_BAR_WIDTH=50



${BOLD}EXAMPLES:${NC}    util_cleanup_tempreadonly SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

    $0                              # Interactive menu

    $0 --full                       # Full installation}

    $0 --dry-run --full             # Preview installation

    $0 --profile=pentest            # Install pentest profile# Enhanced progress bar functions

    $0 --zsh-only                   # ZSH environment only

    $0 --go-tools --python-tools    # Go and Python toolserror_handler() {draw_progress_bar() {

    $0 --update                     # Update existing tools

    local line_no=$1    local current="$1"

${BOLD}DOCUMENTATION:${NC}

    README.md           Complete user guide    local exit_code=$2    local total="$2"

    ARCHITECTURE.md     Technical documentation

    QUICKSTART.md       Quick reference guide        local message="$3"



${BOLD}SUPPORT:${NC}    log_error "Script failed at line $line_no with exit code $exit_code"    local percentage=$((current * 100 / total))

    GitHub: https://github.com/shayanrsh/bug-bounty-toolkit-install-script

    Issues: https://github.com/shayanrsh/bug-bounty-toolkit-install-script/issues    ui_show_error "Installation failed unexpectedly" \    local filled_width=$((current * PROGRESS_BAR_WIDTH / total))



EOF        "Check the log file for details: $LOG_FILE"    local empty_width=$((PROGRESS_BAR_WIDTH - filled_width))

}

        

show_version() {

    cat << EOF    if [[ ${#ROLLBACK_STACK[@]} -gt 0 ]]; then    # Create the progress bar

${BOLD}${CYAN}Security Tools Installer${NC}

Version: ${GREEN}${SCRIPT_VERSION}${NC}        log_warning "Rollback available."    local filled_bar=$(printf "█%.0s" $(seq 1 $filled_width))

License: MIT

Author: Bug Bounty Community        if [[ "$INTERACTIVE" == "true" ]]; then    local empty_bar=$(printf "░%.0s" $(seq 1 $empty_width))



${BOLD}Features:${NC}            if ui_confirm "Execute rollback?" "y"; then    

  ✓ Modular architecture

  ✓ 30+ security tools                rollback_execute    # Color coding based on percentage

  ✓ Automatic rollback

  ✓ Multiple profiles            fi    local bar_color="$RED"

  ✓ WSL2 compatible

        fi    if [[ $percentage -ge 75 ]]; then

${BOLD}Repository:${NC}

  https://github.com/shayanrsh/bug-bounty-toolkit-install-script    fi        bar_color="$GREEN"



EOF        elif [[ $percentage -ge 50 ]]; then

}

    cleanup        bar_color="$YELLOW"

# ==============================================================================

# Argument Parsing    exit "$exit_code"    elif [[ $percentage -ge 25 ]]; then

# ==============================================================================

}        bar_color="$BLUE"

parse_arguments() {

    # If no arguments, enable interactive mode    fi

    if [[ $# -eq 0 ]]; then

        INSTALL_MODE="interactive"# Set up traps    

        return 0

    fitrap 'error_handler ${LINENO} $?' ERR    # Format: [████████████░░░░░░░░] 75% (15/20) Installing Go tools...

    

    while [[ $# -gt 0 ]]; dotrap cleanup EXIT SIGINT SIGTERM    printf "\r${CYAN}[${bar_color}%s${CYAN}%s${CYAN}] %3d%% (%d/%d) ${NC}%s" \

        case "$1" in

            -h|--help)           "$filled_bar" "$empty_bar" "$percentage" "$current" "$total" "$message"

                show_help

                exit 0# ==============================================================================}

                ;;

            -v|--version)# Command Line Argument Parsing

                show_version

                exit 0# ==============================================================================# Spinner for long-running operations

                ;;

            -d|--dry-run)show_spinner() {

                DRY_RUN="true"

                log_info "Dry-run mode enabled"show_help() {    local pid=$1

                shift

                ;;    cat << EOF    local message="$2"

            -f|--force)

                FORCE="true"${SCRIPT_NAME} v${SCRIPT_VERSION}    local spinner_index=0

                shift

                ;;    

            -q|--quiet)

                QUIET="true"Professional security tools installation framework with modular architecture.    echo -ne "\n"

                VERBOSE="false"

                shift    while kill -0 "$pid" 2>/dev/null; do

                ;;

            -V|--verbose)USAGE:        local spinner_char="${SPINNER_CHARS:$spinner_index:1}"

                VERBOSE="true"

                QUIET="false"    $0 [OPTIONS]        printf "\r${YELLOW}%s${NC} %s" "$spinner_char" "$message"

                shift

                ;;        spinner_index=$(( (spinner_index + 1) % ${#SPINNER_CHARS} ))

            --debug)

                DEBUG="true"OPTIONS:        sleep 0.1

                VERBOSE="true"

                set -x    -h, --help              Show this help message    done

                shift

                ;;    -v, --version           Show version information    printf "\r${GREEN}✓${NC} %s\n" "$message"

            --no-interactive)

                INTERACTIVE="false"    -d, --dry-run          Preview installation without making changes}

                shift

                ;;    -f, --force            Force installation (skip confirmations)

            --skip-checks)

                SKIP_CHECKS="true"    -q, --quiet            Quiet mode (minimal output)# Enhanced progress tracking

                shift

                ;;    -V, --verbose          Verbose mode (detailed output)update_progress() {

            --full)

                INSTALL_MODE="full"    --debug                Enable debug mode with detailed logs    ((CURRENT_STEP++))

                shift

                ;;    --no-interactive       Non-interactive mode (use defaults)    local message="${1:-Step $CURRENT_STEP}"

            --zsh-only)

                INSTALL_MODE="zsh"    --skip-checks          Skip system requirement checks (dangerous)    draw_progress_bar "$CURRENT_STEP" "$TOTAL_STEPS" "$message"

                shift

                ;;    

            --tools-only)

                INSTALL_MODE="tools"INSTALLATION MODES:    # Add a small delay for visual effect

                shift

                ;;    --full                 Full installation (all tools) [DEFAULT]    sleep 0.1

            --go-tools)

                INSTALL_MODE="go_tools"    --zsh-only             Install ZSH + Oh My ZSH only}

                shift

                ;;    --tools-only           Install security tools only

            --python-tools)

                INSTALL_MODE="python_tools"    --go-tools             Install Go-based tools only# Progress bar for downloads

                shift

                ;;    --python-tools         Install Python-based tools onlydownload_with_progress() {

            --wordlists)

                INSTALL_MODE="wordlists"    --wordlists            Install wordlists only    local url="$1"

                shift

                ;;    --profile=PROFILE      Use installation profile    local output="$2"

            --custom)

                INSTALL_MODE="custom"    --custom               Custom installation (interactive)    local description="$3"

                shift

                ;;    

            --profile=*)

                PROFILE="${1#*=}"MAINTENANCE OPERATIONS:    log_info "Downloading $description..."

                INSTALL_MODE="profile"

                shift    --update               Update all installed tools    

                ;;

            --update)    --uninstall            Remove all installed tools    # Use wget with progress bar

                INSTALL_MODE="update"

                shift    wget --progress=bar:force:noscroll "$url" -O "$output" 2>&1 | \

                ;;

            --uninstall)PROFILES:    while IFS= read -r line; do

                INSTALL_MODE="uninstall"

                shift    minimal                ZSH + Go + Essential tools (nuclei, subfinder, httpx)        # Parse wget progress and create custom progress bar

                ;;

            *)    full                   All available tools and wordlists        if [[ $line =~ ([0-9]+)% ]]; then

                log_error "Unknown option: $1"

                echo "Use --help for usage information"    pentest                Pentesting focused (tools + wordlists)            local percent="${BASH_REMATCH[1]}"

                exit 1

                ;;    developer              Development environment (ZSH + Go + Rust + build tools)            local filled=$((percent * PROGRESS_BAR_WIDTH / 100))

        esac

    done            local empty=$((PROGRESS_BAR_WIDTH - filled))

}

EXAMPLES:            local filled_bar=$(printf "█%.0s" $(seq 1 $filled))

# ==============================================================================

# Interactive Menu    # Interactive mode with menu            local empty_bar=$(printf "░%.0s" $(seq 1 $empty))

# ==============================================================================

    $0            printf "\r${CYAN}Downloading: [${GREEN}%s${CYAN}%s${CYAN}] %3d%% ${NC}%s" \

interactive_menu() {

    ui_show_banner                   "$filled_bar" "$empty_bar" "$percent" "$description"

    

    echo ""    # Full installation with verbose output        fi

    echo "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"

    echo "${BOLD}${CYAN}║${NC}          ${BOLD}Bug Bounty Toolkit Installer Menu${NC}          ${BOLD}${CYAN}║${NC}"    $0 --full --verbose    done

    echo "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

    echo ""    echo # New line after progress

    echo "  ${GREEN}1)${NC} Full Installation ${DIM}(Everything)${NC}"

    echo "  ${GREEN}2)${NC} ZSH Environment Only"    # Dry run to preview installation}

    echo "  ${GREEN}3)${NC} Security Tools Only ${DIM}(No ZSH)${NC}"

    echo "  ${GREEN}4)${NC} Go Tools Only"    $0 --dry-run --full

    echo "  ${GREEN}5)${NC} Python Tools Only"

    echo "  ${GREEN}6)${NC} Wordlists Only"# Enhanced logging functions with timestamps and file logging

    echo "  ${GREEN}7)${NC} Minimal Profile ${DIM}(Essential tools)${NC}"

    echo "  ${GREEN}8)${NC} Pentest Profile ${DIM}(Pentesting focus)${NC}"    # Install pentesting profilelog_message() {

    echo "  ${GREEN}9)${NC} Developer Profile ${DIM}(Dev environment)${NC}"

    echo "  ${GREEN}10)${NC} Custom Installation ${DIM}(Choose components)${NC}"    $0 --profile=pentest    local level="$1"

    echo "  ${GREEN}11)${NC} Update Existing Tools"

    echo ""    local color="$2"

    echo "  ${YELLOW}u)${NC} Uninstall All"

    echo "  ${RED}q)${NC} Quit"    # Non-interactive full installation    local message="$3"

    echo ""

    echo "${BOLD}${CYAN}────────────────────────────────────────────────────────────${NC}"    $0 --no-interactive --full    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    

    read -rp "$(echo -e "${BOLD}Select an option: ${NC}")" choice    local icon=""

    

    case "$choice" in    # Update existing tools    

        1) INSTALL_MODE="full" ;;

        2) INSTALL_MODE="zsh" ;;    $0 --update    # Add icons for different log levels

        3) INSTALL_MODE="tools" ;;

        4) INSTALL_MODE="go_tools" ;;    case "$level" in

        5) INSTALL_MODE="python_tools" ;;

        6) INSTALL_MODE="wordlists" ;;    # Debug mode installation        "INFO")    icon="ℹ️ " ;;

        7) INSTALL_MODE="profile"; PROFILE="minimal" ;;

        8) INSTALL_MODE="profile"; PROFILE="pentest" ;;    $0 --debug --full        "SUCCESS") icon="✅" ;;

        9) INSTALL_MODE="profile"; PROFILE="developer" ;;

        10) INSTALL_MODE="custom" ;;        "WARNING") icon="⚠️ " ;;

        11) INSTALL_MODE="update" ;;

        u|U) INSTALL_MODE="uninstall" ;;LOGS AND FILES:        "ERROR")   icon="❌" ;;

        q|Q) log_info "Installation cancelled by user"; exit 0 ;;

        *) log_error "Invalid option"; exit 1 ;;    Log file:     ${LOG_DIR}/install-*.log        "DEBUG")   icon="🔍" ;;

    esac

}    Manifest:     ${MANIFEST_FILE}    esac



# ==============================================================================    Config:       ${CONFIG_FILE}    

# Main Execution

# ==============================================================================    echo -e "${color}${icon} [${level}] ${timestamp}${NC} $message" | tee -a "$LOG_FILE"



main() {For more information, visit: https://github.com/yourusername/security-tools-installer}

    # Initialize

    util_init_loggingEOF

    

    # Parse command-line arguments}# Fancy box drawing functions

    parse_arguments "$@"

    draw_box() {

    # Show interactive menu if mode not set

    if [[ -z "$INSTALL_MODE" ]]; thenshow_version() {    local text="$1"

        interactive_menu

    fi    echo "$SCRIPT_NAME v$SCRIPT_VERSION"    local color="${2:-$CYAN}"

    

    # Display banner for non-interactive modes    echo "Author: $SCRIPT_AUTHOR"    local width=$((${#text} + 4))

    if [[ "$INSTALL_MODE" != "interactive" ]] && [[ "$QUIET" != "true" ]]; then

        ui_show_banner}    

    fi

        echo -e "${color}╔$(printf "═%.0s" $(seq 1 $((width - 2))))╗${NC}"

    # Pre-installation checks

    if [[ "$SKIP_CHECKS" != "true" ]] && [[ "$INSTALL_MODE" != "update" ]] && [[ "$INSTALL_MODE" != "uninstall" ]]; thenparse_arguments() {    echo -e "${color}║ ${text} ║${NC}"

        log_info "Running pre-installation checks..."

        if ! core_pre_install_checks; then    while [[ $# -gt 0 ]]; do    echo -e "${color}╚$(printf "═%.0s" $(seq 1 $((width - 2))))╝${NC}"

            log_error "Pre-installation checks failed"

            exit 1        case $1 in}

        fi

    fi            -h|--help)

    

    # Execute based on mode                show_help# Section headers

    case "$INSTALL_MODE" in

        full)                exit 0print_section_header() {

            log_info "Starting full installation..."

            core_install_full                ;;    local title="$1"

            ;;

        zsh)            -v|--version)    local color="${2:-$BLUE}"

            log_info "Installing ZSH environment..."

            core_install_zsh                show_version    

            ;;

        tools)                exit 0    echo -e "\n${color}╭─────────────────────────────────────────────────────────────────╮${NC}"

            log_info "Installing security tools..."

            core_install_tools                ;;    echo -e "${color}│$(printf "%*s" $(((67-${#title})/2)) "")${title}$(printf "%*s" $(((67-${#title})/2)) "")│${NC}"

            ;;

        go_tools)            -d|--dry-run)    echo -e "${color}╰─────────────────────────────────────────────────────────────────╯${NC}\n"

            log_info "Installing Go-based tools..."

            core_install_go_tools                DRY_RUN=true}

            ;;

        python_tools)                log_info "Dry run mode enabled"

            log_info "Installing Python-based tools..."

            core_install_python_tools                shift# Step indicator

            ;;

        wordlists)                ;;print_step() {

            log_info "Installing wordlists..."

            core_install_wordlists            -f|--force)    local step_num="$1"

            ;;

        profile)                FORCE_INSTALL=true    local total_steps="$2"

            log_info "Installing profile: $PROFILE..."

            core_install_profile "$PROFILE"                log_info "Force mode enabled"    local description="$3"

            ;;

        custom)                shift    

            log_info "Custom installation mode..."

            core_install_custom                ;;    echo -e "\n${PURPLE}┌─ Step ${step_num}/${total_steps} ─────────────────────────────────────────────┐${NC}"

            ;;

        update)            -q|--quiet)    echo -e "${PURPLE}│ ${description}$(printf "%*s" $((60-${#description})) "")│${NC}"

            log_info "Updating existing tools..."

            core_update_tools                VERBOSE=false    echo -e "${PURPLE}└─────────────────────────────────────────────────────────────────┘${NC}"

            ;;

        uninstall)                shift}

            log_warning "Uninstalling all tools..."

            core_uninstall_all                ;;

            ;;

        *)            -V|--verbose)# Logging functions

            log_error "Invalid installation mode: $INSTALL_MODE"

            exit 1                VERBOSE=truelog_info() {

            ;;

    esac                log_info "Verbose mode enabled"    log_message "INFO" "$BLUE" "$1"

    

    # Show completion message                shift}

    if [[ $? -eq 0 ]]; then

        ui_show_completion                ;;

        

        # Save installation info            --debug)log_success() {

        config_save

                        DEBUG=true    log_message "SUCCESS" "$GREEN" "$1"

        # Generate manifest

        util_generate_manifest                log_info "Debug mode enabled"}

        

        log_success "Installation completed successfully!"                shift

        

        if [[ "$INSTALL_MODE" =~ ^(full|zsh|profile)$ ]]; then                ;;log_warning() {

            echo ""

            echo "${BOLD}${YELLOW}⚠ Important:${NC} Please restart your terminal or run:"            --no-interactive)    log_message "WARNING" "$YELLOW" "$1"

            echo "  ${CYAN}source ~/.zshrc${NC}"

        fi                INTERACTIVE=false}

    else

        log_error "Installation failed"                log_info "Non-interactive mode"

        exit 1

    fi                shiftlog_error() {

}

                ;;    log_message "ERROR" "$RED" "$1"

# ==============================================================================

# Script Entry Point            --skip-checks)}

# ==============================================================================

                SKIP_CHECKS=true

main "$@"

                log_warning "Skipping system checks (not recommended)"log_debug() {

                shift    if [[ "${DEBUG:-false}" == "true" ]]; then

                ;;        log_message "DEBUG" "$PURPLE" "$1"

            --full)    fi

                INSTALL_MODE="full"}

                shift

                ;;# Utility functions

            --zsh-only)command_exists() {

                INSTALL_MODE="zsh"    command -v "$1" &> /dev/null

                shift}

                ;;

            --tools-only)is_package_installed() {

                INSTALL_MODE="tools"    dpkg -l | grep -q "^ii  $1 "

                shift}

                ;;

            --go-tools)retry_command() {

                INSTALL_MODE="go_tools"    local max_attempts="$1"

                shift    local delay="$2"

                ;;    shift 2

            --python-tools)    local count=0

                INSTALL_MODE="python_tools"    

                shift    until "$@"; do

                ;;        count=$((count + 1))

            --wordlists)        if [[ $count -lt $max_attempts ]]; then

                INSTALL_MODE="wordlists"            log_warning "Command failed. Attempt $count/$max_attempts. Retrying in ${delay}s..."

                shift            sleep "$delay"

                ;;        else

            --profile=*)            log_error "Command failed after $max_attempts attempts: $*"

                INSTALL_MODE="profile"            return 1

                PROFILE_NAME="${1#*=}"        fi

                shift    done

                ;;}

            --custom)

                INSTALL_MODE="custom"# System information

                shiftget_system_info() {

                ;;    log_info "Gathering system information..."

            --update)    

                INSTALL_MODE="update"    # Detect environment type

                shift    local env_type="Linux"

                ;;    if grep -qi microsoft /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then

            --uninstall)        env_type="WSL2/WSL"

                INSTALL_MODE="uninstall"    fi

                shift    

                ;;    log_info "Environment: $env_type"

            *)    log_info "OS: $(lsb_release -d | cut -f2 2>/dev/null || echo 'Unknown')"

                log_error "Unknown option: $1"    log_info "Kernel: $(uname -r)"

                echo "Use --help for usage information"    log_info "Architecture: $(uname -m)"

                exit 1    log_info "User: $(whoami)"

                ;;    log_info "Home: $USER_HOME"

        esac    

    done    # WSL2 specific info

}    if [[ "$env_type" == "WSL2/WSL" ]]; then

        log_info "WSL Distribution: ${WSL_DISTRO_NAME:-Unknown}"

# ==============================================================================        if [[ -n "${WSL_INTEROP:-}" ]]; then

# Interactive Menu            log_info "Windows Interop: Enabled"

# ==============================================================================        fi

    fi

interactive_menu() {    

    while true; do    # Display memory and disk info

        ui_show_banner    local memory_info=$(free -h | awk '/^Mem:/ {print $2}' 2>/dev/null || echo "Unknown")

        ui_menu_main    log_info "Available Memory: $memory_info"

            

        read -p "Enter your choice [0-11]: " choice    local disk_info=$(df -h "$USER_HOME" 2>/dev/null | awk 'NR==2 {print $4}' || echo "Unknown")

        echo    log_info "Available Disk Space: $disk_info"

        }

        case $choice in

            1)# Check system requirements

                core_install_fullcheck_system_requirements() {

                break    log_info "Checking system requirements..."

                ;;    

            2)    # Check if running in WSL2

                core_install_zsh_only    local is_wsl=false

                break    if grep -qi microsoft /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then

                ;;        is_wsl=true

            3)        log_info "WSL2/WSL environment detected"

                core_install_tools_only    fi

                break    

                ;;    # Check Ubuntu version (with WSL compatibility)

            4)    if ! lsb_release -d | grep -qi "ubuntu"; then

                core_install_go_tools_only        log_error "This script is designed for Ubuntu systems"

                break        read -p "Continue anyway? (y/n): " -n 1 -r

                ;;        echo

            5)        if [[ ! $REPLY =~ ^[Yy]$ ]]; then

                core_install_python_tools_only            exit 1

                break        fi

                ;;        log_warning "Proceeding with non-Ubuntu system at user request"

            6)    fi

                core_install_wordlists_only    

                break    # Determine the correct path for disk space check

                ;;    local check_path="$HOME"

            7)    if [[ -z "$check_path" || "$check_path" == "/" ]]; then

                echo "Select profile:"        check_path="/home"

                echo "  1) minimal"    fi

                echo "  2) full"    

                echo "  3) pentest"    # For WSL, also try Windows drives if home check fails

                echo "  4) developer"    local available_space=0

                read -p "Choice: " profile_choice    if [[ "$is_wsl" == true ]]; then

                        # Try to get space from Windows C: drive if available

                case $profile_choice in        if [[ -d "/mnt/c" ]]; then

                    1) core_install_profile "minimal" ;;            available_space=$(df "/mnt/c" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")

                    2) core_install_profile "full" ;;            if [[ $available_space -gt 0 ]]; then

                    3) core_install_profile "pentest" ;;                log_info "Using Windows C: drive space for WSL2: $((available_space/1024/1024))GB available"

                    4) core_install_profile "developer" ;;                check_path="/mnt/c"

                    *) log_error "Invalid profile choice" ;;            fi

                esac        fi

                break    fi

                ;;    

            8)    # Fallback to home directory space check

                core_install_custom    if [[ $available_space -eq 0 ]]; then

                break        available_space=$(df "$check_path" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")

                ;;    fi

            9)    

                core_update_tools    # If still no space detected, try root filesystem

                break    if [[ $available_space -eq 0 ]]; then

                ;;        available_space=$(df "/" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")

            10)        check_path="/"

                core_uninstall_all    fi

                break    

                ;;    local required_space=5242880  # 5GB in KB

            11)    local available_gb=$((available_space/1024/1024))

                DRY_RUN=true    

                core_dry_run_summary    log_info "Disk space check on $check_path: ${available_gb}GB available"

                if ui_confirm "Proceed with installation?" "y"; then    

                    DRY_RUN=false    if [[ $available_space -lt $required_space ]]; then

                    core_install_full        log_error "Insufficient disk space. Required: 5GB, Available: ${available_gb}GB"

                fi        echo

                break        log_warning "You can proceed with limited disk space, but some installations might fail."

                ;;        read -p "Continue with insufficient disk space? (y/n): " -n 1 -r

            0)        echo

                log_info "Exiting..."        if [[ ! $REPLY =~ ^[Yy]$ ]]; then

                exit 0            exit 1

                ;;        fi

            *)        log_warning "Proceeding with insufficient disk space at user request"

                log_error "Invalid choice. Please try again."    fi

                sleep 2    

                ;;    # Check internet connectivity (with multiple fallbacks)

        esac    log_info "Testing internet connectivity..."

    done    local internet_ok=false

}    

    # Try multiple endpoints for connectivity check

# ==============================================================================    local test_urls=("google.com" "github.com" "ubuntu.com" "8.8.8.8")

# Main Function    

# ==============================================================================    for url in "${test_urls[@]}"; do

        if ping -c 1 -W 5 "$url" &> /dev/null; then

main() {            internet_ok=true

    # Initialize            log_info "Internet connectivity confirmed via $url"

    config_init_dirs            break

    ui_log_init        fi

    config_load    done

    config_export    

        if [[ "$internet_ok" == false ]]; then

    # Show banner for interactive mode        log_error "No internet connection detected"

    if [[ "$INTERACTIVE" == "true" ]] && [[ -z "$INSTALL_MODE" ]]; then        echo

        ui_show_banner        log_warning "Internet connection is required to download tools and packages."

    fi        read -p "Continue without internet connectivity check? (y/n): " -n 1 -r

            echo

    log_info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"        if [[ ! $REPLY =~ ^[Yy]$ ]]; then

    log_info "Mode: ${INSTALL_MODE:-interactive}"            exit 1

            fi

    # Pre-installation checks        log_warning "Proceeding without internet connectivity verification"

    if [[ "$SKIP_CHECKS" == "false" ]] && [[ "$INSTALL_MODE" != "uninstall" ]]; then    fi

        core_pre_install_checks || exit 1    

    fi    # WSL2 specific checks and warnings

        if [[ "$is_wsl" == true ]]; then

    # Execute based on mode        log_info "WSL2 environment detected - applying WSL-specific configurations"

    if [[ -z "$INSTALL_MODE" ]]; then        

        # Interactive menu        # Check if systemd is available (WSL2 with systemd support)

        interactive_menu        if command -v systemctl &> /dev/null; then

    else            log_info "systemd detected in WSL2"

        case "$INSTALL_MODE" in        else

            full)            log_warning "systemd not available - some services might not work as expected"

                core_install_full        fi

                ;;        

            zsh)        # Check for Windows interop

                core_install_zsh_only        if [[ -n "${WSL_INTEROP:-}" ]]; then

                ;;            log_info "Windows interoperability is available"

            tools)        fi

                core_install_tools_only        

                ;;        # Warn about snap packages in WSL2

            go_tools)        log_warning "Note: Snap packages may have limited functionality in WSL2"

                core_install_go_tools_only        if [[ "${INTERACTIVE:-true}" == "true" ]]; then

                ;;            read -p "Continue with WSL2 setup? (y/n): " -n 1 -r

            python_tools)            echo

                core_install_python_tools_only            if [[ ! $REPLY =~ ^[Yy]$ ]]; then

                ;;                exit 1

            wordlists)            fi

                core_install_wordlists_only        else

                ;;            log_info "Non-interactive mode: automatically continuing with WSL2 setup"

            profile)        fi

                core_install_profile "$PROFILE_NAME"    fi

                ;;    

            custom)    log_success "System requirements check completed"

                core_install_custom}

                ;;

            update)# Check if running as root and handle accordingly

                core_update_toolscheck_root() {

                ;;    if [[ $EUID -eq 0 ]]; then

            uninstall)        log_warning "Running as root user. This is acceptable for server setups."

                core_uninstall_all        log_info "Setting up environment for root user..."

                ;;        USER_HOME="/root"

            *)        

                log_error "Unknown installation mode: $INSTALL_MODE"        # Create non-root user prompt for security

                exit 1        if [[ "${INTERACTIVE:-true}" == "true" ]]; then

                ;;            read -p "Would you like to create a non-root user for security tools? (y/n): " -n 1 -r

        esac            echo

    fi            if [[ $REPLY =~ ^[Yy]$ ]]; then

                    read -p "Enter username: " new_user

    # Post-installation tasks                if ! id "$new_user" &>/dev/null; then

    if [[ "$INSTALL_MODE" != "uninstall" ]] && [[ "$INSTALL_MODE" != "update" ]]; then                    adduser "$new_user"

        core_post_install                    usermod -aG sudo "$new_user"

    fi                    log_success "User $new_user created and added to sudo group"

                    fi

    log_success "All operations completed!"            fi

            else

    # Show dry run note            log_info "Non-interactive mode: skipping user creation prompt"

    if [[ "$DRY_RUN" == "true" ]]; then        fi

        echo    else

        log_info "This was a DRY RUN - no changes were made"        # Set USER_HOME early to avoid empty variable issues

        log_info "Run without --dry-run to perform actual installation"        USER_HOME="$HOME"

    fi        

}        # Fallback if HOME is not set (rare edge case)

        if [[ -z "$USER_HOME" ]]; then

# ==============================================================================            USER_HOME="/home/$(whoami)"

# Script Execution            log_warning "HOME variable not set, using fallback: $USER_HOME"

# ==============================================================================        fi

        

# Parse command line arguments        # Check if user has sudo privileges

parse_arguments "$@"        log_info "Checking sudo privileges..."

        if ! sudo -n true 2>/dev/null; then

# Run main function            log_warning "Password-less sudo not configured"

main            log_info "Testing sudo access with password prompt..."

            

exit 0            if sudo true; then

                log_success "Sudo access confirmed"
            else
                log_error "This script requires sudo privileges. Please run with sudo or ensure your user is in the sudo group."
                
                # Offer alternatives
                echo
                log_info "Alternatives:"
                log_info "1. Run: sudo ./$(basename "$0")"
                log_info "2. Add user to sudo group: sudo usermod -aG sudo $(whoami)"
                log_info "3. Configure password-less sudo"
                
                read -p "Continue without sudo verification? (NOT RECOMMENDED) (y/n): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    exit 1
                fi
                log_warning "Proceeding without sudo verification - installation may fail"
            fi
        else
            log_success "Password-less sudo access confirmed"
        fi
    fi
    
    # Ensure USER_HOME directory exists
    mkdir -p "$USER_HOME" 2>/dev/null || {
        log_warning "Could not create USER_HOME directory: $USER_HOME"
        log_info "Using current directory as fallback"
        USER_HOME="$(pwd)"
    }
    
    log_info "Using home directory: $USER_HOME"
    return 0
}

# Check if ZSH is installed
check_zsh() {
    if command -v zsh &> /dev/null; then
        log_success "ZSH is already installed"
        return 0
    else
        log_info "ZSH is not installed"
        return 1
    fi
}

# Check if Oh My ZSH is installed
check_ohmyzsh() {
    if [ -d "$USER_HOME/.oh-my-zsh" ]; then
        log_success "Oh My ZSH is already installed"
        return 0
    else
        log_info "Oh My ZSH is not installed"
        return 1
    fi
}

# Install ZSH and prerequisites
install_zsh() {
    ((CURRENT_STEP++))
    print_step "$CURRENT_STEP" "$TOTAL_STEPS" "Installing ZSH and prerequisites"
    
    log_info "Installing ZSH and prerequisites..."
    
    # Update package list
    log_info "Updating package list..."
    retry_command 3 5 sudo apt update &
    show_spinner $! "Updating package repositories"
    
    # Install packages with version tracking
    local packages=(
        "zsh"
        "git"
        "fonts-font-awesome"
        "curl"
        "wget"
        "build-essential"
        "pkg-config"
        "libssl-dev"
        "python3-venv"
        "python3-pip"
        "snapd"
        "unzip"
        "jq"
        "tree"
        "htop"
        "neofetch"
    )
    
    local total_packages=${#packages[@]}
    local current_package=0
    
    for package in "${packages[@]}"; do
        ((current_package++))
        if ! is_package_installed "$package"; then
            log_info "Installing $package ($current_package/$total_packages)..."
            
            # Show progress for package installation
            draw_progress_bar "$current_package" "$total_packages" "Installing $package"
            
            sudo apt install -y "$package" &>/dev/null &
            show_spinner $! "Installing $package"
            
            log_success "$package installed"
        else
            draw_progress_bar "$current_package" "$total_packages" "$package already installed"
            log_warning "$package already installed"
        fi
    done
    
    echo # New line after progress bar
    
    # Verify ZSH installation
    if command_exists zsh; then
        local zsh_version=$(zsh --version | cut -d' ' -f2)
        log_success "ZSH $zsh_version installed successfully"
    else
        log_error "ZSH installation failed"
        exit 1
    fi
}

# Install Oh My ZSH
install_ohmyzsh() {
    print_step "$CURRENT_STEP" "$TOTAL_STEPS" "Installing Oh My ZSH"
    update_progress "Installing Oh My ZSH..."
    
    local ohmyzsh_dir="$USER_HOME/.oh-my-zsh"
    
    if [[ -d "$ohmyzsh_dir" ]]; then
        log_warning "Oh My ZSH already installed, updating..."
        cd "$ohmyzsh_dir"
        git pull origin master &>/dev/null &
        show_spinner $! "Updating Oh My ZSH"
        cd - > /dev/null
    else
        # Download and install Oh My ZSH
        export HOME="$USER_HOME"
        local install_script=$(mktemp)
        
        download_with_progress "https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "$install_script" "Oh My ZSH installer"
        
        if [[ -f "$install_script" ]]; then
            chmod +x "$install_script"
            
            RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$install_script" &>/dev/null &
            show_spinner $! "Installing Oh My ZSH"
            
            rm -f "$install_script"
            log_success "Oh My ZSH installed"
        else
            log_error "Failed to download Oh My ZSH installer"
            exit 1
        fi
    fi
}

# Install ZSH plugins
install_zsh_plugins() {
    print_step "$CURRENT_STEP" "$TOTAL_STEPS" "Installing ZSH plugins"
    update_progress "Installing ZSH plugins..."
    
    local plugins=(
        "zsh-autosuggestions:https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting:https://github.com/zsh-users/zsh-syntax-highlighting.git"
        "powerlevel10k:https://github.com/romkatv/powerlevel10k.git"
    )
    
    local total_plugins=${#plugins[@]}
    local current_plugin=0
    
    for plugin_info in "${plugins[@]}"; do
        ((current_plugin++))
        local plugin_name="${plugin_info%%:*}"
        local plugin_url="${plugin_info##*:}"
        local plugin_dir=""
        
        if [[ "$plugin_name" == "powerlevel10k" ]]; then
            plugin_dir="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
        else
            plugin_dir="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}/plugins/$plugin_name"
        fi
        
        draw_progress_bar "$current_plugin" "$total_plugins" "Installing $plugin_name"
        
        if [[ ! -d "$plugin_dir" ]]; then
            log_info "Installing $plugin_name..."
            
            git clone --depth=1 "$plugin_url" "$plugin_dir" &>/dev/null &
            show_spinner $! "Cloning $plugin_name repository"
            
            log_success "$plugin_name plugin installed"
        else
            log_warning "$plugin_name plugin already installed"
        fi
    done
    
    echo # New line after progress bar
}

# Configure ZSH
configure_zsh() {
    log_info "Configuring ZSH..."
    
    # Backup existing .zshrc if it exists
    if [ -f "$USER_HOME/.zshrc" ]; then
        cp "$USER_HOME/.zshrc" "$USER_HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing .zshrc"
    fi
    
    # Create new .zshrc with our configuration
    cat > "$USER_HOME/.zshrc" << EOF
# Path to your oh-my-zsh installation.
export ZSH="$USER_HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source \$ZSH/oh-my-zsh.sh

# Go environment
export PATH=\$PATH:/usr/local/go/bin
export PATH=\$PATH:\$(go env GOPATH)/bin

# Rust environment
export PATH=\$PATH:$USER_HOME/.cargo/bin

# Pipx environment
export PATH=\$PATH:$USER_HOME/.local/bin

# Tools directory
export PATH=\$PATH:$USER_HOME/tools

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
    
    log_success "ZSH configuration completed"
}

# Install Go
install_go() {
    print_step "$CURRENT_STEP" "$TOTAL_STEPS" "Installing Go programming language"
    
    local go_version="1.22.4"
    local go_url="https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
    
    if command_exists go; then
        local current_version=$(go version | awk '{print $3}' | sed 's/go//')
        log_success "Go $current_version is already installed"
        
        # Check if update is needed
        if [[ "$current_version" != "$go_version" ]]; then
            read -p "Update Go from $current_version to $go_version? (y/n): " -n 1 -r
            echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
        else
            return 0
        fi
    fi
    
    update_progress "Installing Go $go_version..."
    
    local temp_file=$(mktemp)
    
    # Download Go with progress
    download_with_progress "$go_url" "$temp_file" "Go $go_version"
    
    if [[ -f "$temp_file" ]]; then
        log_info "Extracting Go archive..."
        
        # Remove existing installation
        sudo rm -rf /usr/local/go &>/dev/null &
        show_spinner $! "Removing old Go installation"
        
        # Extract new installation
        sudo tar -C /usr/local -xzf "$temp_file" &>/dev/null &
        show_spinner $! "Extracting Go archive"
        
        rm -f "$temp_file"
        
        # Verify installation
        if /usr/local/go/bin/go version; then
            log_success "Go $go_version installed successfully"
        else
            log_error "Go installation verification failed"
            exit 1
        fi
    else
        log_error "Failed to download Go"
        exit 1
    fi
}

# Install Rust
install_rust() {
    if command_exists rustc; then
        local rust_version=$(rustc --version | awk '{print $2}')
        log_success "Rust $rust_version is already installed"
        
        # Update Rust
        read -p "Update Rust to latest version? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            export HOME="$USER_HOME"
            source "$USER_HOME/.cargo/env" 2>/dev/null || true
            rustup update
            log_success "Rust updated"
        fi
        return 0
    fi
    
    log_info "Installing Rust..."
    update_progress
    
    export HOME="$USER_HOME"
    
    # Download and install Rust
    local rust_installer=$(mktemp)
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$rust_installer"; then
        chmod +x "$rust_installer"
        "$rust_installer" -y --default-toolchain stable
        rm -f "$rust_installer"
        
        # Source Rust environment
        source "$USER_HOME/.cargo/env"
        
        # Verify installation
        if command_exists rustc; then
            local rust_version=$(rustc --version | awk '{print $2}')
            log_success "Rust $rust_version installed successfully"
        else
            log_error "Rust installation verification failed"
            exit 1
        fi
    else
        log_error "Failed to download Rust installer"
        rm -f "$rust_installer"
        exit 1
    fi
}

# Install Go tools
install_go_tools() {
    print_step "$CURRENT_STEP" "$TOTAL_STEPS" "Installing Go-based security tools"
    update_progress "Installing Go security tools..."
    
    # Ensure Go is in PATH
    export PATH=$PATH:/usr/local/go/bin
    
    # Array of Go tools to install
    declare -a go_tools=(
        "github.com/projectdiscovery/dnsx/cmd/dnsx@latest:DNS toolkit"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest:HTTP toolkit"
        "github.com/tomnomnom/unfurl@latest:URL analysis tool"
        "github.com/tomnomnom/waybackurls@latest:Wayback machine URLs"
        "github.com/lc/gau/v2/cmd/gau@latest:Get All URLs"
        "github.com/ffuf/ffuf/v2@latest:Fast web fuzzer"
        "github.com/OJ/gobuster/v3@latest:Directory/file brute forcer"
        "github.com/iangcarroll/cookiemonster/cmd/cookiemonster@latest:Cookie analysis"
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest:Vulnerability scanner"
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest:Subdomain discovery"
    )
    
    local total_tools=${#go_tools[@]}
    local current_tool=0
    
    for tool_info in "${go_tools[@]}"; do
        ((current_tool++))
        local tool="${tool_info%%:*}"
        local description="${tool_info##*:}"
        local tool_name=$(basename "$tool" | cut -d'@' -f1)
        
        draw_progress_bar "$current_tool" "$total_tools" "Installing $tool_name"
        
        log_info "Installing $tool_name ($description)..."
        
        if go install -v "$tool" &>/dev/null; then
            log_success "✅ $tool_name installed"
        else
            log_error "❌ Failed to install $tool_name"
        fi
    done
    
    echo # New line after progress bar
    log_success "Go tools installation completed"
}

# Install Python tools
install_python_tools() {
    log_info "Installing Python-based security tools..."
    
    # Create tools directory
    mkdir -p "$USER_HOME/tools"
    cd "$USER_HOME/tools"
    
    # SQLMap
    if [ ! -d "sqlmap" ]; then
        log_info "Installing SQLMap..."
        git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git
        log_success "SQLMap installed"
    else
        log_warning "SQLMap already installed"
    fi
    
    # Ghauri
    if [ ! -d "ghauri" ]; then
        log_info "Installing Ghauri..."
        git clone https://github.com/r0oth3x49/ghauri.git
        cd ghauri
        python3 -m venv ghaurienv
        source ghaurienv/bin/activate
        pip install --upgrade -r requirements.txt
        deactivate
        cd ..
        log_success "Ghauri installed"
    else
        log_warning "Ghauri already installed"
    fi
    
    # Recollapse
    if [ ! -d "recollapse" ]; then
        log_info "Installing Recollapse..."
        git clone https://github.com/0xacb/recollapse.git
        cd recollapse
        python3 -m venv recollapseEnv
        source recollapseEnv/bin/activate
        pip install --upgrade -r requirements.txt
        if [ -f "install.sh" ]; then
            ./install.sh
        fi
        deactivate
        cd ..
        log_success "Recollapse installed"
    else
        log_warning "Recollapse already installed"
    fi
    
    # Commix
    if [ ! -d "commix" ]; then
        log_info "Installing Commix..."
        git clone https://github.com/commixproject/commix.git
        log_success "Commix installed"
    else
        log_warning "Commix already installed"
    fi
    
    # SSTImap
    if [ ! -d "SSTImap" ]; then
        log_info "Installing SSTImap..."
        git clone https://github.com/vladko312/SSTImap.git
        cd SSTImap
        python3 -m venv sstimapEnv
        source sstimapEnv/bin/activate
        pip install --upgrade -r requirements.txt
        deactivate
        cd ..
        log_success "SSTImap installed"
    else
        log_warning "SSTImap already installed"
    fi
    
    # XSStrike
    if [ ! -d "XSStrike" ]; then
        log_info "Installing XSStrike..."
        git clone https://github.com/s0md3v/XSStrike
        cd XSStrike
        python3 -m venv xsstrikeEnv
        source xsstrikeEnv/bin/activate
        pip install --upgrade -r requirements.txt
        deactivate
        cd ..
        log_success "XSStrike installed"
    else
        log_warning "XSStrike already installed"
    fi
    
    cd "$USER_HOME"
}

# Install other tools
install_other_tools() {
    log_info "Installing other security tools..."
    
    # Check if we're in WSL2 and handle snap packages accordingly
    local is_wsl=false
    if grep -qi microsoft /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        is_wsl=true
    fi
    
    # Dalfox (via snap or alternative method for WSL2)
    if ! command -v dalfox &> /dev/null; then
        if [[ "$is_wsl" == true ]]; then
            log_warning "WSL2 detected - snap packages may not work properly"
            log_info "Attempting to install Dalfox via snap..."
            
            if ! snap list dalfox &> /dev/null; then
                if sudo snap install dalfox 2>/dev/null; then
                    log_success "Dalfox installed via snap"
                else
                    log_warning "Snap installation failed in WSL2 - this is expected"
                    log_info "Dalfox can be installed manually later or via alternative methods"
                fi
            else
                log_warning "Dalfox already installed via snap"
            fi
        else
            log_info "Installing Dalfox via snap..."
            if sudo snap install dalfox; then
                log_success "Dalfox installed"
            else
                log_error "Failed to install Dalfox via snap"
            fi
        fi
    else
        log_warning "Dalfox already installed"
    fi
    
    # x8 (Rust-based)
    if ! command -v x8 &> /dev/null; then
        log_info "Installing x8..."
        export HOME="$USER_HOME"
        if [[ -f "$USER_HOME/.cargo/env" ]]; then
            source "$USER_HOME/.cargo/env"
            if cargo install x8; then
                log_success "x8 installed"
            else
                log_error "Failed to install x8"
            fi
        else
            log_warning "Rust not found - skipping x8 installation"
        fi
    else
        log_warning "x8 already installed"
    fi
    
    # Pipx tools
    if ! command -v pipx &> /dev/null; then
        log_info "Installing pipx..."
        if sudo apt install -y pipx; then
            export HOME="$USER_HOME"
            pipx ensurepath
            log_success "pipx installed"
        else
            log_error "Failed to install pipx"
            return 1
        fi
    else
        log_warning "pipx already installed"
    fi
    
    # URO via pipx
    export HOME="$USER_HOME"
    if ! pipx list | grep -q uro 2>/dev/null; then
        log_info "Installing URO..."
        if pipx install uro; then
            log_success "URO installed"
        else
            log_error "Failed to install URO"
        fi
    else
        log_warning "URO already installed"
    fi
    
    # Arjun via pipx
    if ! pipx list | grep -q arjun 2>/dev/null; then
        log_info "Installing Arjun..."
        if pipx install arjun; then
            log_success "Arjun installed"
        else
            log_error "Failed to install Arjun"
        fi
    else
        log_warning "Arjun already installed"
    fi
    
    # Crunch
    if ! command -v crunch &> /dev/null; then
        log_info "Installing Crunch..."
        if sudo apt install -y crunch; then
            log_success "Crunch installed"
        else
            log_error "Failed to install Crunch"
        fi
    else
        log_warning "Crunch already installed"
    fi
}

# Install wordlists
install_wordlists() {
    log_info "Installing wordlists..."
    
    mkdir -p "$USER_HOME/wordlists"
    cd "$USER_HOME/wordlists"
    
    # 1. SecLists
    if [ ! -d "SecLists" ]; then
        log_info "Downloading SecLists..."
        wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip
        unzip -q SecList.zip
        mv SecLists-master SecLists
        rm -f SecList.zip
        log_success "SecLists installed."
    else
        log_warning "SecLists directory already exists."
    fi

    # 2. Bo0oM/fuzz.txt
    if [ ! -d "Bo0oM" ]; then
        log_info "Cloning Bo0oM/fuzz.txt..."
        git clone https://github.com/Bo0oM/fuzz.txt.git Bo0oM
        log_success "Bo0oM/fuzz.txt cloned."
    else
        log_warning "Bo0oM directory already exists."
    fi

    # 3. shayanrsh/wordlist
    if [ ! -d "wordlist" ]; then
        log_info "Cloning shayanrsh/wordlist..."
        git clone https://github.com/shayanrsh/wordlist.git
        log_success "shayanrsh/wordlist cloned."
    else
        log_warning "wordlist directory already exists."
    fi
    
    # 4. wallarm/jwt-secrets
    if [ ! -d "jwt-secrets" ]; then
        log_info "Cloning wallarm/jwt-secrets..."
        git clone https://github.com/wallarm/jwt-secrets.git
        log_success "wallarm/jwt-secrets cloned."
    else
        log_warning "jwt-secrets directory already exists."
    fi

    # 5. yassineaboukir gist
    if [ ! -f "yassineaboukir-gist/all.txt" ]; then
        log_info "Downloading yassineaboukir's Gist..."
        mkdir -p yassineaboukir-gist
        wget -O yassineaboukir-gist/all.txt https://gist.githubusercontent.com/yassineaboukir/8e12adefbd505ef704674ad6ad48743d/raw/ece456345963f460f76077979a83a992b2361623/all.txt
        log_success "yassineaboukir's Gist downloaded."
    else
        log_warning "yassineaboukir's Gist already exists."
    fi

    cd "$USER_HOME"
    log_success "Wordlists installation completed."
}


# Create helper scripts
create_helper_scripts() {
    log_info "Creating helper scripts..."
    
    mkdir -p "$USER_HOME/tools/scripts"
    
    # Create activation script for Python tools
    cat > "$USER_HOME/tools/scripts/activate_python_tools.sh" << EOF
#!/bin/bash
# Helper script to activate Python virtual environments

activate_ghauri() {
    source $USER_HOME/tools/ghauri/ghaurienv/bin/activate
    echo "Ghauri environment activated"
}

activate_recollapse() {
    source $USER_HOME/tools/recollapse/recollapseEnv/bin/activate
    echo "Recollapse environment activated"
}

activate_sstimap() {
    source $USER_HOME/tools/SSTImap/sstimapEnv/bin/activate
    echo "SSTImap environment activated"
}

activate_xsstrike() {
    source $USER_HOME/tools/XSStrike/xsstrikeEnv/bin/activate
    echo "XSStrike environment activated"
}

echo "Available functions:"
echo "  activate_ghauri"
echo "  activate_recollapse"
echo "  activate_sstimap"
echo "  activate_xsstrike"
EOF
    
    chmod +x "$USER_HOME/tools/scripts/activate_python_tools.sh"
    log_success "Helper scripts created"
}

# Configuration management
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log_info "Configuration loaded from $CONFIG_FILE"
    else
        log_info "No configuration file found, using defaults"
    fi
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# Security Tools Installation Configuration
# Generated on $(date)

# Installation preferences
SKIP_ZSH_INSTALL=${SKIP_ZSH_INSTALL:-false}
SKIP_GO_INSTALL=${SKIP_GO_INSTALL:-false}
SKIP_RUST_INSTALL=${SKIP_RUST_INSTALL:-false}
SKIP_PYTHON_TOOLS=${SKIP_PYTHON_TOOLS:-false}
SKIP_GO_TOOLS=${SKIP_GO_TOOLS:-false}
SKIP_WORDLISTS=${SKIP_WORDLISTS:-false}

# Paths
TOOLS_DIR="$USER_HOME/tools"
WORDLISTS_DIR="$USER_HOME/wordlists"
SCRIPTS_DIR="$USER_HOME/tools/scripts"

# Last installation date
LAST_INSTALL_DATE=$(date +%Y-%m-%d)
SCRIPT_VERSION="$SCRIPT_VERSION"
EOF
    log_success "Configuration saved to $CONFIG_FILE"
}

# Interactive menu system
show_menu() {
    clear
    
    # ASCII Art Header
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║    ███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗               ║
║    ██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝               ║
║    ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝                ║
║    ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝                 ║
║    ███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║                  ║
║    ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝                  ║
║                                                                                  ║
║         ████████╗ ██████╗  ██████╗ ██╗     ███████╗                             ║
║         ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝                             ║
║            ██║   ██║   ██║██║   ██║██║     ███████╗                             ║
║            ██║   ██║   ██║██║   ██║██║     ╚════██║                             ║
║            ██║   ╚██████╔╝╚██████╔╝███████╗███████║                             ║
║            ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝                             ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Version and system info
    echo -e "${PURPLE}┌─ System Information ─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│ Version: ${SCRIPT_VERSION}$(printf "%*s" $((15-${#SCRIPT_VERSION})) "")OS: $(lsb_release -d | cut -f2 | cut -c1-25)$(printf "%*s" $((30)) "")│${NC}"
    echo -e "${PURPLE}│ User: $(whoami)$(printf "%*s" $((20-${#USER})) "")Architecture: $(uname -m)$(printf "%*s" $((20)) "")│${NC}"
    echo -e "${PURPLE}└───────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    # Menu options with fancy styling
    echo -e "${YELLOW}╭─ Installation Options ─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${YELLOW}│                                                                               │${NC}"
    echo -e "${GREEN}│  1) ${NC}🚀 Full installation (recommended)$(printf "%*s" $((42)) "")${YELLOW}│${NC}"
    echo -e "${BLUE}│  2) ${NC}🐚 ZSH + Oh My ZSH only$(printf "%*s" $((49)) "")${YELLOW}│${NC}"
    echo -e "${RED}│  3) ${NC}🔧 Security tools only$(printf "%*s" $((51)) "")${YELLOW}│${NC}"
    echo -e "${PURPLE}│  4) ${NC}⚡ Go tools only$(printf "%*s" $((58)) "")${YELLOW}│${NC}"
    echo -e "${CYAN}│  5) ${NC}🐍 Python tools only$(printf "%*s" $((54)) "")${YELLOW}│${NC}"
    echo -e "${GREEN}│  6) ${NC}📚 Wordlists only$(printf "%*s" $((57)) "")${YELLOW}│${NC}"
    echo -e "${BLUE}│  7) ${NC}⚙️  Custom installation$(printf "%*s" $((49)) "")${YELLOW}│${NC}"
    echo -e "${PURPLE}│  8) ${NC}🔄 Update existing tools$(printf "%*s" $((46)) "")${YELLOW}│${NC}"
    echo -e "${RED}│  9) ${NC}🗑️  Uninstall tools$(printf "%*s" $((53)) "")${YELLOW}│${NC}"
    echo -e "${YELLOW}│  0) ${NC}❌ Exit$(printf "%*s" $((67)) "")${YELLOW}│${NC}"
    echo -e "${YELLOW}│                                                                               │${NC}"
    echo -e "${YELLOW}╰─────────────────────────────────────────────────────────────────────────────────╯${NC}"
    echo
    echo -e "${CYAN}💡 Tip: Use arrow keys navigation in future versions!${NC}"
    echo
}

get_user_choice() {
    while true; do
        show_menu
        read -p "Enter your choice [0-9]: " choice
        
        case $choice in
            1) run_full_installation; break ;;
            2) install_zsh_only; break ;;
            3) install_security_tools_only; break ;;
            4) install_go_tools_only; break ;;
            5) install_python_tools_only; break ;;
            6) install_wordlists_only; break ;;
            7) custom_installation; break ;;
            8) update_tools; break ;;
            9) uninstall_tools; break ;;
            10) log_info "Exiting..."; exit 0 ;;
            *) log_error "Invalid choice. Please try again." ;;
        esac
    done
}

# Installation modes
run_full_installation() {
    TOTAL_STEPS=12
    CURRENT_STEP=0
    
    print_section_header "FULL INSTALLATION STARTING" "$GREEN"
    log_info "Starting comprehensive security tools installation..."
    
    # Installation steps with visual progress
    install_zsh
    install_ohmyzsh
    install_zsh_plugins
    configure_zsh
    install_go
    install_rust
    install_go_tools
    install_python_tools
    install_other_tools
    install_wordlists
    create_helper_scripts
    post_installation_setup
    
    # Final completion animation
    echo -e "\n${GREEN}"
    for i in {1..3}; do
        echo -ne "🎉 Installation Complete! "
        sleep 0.5
        echo -ne "\r                                    \r"
        sleep 0.5
    done
    echo -e "🎉 Installation Complete! 🎉${NC}\n"
}

install_zsh_only() {
    TOTAL_STEPS=4
    CURRENT_STEP=0
    
    install_zsh
    install_ohmyzsh
    install_zsh_plugins
    configure_zsh
}

install_security_tools_only() {
    TOTAL_STEPS=5
    CURRENT_STEP=0
    
    install_go
    install_rust
    install_go_tools
    install_python_tools
    install_other_tools
}

install_go_tools_only() {
    TOTAL_STEPS=1
    CURRENT_STEP=0
    
    install_go_tools
}

install_python_tools_only() {
    TOTAL_STEPS=1
    CURRENT_STEP=0
    
    install_python_tools
}

install_wordlists_only() {
    TOTAL_STEPS=1
    CURRENT_STEP=0
    
    install_wordlists
}

custom_installation() {
    log_info "Custom installation mode"
    echo "Available components:"
    echo "1. ZSH + Oh My ZSH"
    echo "2. Go programming language"
    echo "3. Rust programming language"
    echo "4. Go security tools"
    echo "5. Python security tools"
    echo "6. Other security tools"
    echo "7. Wordlists"
    echo
    read -p "Enter component numbers separated by spaces (e.g., 1 4 5): " -a components
    
    TOTAL_STEPS=${#components[@]}
    CURRENT_STEP=0
    
    for component in "${components[@]}"; do
        case $component in
            1) install_zsh; install_ohmyzsh; install_zsh_plugins; configure_zsh ;;
            2) install_go ;;
            3) install_rust ;;
            4) install_go_tools ;;
            5) install_python_tools ;;
            6) install_other_tools ;;
            7) install_wordlists ;;
            *) log_warning "Unknown component: $component" ;;
        esac
    done
}

# Tool management functions
update_tools() {
    log_info "Updating installed tools..."
    
    # Update Go tools
    if command_exists go; then
        log_info "Updating Go tools..."
        export PATH=$PATH:/usr/local/go/bin
        go install -a -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
        go install -a -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
        # Add other Go tools as needed
    fi
    
    # Update Python tools
    if [[ -d "$USER_HOME/tools" ]]; then
        for tool_dir in "$USER_HOME/tools"/*; do
            if [[ -d "$tool_dir/.git" ]]; then
                log_info "Updating $(basename "$tool_dir")..."
                cd "$tool_dir"
                git pull origin main || git pull origin master || log_warning "Failed to update $(basename "$tool_dir")"
                cd - > /dev/null
            fi
        done
    fi
    
    log_success "Tools update completed"
}

uninstall_tools() {
    log_warning "This will remove all installed security tools!"
    read -p "Are you sure? (type 'yes' to confirm): " confirmation
    
    if [[ "$confirmation" == "yes" ]]; then
        log_info "Removing tools directory..."
        rm -rf "$USER_HOME/tools"
        rm -rf "$USER_HOME/wordlists"
        rm -f "$CONFIG_FILE"
        log_success "Tools uninstalled"
    else
        log_info "Uninstallation cancelled"
    fi
}

# Post-installation setup
post_installation_setup() {
    log_info "Running post-installation setup..."
    update_progress
    
    # Create desktop shortcuts
    create_desktop_shortcuts
    
    # Set up shell aliases
    setup_aliases
    
    # Initialize tool databases
    initialize_tool_databases
    
    log_success "Post-installation setup completed"
}

create_desktop_shortcuts() {
    local desktop_dir="$USER_HOME/Desktop"
    mkdir -p "$desktop_dir"
    
    # Create tools launcher script
    cat > "$desktop_dir/security-tools.sh" << 'EOF'
#!/bin/bash
# Security Tools Launcher
source ~/.zshrc
exec zsh
EOF
    chmod +x "$desktop_dir/security-tools.sh"
}

setup_aliases() {
    local aliases_file="$USER_HOME/.security_aliases"
    
    cat > "$aliases_file" << 'EOF'
# Security Tools Aliases
alias nuclei-update="nuclei -update-templates"
alias subfinder-help="subfinder -h"
alias httpx-help="httpx -h"
alias sqlmap-wizard="python3 ~/tools/sqlmap/sqlmap.py --wizard"
alias wordlists="cd ~/wordlists && ls -la"
alias tools="cd ~/tools && ls -la"
EOF
    
    # Add to .zshrc if not already present
    if ! grep -q "source.*security_aliases" "$USER_HOME/.zshrc"; then
        echo "source $aliases_file" >> "$USER_HOME/.zshrc"
    fi
}

initialize_tool_databases() {
    log_info "Initializing tool databases..."
    
    # Update Nuclei templates
    if command_exists nuclei; then
        nuclei -update-templates || log_warning "Failed to update Nuclei templates"
    fi
    
    # Initialize other databases as needed
}

# Version checking and updates
check_script_updates() {
    log_info "Checking for script updates..."
    
    local latest_version=$(curl -s "https://api.github.com/repos/yourusername/security-tools-installer/releases/latest" | jq -r '.tag_name' 2>/dev/null || echo "unknown")
    
    if [[ "$latest_version" != "unknown" && "$latest_version" != "v$SCRIPT_VERSION" ]]; then
        log_warning "New version available: $latest_version (current: v$SCRIPT_VERSION)"
        read -p "Download and install update? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_script
        fi
    else
        log_success "Script is up to date"
    fi
}

update_script() {
    log_info "Updating script..."
    # Implementation for self-update
    log_warning "Self-update feature not implemented yet"
}

# Command line argument parsing
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "Security Tools Installer v$SCRIPT_VERSION"
                exit 0
                ;;
            --full)
                MODE="full"
                shift
                ;;
            --zsh-only)
                MODE="zsh"
                shift
                ;;
            --tools-only)
                MODE="tools"
                shift
                ;;
            --update)
                MODE="update"
                shift
                ;;
            --uninstall)
                MODE="uninstall"
                shift
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --no-interactive)
                INTERACTIVE=false
                shift
                ;;
            --config=*)
                CONFIG_FILE="${1#*=}"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
Security Tools Installer v$SCRIPT_VERSION

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show version information
    --full                  Run full installation (default)
    --zsh-only             Install ZSH and Oh My ZSH only
    --tools-only           Install security tools only
    --update               Update existing tools
    --uninstall            Remove all installed tools
    --debug                Enable debug logging
    --no-interactive       Run in non-interactive mode
    --config=FILE          Use custom configuration file

EXAMPLES:
    $0                     # Interactive mode
    $0 --full             # Full installation
    $0 --zsh-only         # ZSH setup only
    $0 --update           # Update existing tools
    $0 --debug --full     # Full installation with debug logging

For more information, visit: https://github.com/yourusername/security-tools-installer
EOF
}

# Main function
main() {
    # Initialize variables
    MODE=""
    DEBUG=${DEBUG:-false}
    INTERACTIVE=${INTERACTIVE:-true}
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Set USER_HOME early to prevent empty variable issues
    if [[ $EUID -eq 0 ]]; then
        USER_HOME="/root"
    else
        USER_HOME="${HOME:-/home/$(whoami)}"
    fi
    
    # Ensure USER_HOME exists
    mkdir -p "$USER_HOME" 2>/dev/null || USER_HOME="$(pwd)"
    
    # Initialize logging
    echo "Security Tools Installer v$SCRIPT_VERSION" > "$LOG_FILE"
    echo "Started at: $(date)" >> "$LOG_FILE"
    echo "User: $(whoami)" >> "$LOG_FILE"
    echo "Home: $USER_HOME" >> "$LOG_FILE"
    echo "=====================================" >> "$LOG_FILE"
    
    log_info "Security Tools Installer v$SCRIPT_VERSION starting..."
    
    # Load configuration
    load_config
    
    # System checks (with early USER_HOME set)
    check_system_requirements
    check_root
    get_system_info
    
    # Check for script updates (only in interactive mode)
    if [[ "$INTERACTIVE" == "true" ]]; then
        log_info "Skipping script update check to avoid API rate limits"
        # check_script_updates
    fi
    
    # Run based on mode
    if [[ -n "$MODE" ]]; then
        case "$MODE" in
            "full") run_full_installation ;;
            "zsh") install_zsh_only ;;
            "tools") install_security_tools_only ;;
            "update") update_tools ;;
            "uninstall") uninstall_tools ;;
        esac
    elif [[ "$INTERACTIVE" == "true" ]]; then
        get_user_choice
    else
        run_full_installation
    fi
    
    # Save configuration
    save_config
    
    # Final messages
    clear
    echo -e "\n${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                  ║
║    ███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗██╗                 ║
║    ██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝██║                 ║
║    ███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗██║                 ║
║    ╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║╚═╝                 ║
║    ███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║██╗                 ║
║    ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝╚═╝                 ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Animated success message
    local success_msgs=(
        "✅ All components installed successfully!"
        "🔧 Security tools configured and ready!"
        "📚 Wordlists downloaded and organized!"
        "🚀 Your security environment is ready!"
    )
    
    for msg in "${success_msgs[@]}"; do
        echo -e "${GREEN}$msg${NC}"
        sleep 0.5
    done
    
    echo
    
    # Installation summary box
    echo -e "${CYAN}╭─ Installation Summary ─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│                                                                               │${NC}"
    echo -e "${CYAN}│ 📁 Log file: ${LOG_FILE}$(printf "%*s" $((50-${#LOG_FILE})) "")│${NC}"
    echo -e "${CYAN}│ ⚙️  Config file: ${CONFIG_FILE}$(printf "%*s" $((45-${#CONFIG_FILE})) "")│${NC}"
    echo -e "${CYAN}│ 🛠️  Tools location: ~/tools/$(printf "%*s" $((57)) "")│${NC}"
    echo -e "${CYAN}│ 📚 Wordlists location: ~/wordlists/$(printf "%*s" $((47)) "")│${NC}"
    echo -e "${CYAN}│                                                                               │${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────────────────────────────────────╯${NC}"
    echo
    
    # Next steps with fancy formatting
    echo -e "${YELLOW}╭─ Next Steps ───────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${YELLOW}│                                                                               │${NC}"
    echo -e "${YELLOW}│ 1. ${NC}🔄 Run 'source ~/.zshrc' or restart your terminal$(printf "%*s" $((34)) "")${YELLOW}│${NC}"
    echo -e "${YELLOW}│ 2. ${NC}🎨 Configure Powerlevel10k theme: p10k configure$(printf "%*s" $((32)) "")${YELLOW}│${NC}"
    echo -e "${YELLOW}│ 3. ${NC}🐚 Change default shell: chsh -s /bin/zsh$(printf "%*s" $((38)) "")${YELLOW}│${NC}"
    echo -e "${YELLOW}│ 4. ${NC}🔍 Check tools: ls -la ~/tools/$(printf "%*s" $((48)) "")${YELLOW}│${NC}"
    echo -e "${YELLOW}│ 5. ${NC}📖 Check wordlists: ls -la ~/wordlists/$(printf "%*s" $((40)) "")${YELLOW}│${NC}"
    echo -e "${YELLOW}│                                                                               │${NC}"
    echo -e "${YELLOW}╰─────────────────────────────────────────────────────────────────────────────────╯${NC}"
    echo
    
    # Additional info
    echo -e "${PURPLE}💡 Additional Information:${NC}"
    echo -e "${PURPLE}   • Security aliases: ~/.security_aliases${NC}"
    echo -e "${PURPLE}   • Python environments: ~/tools/scripts/${NC}"
    echo -e "${PURPLE}   • Documentation: Check each tool's README${NC}"
    echo
    
    # Cool exit animation
    echo -e "${CYAN}Thank you for using Security Tools Installer! 🙏${NC}"
    
    local dots=""
    for i in {1..5}; do
        dots+="."
        echo -ne "\r${BLUE}Finalizing$dots${NC}"
        sleep 0.3
    done
    echo -e "\n${GREEN}✨ All done! Happy hacking! ✨${NC}\n"
    
    # Display installation summary
    if [[ "$DEBUG" == "true" ]]; then
        log_debug "Installation summary saved to $LOG_FILE"
    fi
}

# Run main function
main "$@"