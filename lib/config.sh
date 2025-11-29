#!/bin/bash
# ==============================================================================
# Bug Bounty Toolkit - Configuration Module
# ==============================================================================
# Version: 4.0.0
# Description: Central configuration management with environment detection
# License: MIT
# ==============================================================================

# Prevent multiple sourcing
[[ -n "${_CONFIG_LOADED:-}" ]] && return 0
readonly _CONFIG_LOADED=1

# ==============================================================================
# Script Metadata
# ==============================================================================
readonly SCRIPT_VERSION="4.0.0"
readonly SCRIPT_NAME="Bug Bounty Toolkit"
readonly SCRIPT_AUTHOR="Security Community"
readonly SCRIPT_REPO="https://github.com/shayanrsh/bug-bounty-toolkit-install-script"

# ==============================================================================
# Directory Configuration
# ==============================================================================
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/lib"
readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly PLUGINS_DIR="${SCRIPT_DIR}/plugins"

# User directories (XDG compliant with fallback)
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/security-tools"
readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/security-tools"
readonly CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/security-tools"
readonly STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/security-tools"

# Legacy paths (for backward compatibility)
readonly LEGACY_DIR="${HOME}/.security-tools"

# Runtime directories
readonly LOG_DIR="${STATE_HOME}/logs"
readonly STATE_DIR="${STATE_HOME}/state"
readonly STEP_STATE_DIR="${STATE_DIR}/steps"
readonly MANIFEST_FILE="${DATA_HOME}/manifest.json"
readonly CONFIG_FILE="${CONFIG_HOME}/config"
readonly LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"
readonly CACHE_DIR="${CACHE_HOME}"

# Installation targets
readonly TOOLS_DIR="${TOOLS_DIR:-$HOME/tools}"
readonly WORDLISTS_DIR="${WORDLISTS_DIR:-$HOME/wordlists}"
readonly SCRIPTS_DIR="${SCRIPTS_DIR:-$TOOLS_DIR/scripts}"
readonly CUSTOM_BIN_DIR="${CUSTOM_BIN_DIR:-$HOME/.local/bin}"

# System paths
readonly INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
readonly GO_INSTALL_DIR="${GO_INSTALL_DIR:-${INSTALL_PREFIX}/go}"
readonly GO_VERSION_DIR="${GO_VERSION_DIR:-${INSTALL_PREFIX}}"
readonly USER_TOOLS_DIR="${USER_TOOLS_DIR:-${TOOLS_DIR}}"
readonly USER_WORDLISTS_DIR="${USER_WORDLISTS_DIR:-${WORDLISTS_DIR}}"
readonly USER_SCRIPTS_DIR="${USER_SCRIPTS_DIR:-${SCRIPTS_DIR}}"

# ==============================================================================
# Terminal Colors & Formatting  
# ==============================================================================
_setup_colors() {
    if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]] || [[ "${TERM:-}" == "dumb" ]]; then
        export COLORS_ENABLED=false
        export RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN=''
        export WHITE='' GRAY='' ORANGE='' PINK='' BOLD='' DIM='' 
        export ITALIC='' UNDERLINE='' NC=''
    else
        export COLORS_ENABLED=true
        export RED=$'\033[0;31m'
        export GREEN=$'\033[0;32m'
        export YELLOW=$'\033[1;33m'
        export BLUE=$'\033[0;34m'
        export PURPLE=$'\033[0;35m'
        export CYAN=$'\033[0;36m'
        export WHITE=$'\033[1;37m'
        export GRAY=$'\033[0;90m'
        export ORANGE=$'\033[0;33m'
        export PINK=$'\033[0;95m'
        export BOLD=$'\033[1m'
        export DIM=$'\033[2m'
        export ITALIC=$'\033[3m'
        export UNDERLINE=$'\033[4m'
        export NC=$'\033[0m'
        export BG_RED=$'\033[41m'
        export BG_GREEN=$'\033[42m'
        export BG_BLUE=$'\033[44m'
    fi
}
_setup_colors

# ==============================================================================
# Unicode Icons & Symbols
# ==============================================================================
_supports_unicode() {
    [[ "${LANG:-}" =~ [Uu][Tt][Ff]-?8 ]] || [[ "${LC_ALL:-}" =~ [Uu][Tt][Ff]-?8 ]]
}

