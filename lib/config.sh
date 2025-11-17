#!/bin/bash
# ==============================================================================
# Security Tools Installer - Configuration Module
# ==============================================================================
# Purpose: Central configuration for all tools, paths, and installation options
# Author: DevOps Security Team
# License: MIT
# ==============================================================================

# Script metadata
readonly SCRIPT_VERSION="3.0.0"
readonly SCRIPT_NAME="Security Tools Installer"
readonly SCRIPT_AUTHOR="DevOps Security Team"

# Paths and directories
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/lib"
readonly LOG_DIR="${HOME}/.security-tools/logs"
readonly STATE_DIR="${HOME}/.security-tools/state"
readonly STEP_STATE_DIR="${STATE_DIR}/steps"
readonly CONFIG_FILE="${HOME}/.security-tools/config"
readonly MANIFEST_FILE="${HOME}/.security-tools/manifest.json"
readonly LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"

# Installation directories
readonly TOOLS_DIR="${HOME}/tools"
readonly WORDLISTS_DIR="${HOME}/wordlists"
readonly SCRIPTS_DIR="${TOOLS_DIR}/scripts"

# Configurable installation prefixes (can be overridden via environment)
readonly INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
readonly GO_INSTALL_DIR="${GO_INSTALL_DIR:-${INSTALL_PREFIX}/go}"
readonly GO_VERSION_DIR="${GO_VERSION_DIR:-${INSTALL_PREFIX}}"
readonly CUSTOM_BIN_DIR="${CUSTOM_BIN_DIR:-${HOME}/.local/bin}"

# User-configurable paths (override via environment or config file)
readonly USER_TOOLS_DIR="${USER_TOOLS_DIR:-${TOOLS_DIR}}"
readonly USER_WORDLISTS_DIR="${USER_WORDLISTS_DIR:-${WORDLISTS_DIR}}"
readonly USER_SCRIPTS_DIR="${USER_SCRIPTS_DIR:-${SCRIPTS_DIR}}"

# Colors (ANSI escape codes)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly DIM='\033[2m'
readonly NC='\033[0m' # No Color

# Respect NO_COLOR and non-interactive environments to avoid leaking escape codes
if [[ -n "${NO_COLOR:-}" || ! -t 1 ]]; then
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly PURPLE=''
    readonly CYAN=''
    readonly WHITE=''
    readonly GRAY=''
    readonly DIM=''
    readonly NC=''
fi

# Icons and symbols
readonly ICON_SUCCESS="✅"
readonly ICON_ERROR="❌"
readonly ICON_WARNING="⚠️ "
readonly ICON_INFO="ℹ️ "
readonly ICON_DEBUG="🔍"
readonly ICON_DOWNLOAD="⬇️ "
readonly ICON_INSTALL="📦"
readonly ICON_UPDATE="🔄"
readonly ICON_ROCKET="🚀"

# Progress bar configuration
readonly PROGRESS_BAR_WIDTH=50
readonly SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
PROGRESS_BOARD_ENABLED=${PROGRESS_BOARD_ENABLED:-true}
readonly PROGRESS_DEFAULT_TOOL_WEIGHT=1

declare -A TOOL_WEIGHTS=(
    ["tool_install_zsh"]=2
    ["tool_install_go"]=3
    ["tool_install_rust"]=2
    ["tool_install_go_tools"]=4
    ["tool_install_python_tools"]=4
    ["tool_install_rust_tools"]=2
    ["tool_install_apt_tools"]=3
    ["tool_install_snap_tools"]=1
    ["tool_install_pipx_tools"]=2
    ["tool_install_wordlists"]=5
    ["tool_create_helper_scripts"]=1
)

# System requirements
readonly MIN_DISK_SPACE_GB=5
readonly MIN_MEMORY_GB=1
readonly REQUIRED_COMMANDS=("curl" "wget" "git")

# Network configuration
readonly NETWORK_TEST_URLS=("google.com" "github.com" "ubuntu.com" "8.8.8.8")
readonly NETWORK_TIMEOUT=5
readonly RETRY_MAX_ATTEMPTS=3
readonly RETRY_DELAY=5
readonly RETRY_BACKOFF_MULTIPLIER=2

# APT and system timeouts (in seconds)
readonly APT_LOCK_TIMEOUT=300
readonly APT_LOCK_CHECK_INTERVAL=2
readonly DOWNLOAD_TIMEOUT=300
readonly GIT_CLONE_TIMEOUT=600