if _supports_unicode; then
    readonly ICON_SUCCESS="✓"
    readonly ICON_ERROR="✗"
    readonly ICON_WARNING="⚠"
    readonly ICON_INFO="ℹ"
    readonly ICON_DEBUG="⚙"
    readonly ICON_DOWNLOAD="⬇"
    readonly ICON_INSTALL="📦"
    readonly ICON_UPDATE="🔄"
    readonly ICON_ROCKET="🚀"
    readonly ICON_ARROW="→"
    readonly ICON_BULLET="•"
    readonly ICON_STAR="★"
    readonly ICON_CLOCK="⏱"
    readonly ICON_LOCK="🔒"
    readonly ICON_FOLDER="📁"
    readonly ICON_GEAR="⚙"
    readonly ICON_WRENCH="🔧"
    readonly ICON_LIGHTNING="⚡"
    readonly SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    readonly PROGRESS_FILLED="█"
    readonly PROGRESS_EMPTY="░"
    readonly PROGRESS_PARTIAL="▒"
    readonly BOX_TL="╭" BOX_TR="╮" BOX_BL="╰" BOX_BR="╯"
    readonly BOX_H="─" BOX_V="│" BOX_CROSS="┼"
    readonly BOX_LT="├" BOX_RT="┤" BOX_TB="┬" BOX_BT="┴"
else
    readonly ICON_SUCCESS="[OK]"
    readonly ICON_ERROR="[ERR]"
    readonly ICON_WARNING="[WARN]"
    readonly ICON_INFO="[INFO]"
    readonly ICON_DEBUG="[DBG]"
    readonly ICON_DOWNLOAD="[DL]"
    readonly ICON_INSTALL="[PKG]"
    readonly ICON_UPDATE="[UPD]"
    readonly ICON_ROCKET=">>>"
    readonly ICON_ARROW="->"
    readonly ICON_BULLET="*"
    readonly ICON_STAR="*"
    readonly ICON_CLOCK="[TIME]"
    readonly ICON_LOCK="[LOCK]"
    readonly ICON_FOLDER="[DIR]"
    readonly ICON_GEAR="[CFG]"
    readonly ICON_WRENCH="[FIX]"
    readonly ICON_LIGHTNING="[FAST]"
    readonly SPINNER_CHARS="|/-\\"
    readonly PROGRESS_FILLED="#"
    readonly PROGRESS_EMPTY="-"
    readonly PROGRESS_PARTIAL="="
    readonly BOX_TL="+" BOX_TR="+" BOX_BL="+" BOX_BR="+"
    readonly BOX_H="-" BOX_V="|" BOX_CROSS="+"
    readonly BOX_LT="+" BOX_RT="+" BOX_TB="+" BOX_BT="+"
fi

# ==============================================================================
# System Requirements & Limits
# ==============================================================================
readonly MIN_DISK_SPACE_GB=5
readonly MIN_MEMORY_GB=1
readonly MIN_BASH_VERSION=4
readonly REQUIRED_COMMANDS=("curl" "wget" "git" "grep" "awk" "sed")

# Network configuration
readonly NETWORK_TEST_URLS=("google.com" "github.com" "1.1.1.1")
readonly NETWORK_TIMEOUT=10
readonly RETRY_MAX_ATTEMPTS=3
readonly RETRY_DELAY=5
readonly RETRY_BACKOFF_MULTIPLIER=2
readonly DOWNLOAD_TIMEOUT=300
readonly GIT_CLONE_TIMEOUT=600

# APT configuration
readonly APT_LOCK_TIMEOUT=300
readonly APT_LOCK_CHECK_INTERVAL=2

# Cache settings
readonly CACHE_MAX_AGE_HOURS=24

# Parallel processing
readonly DEFAULT_PARALLEL_JOBS=4
readonly MAX_PARALLEL_JOBS=8

# Progress bar
readonly PROGRESS_BAR_WIDTH=50
PROGRESS_BOARD_ENABLED=${PROGRESS_BOARD_ENABLED:-true}
readonly PROGRESS_DEFAULT_TOOL_WEIGHT=1

# ==============================================================================
# Global State Variables
# ==============================================================================
declare -g DEBUG="${DEBUG:-false}"
declare -g VERBOSE="${VERBOSE:-false}"
declare -g DRY_RUN="${DRY_RUN:-false}"
declare -g INTERACTIVE="${INTERACTIVE:-true}"
declare -g FORCE="${FORCE:-false}"
declare -g FORCE_INSTALL="${FORCE_INSTALL:-false}"
declare -g SKIP_CHECKS="${SKIP_CHECKS:-false}"
declare -g QUIET="${QUIET:-false}"
declare -g INSTALL_MODE=""
declare -g PROFILE=""
declare -g RESUME_MODE="false"
declare -g RESUME_TARGET=""
declare -g ALLOW_ROOT="false"
declare -g GO_TOOLS_PARALLEL="${GO_TOOLS_PARALLEL:-true}"
declare -g PARALLEL_JOBS="${PARALLEL_JOBS:-$DEFAULT_PARALLEL_JOBS}"
declare -g LOG_LEVEL="${LOG_LEVEL:-INFO}"
declare -g APT_UPDATED=false

# Progress board state
declare -g PROGRESS_BOARD_ACTIVE=false
declare -g PROGRESS_BOARD_MODE=""
declare -g PROGRESS_BOARD_TOTAL_WEIGHT=0
declare -g PROGRESS_BOARD_FINISHED_WEIGHT=0
declare -g PROGRESS_BOARD_LAST_LINES=0
declare -g PROGRESS_BOARD_FINISHED_COUNT=0
declare -g PROGRESS_BOARD_SUCCESS_COUNT=0
declare -g PROGRESS_BOARD_FAILED_COUNT=0
declare -g PROGRESS_BOARD_SKIPPED_COUNT=0
declare -g PROGRESS_BOARD_DRY_RUN=false
declare -g PROGRESS_BOARD_CAN_REWRITE=true

# Tracking arrays
declare -gA PACKAGE_CACHE=()
declare -ga ROLLBACK_STACK=()
declare -gA ROLLBACK_TOOLS=()
declare -ga TEMP_FILES=()
declare -ga TEMP_DIRS=()
declare -ga INSTALLED_TOOLS=()

# Progress board tracking
declare -ga PROGRESS_BOARD_ORDER=()
declare -gA PROGRESS_BOARD_LABELS=()
declare -gA PROGRESS_BOARD_STATUS=()
declare -gA PROGRESS_BOARD_PERCENT=()
declare -gA PROGRESS_BOARD_MESSAGES=()
declare -gA PROGRESS_BOARD_WEIGHTS=()
declare -gA PROGRESS_BOARD_FINALIZED=()

# Tool weights for progress estimation
declare -gA TOOL_WEIGHTS=(
    ["tool_install_zsh"]=2
    ["tool_install_go"]=3
    ["tool_install_rust"]=2
    ["tool_install_go_tools"]=5
    ["tool_install_python_tools"]=5
    ["tool_install_rust_tools"]=2
    ["tool_install_apt_tools"]=3
    ["tool_install_snap_tools"]=1
    ["tool_install_pipx_tools"]=2
    ["tool_install_wordlists"]=6
    ["tool_create_helper_scripts"]=1
)

# ==============================================================================
# ZSH Configuration
# ==============================================================================
declare -gA ZSH_PACKAGES=(
    ["zsh"]="zsh"
    ["git"]="git"
    ["fonts"]="fonts-font-awesome"
    ["curl"]="curl"
    ["wget"]="wget"
)

declare -gA ZSH_PLUGINS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    ["powerlevel10k"]="https://github.com/romkatv/powerlevel10k.git"
)

# ==============================================================================
# Programming Languages
# ==============================================================================
declare -gA LANGUAGES=(
    ["go"]="latest|https://go.dev/dl/go{VERSION}.linux-amd64.tar.gz"
    ["rust"]="stable|https://sh.rustup.rs"
    ["python3"]="system|apt"
)

# ==============================================================================
# Go-based Security Tools
# ==============================================================================
declare -gA GO_TOOLS=(
    ["nuclei"]="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest|Vulnerability scanner based on templates"
    ["subfinder"]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest|Subdomain discovery tool"
    ["httpx"]="github.com/projectdiscovery/httpx/cmd/httpx@latest|Fast HTTP probe with rich features"
    ["dnsx"]="github.com/projectdiscovery/dnsx/cmd/dnsx@latest|DNS toolkit and resolver"
    ["katana"]="github.com/projectdiscovery/katana/cmd/katana@latest|Web crawling framework"
    ["naabu"]="github.com/projectdiscovery/naabu/v2/cmd/naabu@latest|Fast port scanner"
    ["ffuf"]="github.com/ffuf/ffuf/v2@latest|Fast web fuzzer written in Go"
    ["gobuster"]="github.com/OJ/gobuster/v3@latest|Directory/file and DNS busting tool"
    ["gau"]="github.com/lc/gau/v2/cmd/gau@latest|Get All URLs from various sources"
    ["waybackurls"]="github.com/tomnomnom/waybackurls@latest|Fetch URLs from Wayback Machine"
    ["unfurl"]="github.com/tomnomnom/unfurl@latest|URL parsing and analysis tool"
    ["cookiemonster"]="github.com/iangcarroll/cookiemonster/cmd/cookiemonster@latest|Cookie analysis and manipulation"
)