# Cache configuration
readonly CACHE_DIR="${HOME}/.security-tools/cache"
readonly CACHE_MAX_AGE_HOURS=24

# Parallel installation configuration
readonly DEFAULT_PARALLEL_JOBS=4
readonly MAX_PARALLEL_JOBS=8

# Global flags (can be overridden by CLI arguments)
DEBUG=${DEBUG:-false}
VERBOSE=${VERBOSE:-false}
DRY_RUN=${DRY_RUN:-false}
INTERACTIVE=${INTERACTIVE:-true}
FORCE_INSTALL=${FORCE_INSTALL:-false}
SKIP_CHECKS=${SKIP_CHECKS:-false}

# Installation mode
INSTALL_MODE=""

# Rollback stack (for tracking installation steps)
declare -a ROLLBACK_STACK=()

# ==============================================================================
# Configuration File Loading
# ==============================================================================

# Load configuration from ~/.security-tools.conf if it exists
config_load_user_config() {
    local user_config="${HOME}/.security-tools.conf"
    
    if [[ ! -f "$user_config" ]]; then
        return 0  # No user config, use defaults
    fi
    
    log_info "Loading user configuration from $user_config"
    
    # Source the config file in a safe way (only allow specific variables)
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Only allow specific safe configuration variables
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
# Security Tools Installer Configuration
# Copy this file to ~/.security-tools.conf and customize as needed

# Skip specific installation categories
#SKIP_ZSH_INSTALL=false
#SKIP_GO_INSTALL=false
#SKIP_RUST_INSTALL=false
#SKIP_PYTHON_INSTALL=false

# Custom installation directories
#CUSTOM_TOOLS_DIR=/opt/security-tools
#CUSTOM_WORDLISTS_DIR=/opt/wordlists
#CUSTOM_SCRIPTS_DIR=/opt/scripts

# Performance settings
#GO_TOOLS_PARALLEL=true
#PARALLEL_JOBS=4

# Logging and debug
#LOG_LEVEL=INFO  # TRACE, DEBUG, INFO, WARNING, ERROR
#VERBOSE=true
#DEBUG=false

# Note: Installation paths (INSTALL_PREFIX, GO_INSTALL_DIR, etc.) 
# must be set via environment variables before running the script:
#   export INSTALL_PREFIX=/opt
#   ./install.sh --full
EOF
    
    log_success "Created example configuration: $example_config"
}

# ==============================================================================
# Tool Definitions - Modular Plugin System
# ==============================================================================

# Tool categories
readonly TOOL_CATEGORIES=("zsh" "languages" "go_tools" "python_tools" "rust_tools" "other_tools" "wordlists")

# -----------------------------------------------------------------------------
# ZSH Tools
# -----------------------------------------------------------------------------
declare -A ZSH_PACKAGES=(
    ["zsh"]="zsh"
    ["git"]="git"
    ["fonts"]="fonts-font-awesome"
    ["curl"]="curl"
    ["wget"]="wget"
)

declare -A ZSH_PLUGINS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    ["powerlevel10k"]="https://github.com/romkatv/powerlevel10k.git"
)

# -----------------------------------------------------------------------------
# Programming Languages
# -----------------------------------------------------------------------------
declare -A LANGUAGES=(
    ["go"]="1.22.4|https://go.dev/dl/go{VERSION}.linux-amd64.tar.gz"
    ["rust"]="stable|https://sh.rustup.rs"
    ["python3"]="system|apt"
)

# -----------------------------------------------------------------------------
# Go-based Security Tools
# -----------------------------------------------------------------------------
declare -A GO_TOOLS=(
    ["dnsx"]="github.com/projectdiscovery/dnsx/cmd/dnsx@latest|DNS toolkit and resolver"
    ["httpx"]="github.com/projectdiscovery/httpx/cmd/httpx@latest|Fast HTTP probe with rich features"
    ["unfurl"]="github.com/tomnomnom/unfurl@latest|URL parsing and analysis tool"
    ["waybackurls"]="github.com/tomnomnom/waybackurls@latest|Fetch URLs from Wayback Machine"
    ["gau"]="github.com/lc/gau/v2/cmd/gau@latest|Get All URLs from various sources"
    ["ffuf"]="github.com/ffuf/ffuf/v2@latest|Fast web fuzzer written in Go"
    ["gobuster"]="github.com/OJ/gobuster/v3@latest|Directory/file and DNS busting tool"
    ["cookiemonster"]="github.com/iangcarroll/cookiemonster/cmd/cookiemonster@latest|Cookie analysis and manipulation"
    ["nuclei"]="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest|Vulnerability scanner based on templates"
    ["subfinder"]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest|Subdomain discovery tool"
    ["katana"]="github.com/projectdiscovery/katana/cmd/katana@latest|Web crawling framework"
    ["naabu"]="github.com/projectdiscovery/naabu/v2/cmd/naabu@latest|Fast port scanner"
)

# -----------------------------------------------------------------------------
# Python-based Security Tools
# -----------------------------------------------------------------------------
declare -A PYTHON_TOOLS=(
    ["sqlmap"]="git|https://github.com/sqlmapproject/sqlmap.git|SQL injection tool"
    ["ghauri"]="git|https://github.com/r0oth3x49/ghauri.git|Advanced SQL injection tool|requirements.txt"
    ["recollapse"]="git|https://github.com/0xacb/recollapse.git|Regex-based attack pattern generator|requirements.txt|install.sh"
    ["commix"]="git|https://github.com/commixproject/commix.git|Command injection exploitation tool"
    ["sstimap"]="git|https://github.com/vladko312/SSTImap.git|SSTI detection and exploitation|requirements.txt"
    ["xsstrike"]="git|https://github.com/s0md3v/XSStrike.git|XSS detection suite|requirements.txt"
)

# -----------------------------------------------------------------------------
# Rust-based Tools
# -----------------------------------------------------------------------------
declare -A RUST_TOOLS=(
    ["x8"]="cargo|x8|Hidden parameter discovery tool"
)

# -----------------------------------------------------------------------------
# Other Tools (APT, Snap, Pipx)
# -----------------------------------------------------------------------------
declare -A APT_TOOLS=(
    ["build-essential"]="build-essential|Development tools and libraries"
    ["pkg-config"]="pkg-config|Package configuration helper"
    ["libssl-dev"]="libssl-dev|SSL development libraries"
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

declare -A SNAP_TOOLS=(
    ["dalfox"]="dalfox|XSS parameter analysis tool"
)

declare -A PIPX_TOOLS=(
    ["uro"]="uro|URL filtering and deduplication"
    ["arjun"]="arjun|HTTP parameter discovery"
)

# -----------------------------------------------------------------------------
# Wordlists
# -----------------------------------------------------------------------------
declare -A WORDLISTS=(
    ["seclists"]="https://github.com/danielmiessler/SecLists/archive/master.zip|SecLists-master|SecLists"
    ["bo0om"]="https://github.com/Bo0oM/fuzz.txt.git|git|Bo0oM"
    ["shayanrsh"]="https://github.com/shayanrsh/wordlist.git|git|wordlist"
    ["jwt-secrets"]="https://github.com/wallarm/jwt-secrets.git|git|jwt-secrets"
    ["yassineaboukir"]="https://gist.githubusercontent.com/yassineaboukir/8e12adefbd505ef704674ad6ad48743d/raw/all.txt|file|yassineaboukir-gist/all.txt"
)

# ==============================================================================
# Dependency Resolution
# ==============================================================================

# Tool dependencies (tool -> dependencies)
declare -A TOOL_DEPENDENCIES=(
    ["go_tools"]="go"
    ["rust_tools"]="rust"
    ["python_tools"]="python3"
    ["pipx_tools"]="python3-pip"
)

# ==============================================================================
# Installation Profiles
# ==============================================================================

declare -A PROFILES=(
    ["minimal"]="zsh|go|nuclei|subfinder|httpx"
    ["full"]="all"
    ["pentest"]="zsh|go|python_tools|go_tools|wordlists"
    ["developer"]="zsh|go|rust|build-essential"
)

# ==============================================================================
# Configuration Functions
# ==============================================================================

# Load user configuration
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
# Security Tools Installer Configuration
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
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

# Initialize directories
config_init_dirs() {
    local dirs=("$LOG_DIR" "$STATE_DIR" "$STEP_STATE_DIR" "$TOOLS_DIR" "$WORDLISTS_DIR" "$SCRIPTS_DIR")
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir" 2>/dev/null || return 1
    done
}

# Export configuration for other modules
config_export() {
    export SCRIPT_VERSION SCRIPT_NAME LOG_FILE TOOLS_DIR WORDLISTS_DIR
    export RED GREEN YELLOW BLUE PURPLE CYAN WHITE GRAY NC
    export DEBUG VERBOSE DRY_RUN INTERACTIVE
}