# ==============================================================================
# Python-based Security Tools
# ==============================================================================
declare -gA PYTHON_TOOLS=(
    ["sqlmap"]="git|https://github.com/sqlmapproject/sqlmap.git|SQL injection tool"
    ["ghauri"]="git|https://github.com/r0oth3x49/ghauri.git|Advanced SQL injection tool|requirements.txt"
    ["recollapse"]="git|https://github.com/0xacb/recollapse.git|Regex-based attack pattern generator|requirements.txt|install.sh"
    ["commix"]="git|https://github.com/commixproject/commix.git|Command injection exploitation tool"
    ["sstimap"]="git|https://github.com/vladko312/SSTImap.git|SSTI detection and exploitation|requirements.txt"
    ["xsstrike"]="git|https://github.com/s0md3v/XSStrike.git|XSS detection suite|requirements.txt"
)

# ==============================================================================
# Rust-based Tools
# ==============================================================================
declare -gA RUST_TOOLS=(
    ["x8"]="cargo|x8|Hidden parameter discovery tool"
)

# ==============================================================================
# APT Packages
# ==============================================================================
declare -gA APT_TOOLS=(
    ["build-essential"]="build-essential|Development tools and libraries"
    ["pkg-config"]="pkg-config|Package configuration helper"
    ["libssl-dev"]="libssl-dev|SSL development libraries"
    ["libpcap-dev"]="libpcap-dev|Packet capture development library"
    ["python3-venv"]="python3-venv|Python virtual environment support"
    ["python3-pip"]="python3-pip|Python package installer"
    ["snapd"]="snapd|Snap package manager"
    ["unzip"]="unzip|Archive extraction tool"
    ["jq"]="jq|JSON processor"
    ["tree"]="tree|Directory tree viewer"
    ["htop"]="htop|Interactive process viewer"
    ["neofetch"]="neofetch|System information tool"
    ["crunch"]="crunch|Wordlist generator"
)

# ==============================================================================
# Snap Packages
# ==============================================================================
declare -gA SNAP_TOOLS=(
    ["dalfox"]="dalfox|XSS parameter analysis tool"
)

# ==============================================================================
# Pipx Tools
# ==============================================================================
declare -gA PIPX_TOOLS=(
    ["uro"]="uro|URL filtering and deduplication"
    ["arjun"]="arjun|HTTP parameter discovery"
)

# ==============================================================================
# Wordlists
# ==============================================================================
declare -gA WORDLISTS=(
    ["seclists"]="https://github.com/danielmiessler/SecLists/archive/master.zip|SecLists-master|SecLists"
    ["bo0om"]="https://github.com/Bo0oM/fuzz.txt.git|git|Bo0oM"
    ["shayanrsh"]="https://github.com/shayanrsh/wordlist.git|git|wordlist"
    ["jwt-secrets"]="https://github.com/wallarm/jwt-secrets.git|git|jwt-secrets"
    ["yassineaboukir"]="https://gist.githubusercontent.com/yassineaboukir/8e12adefbd505ef704674ad6ad48743d/raw/all.txt|file|yassineaboukir-gist/all.txt"
)

# ==============================================================================
# Tool Dependencies
# ==============================================================================
declare -gA TOOL_DEPENDENCIES=(
    ["go_tools"]="go"
    ["rust_tools"]="rust"
    ["python_tools"]="python3"
    ["pipx_tools"]="python3-pip"
)

# ==============================================================================
# Tool Categories
# ==============================================================================
readonly TOOL_CATEGORIES=("zsh" "languages" "go_tools" "python_tools" "rust_tools" "other_tools" "wordlists")

# ==============================================================================
# Installation Profiles
# ==============================================================================
declare -gA PROFILES=(
    ["minimal"]="zsh|go|nuclei|subfinder|httpx"
    ["full"]="all"
    ["pentest"]="zsh|go|python_tools|go_tools|wordlists"
    ["developer"]="zsh|go|rust|build-essential"
    ["recon"]="go|nuclei|subfinder|httpx|katana|gau|waybackurls"
)

# ==============================================================================
# Configuration Functions
# ==============================================================================

# Load configuration from user config file
config_load_user_config() {
    local user_config="${HOME}/.security-tools.conf"
    
    if [[ ! -f "$user_config" ]]; then
        return 0
    fi
    
    log_info "Loading user configuration from $user_config"
    
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        case "$key" in
            SKIP_ZSH_INSTALL|SKIP_GO_INSTALL|SKIP_RUST_INSTALL|SKIP_PYTHON_INSTALL)
                declare -g "$key=$value"
                log_debug "Config: $key=$value"
                ;;
            CUSTOM_TOOLS_DIR|CUSTOM_WORDLISTS_DIR|CUSTOM_SCRIPTS_DIR)
                declare -g "$key=$value"
                log_debug "Config: $key=$value"
                ;;
            GO_TOOLS_PARALLEL|PARALLEL_JOBS)
                declare -g "$key=$value"
                log_debug "Config: $key=$value"
                ;;
            LOG_LEVEL|VERBOSE|DEBUG)
                declare -g "$key=$value"
                log_debug "Config: $key=$value"
                ;;
            INSTALL_PREFIX|GO_INSTALL_DIR|CUSTOM_BIN_DIR)
                log_warning "Cannot override readonly path: $key (set via environment before script)"
                ;;
            *)
                log_warning "Unknown configuration key: $key"
                ;;
        esac
    done < "$user_config"
    
    log_success "User configuration loaded"
}

# Create example configuration file
config_create_example() {
    local example_config="${HOME}/.security-tools.conf.example"
    
    cat > "$example_config" << 'EOF'
# Bug Bounty Toolkit Configuration
# Copy to ~/.security-tools.conf and customize

# Skip specific components
#SKIP_ZSH_INSTALL=false
#SKIP_GO_INSTALL=false
#SKIP_RUST_INSTALL=false
#SKIP_PYTHON_INSTALL=false

# Custom directories
#CUSTOM_TOOLS_DIR=/opt/security-tools
#CUSTOM_WORDLISTS_DIR=/opt/wordlists
#CUSTOM_SCRIPTS_DIR=/opt/scripts

# Performance
#GO_TOOLS_PARALLEL=true
#PARALLEL_JOBS=4

# Logging
#LOG_LEVEL=INFO
#VERBOSE=false
#DEBUG=false
EOF
    
    log_success "Created example config: $example_config"
}

# Load saved configuration
config_load() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
        return 0
    fi
    return 1
}

# Save current configuration
config_save() {
    local config_dir
    config_dir="$(dirname "$CONFIG_FILE")"
    mkdir -p "$config_dir"
    
    cat > "$CONFIG_FILE" << EOF
# Bug Bounty Toolkit Configuration
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Version: $SCRIPT_VERSION

# Installation preferences
SKIP_ZSH_INSTALL=${SKIP_ZSH_INSTALL:-false}
SKIP_GO_INSTALL=${SKIP_GO_INSTALL:-false}
SKIP_RUST_INSTALL=${SKIP_RUST_INSTALL:-false}
SKIP_PYTHON_TOOLS=${SKIP_PYTHON_TOOLS:-false}
SKIP_GO_TOOLS=${SKIP_GO_TOOLS:-false}
SKIP_WORDLISTS=${SKIP_WORDLISTS:-false}

# Paths
TOOLS_DIR="$TOOLS_DIR"
WORDLISTS_DIR="$WORDLISTS_DIR"
SCRIPTS_DIR="$SCRIPTS_DIR"

# Metadata
LAST_INSTALL_DATE="$(date +%Y-%m-%d)"
INSTALLED_VERSION="$SCRIPT_VERSION"
EOF
}

# Initialize all required directories
config_init_dirs() {
    local dirs=(
        "$LOG_DIR" 
        "$STATE_DIR" 
        "$STEP_STATE_DIR" 
        "$TOOLS_DIR" 
        "$WORDLISTS_DIR" 
        "$SCRIPTS_DIR"
        "$CACHE_DIR"
        "$DATA_HOME"
        "$CONFIG_HOME"
        "$(dirname "$MANIFEST_FILE")"
    )
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir" 2>/dev/null || return 1
    done
}

# Export configuration for child processes
config_export() {
    export SCRIPT_VERSION SCRIPT_NAME LOG_FILE TOOLS_DIR WORDLISTS_DIR
    export RED GREEN YELLOW BLUE PURPLE CYAN WHITE GRAY NC
    export DEBUG VERBOSE DRY_RUN INTERACTIVE
}
