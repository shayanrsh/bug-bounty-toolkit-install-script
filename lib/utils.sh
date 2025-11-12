#!/bin/bash
# ==============================================================================
# Security Tools Installer - Utility Functions Module
# ==============================================================================
# Purpose: Common utility functions for system checks, network operations, etc.
# ==============================================================================

# shellcheck disable=SC2155

# ==============================================================================
# Command Existence Checks
# ==============================================================================

util_command_exists() {
    command -v "$1" &>/dev/null
}

util_package_installed() {
    dpkg -l 2>/dev/null | grep -q "^ii  $1 "
}

# ==============================================================================
# System Information
# ==============================================================================

util_get_system_info() {
    local -n info_array=$1
    
    info_array["os"]=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
    info_array["kernel"]=$(uname -r)
    info_array["arch"]=$(uname -m)
    info_array["user"]=$(whoami)
    info_array["home"]="$HOME"
    info_array["memory"]=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "Unknown")
    info_array["disk_space"]=$(df -h "$HOME" 2>/dev/null | awk 'NR==2 {print $4}' || echo "Unknown")
    
    # WSL Detection
    if grep -qi microsoft /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        info_array["environment"]="WSL2"
        info_array["wsl_distro"]="${WSL_DISTRO_NAME:-Unknown}"
    else
        info_array["environment"]="Native Linux"
        info_array["wsl_distro"]="N/A"
    fi
}

util_is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]
}

# ==============================================================================
# APT Lock Handling
# ==============================================================================

util_wait_for_apt_lock() {
    local max_wait=300  # 5 minutes
    local waited=0
    local lock_files=(
        "/var/lib/dpkg/lock-frontend"
        "/var/lib/dpkg/lock"
        "/var/lib/apt/lists/lock"
        "/var/cache/apt/archives/lock"
    )
    
    # Check if any lock files exist
    local locks_found=false
    for lock_file in "${lock_files[@]}"; do
        if sudo lsof "$lock_file" &>/dev/null; then
            locks_found=true
            break
        fi
    done
    
    if [[ "$locks_found" == "false" ]]; then
        return 0
    fi
    
    log_warning "APT/dpkg is locked by another process"
    log_info "Waiting for lock to be released (timeout: ${max_wait}s)..."
    
    while [[ $waited -lt $max_wait ]]; do
        local all_clear=true
        
        for lock_file in "${lock_files[@]}"; do
            if sudo lsof "$lock_file" &>/dev/null; then
                all_clear=false
                break
            fi
        done
        
        if [[ "$all_clear" == "true" ]]; then
            log_success "APT lock released"
            return 0
        fi
        
        printf "\r${YELLOW}⏳${NC} Waiting for APT lock... (%ds/%ds)" "$waited" "$max_wait"
        sleep 2
        ((waited+=2))
    done
    
    echo ""
    log_error "Timeout waiting for APT lock"
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        if ui_confirm "Force kill processes holding APT locks?" "n"; then
            util_force_kill_apt_locks
            return $?
        fi
    fi
    
    return 1
}

util_force_kill_apt_locks() {
    log_warning "Force killing processes holding APT locks..."
    
    local lock_files=(
        "/var/lib/dpkg/lock-frontend"
        "/var/lib/dpkg/lock"
        "/var/lib/apt/lists/lock"
        "/var/cache/apt/archives/lock"
    )
    
    local killed=false
    for lock_file in "${lock_files[@]}"; do
        if [[ -f "$lock_file" ]]; then
            local pids=$(sudo lsof -t "$lock_file" 2>/dev/null)
            if [[ -n "$pids" ]]; then
                log_info "Killing processes: $pids"
                sudo kill -9 $pids 2>/dev/null && killed=true
            fi
        fi
    done
    
    # Remove lock files
    for lock_file in "${lock_files[@]}"; do
        sudo rm -f "$lock_file" 2>/dev/null
    done
    
    # Reconfigure dpkg if needed
    if $killed; then
        log_info "Reconfiguring dpkg..."
        sudo dpkg --configure -a 2>/dev/null || true
    fi
    
    log_success "APT locks cleared"
    return 0
}

util_is_root() {
    [[ $EUID -eq 0 ]]
}

# ==============================================================================
# System Requirements Checking
# ==============================================================================

util_check_disk_space() {
    local required_gb=${1:-$MIN_DISK_SPACE_GB}
    local check_path="${2:-$HOME}"
    
    # Handle WSL2 special case
    if util_is_wsl && [[ -d "/mnt/c" ]]; then
        local c_space
        c_space=$(df "/mnt/c" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
        if [[ $c_space -gt 0 ]]; then
            check_path="/mnt/c"
        fi
    fi
    
    local available_kb
    available_kb=$(df "$check_path" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
    local available_gb=$((available_kb / 1024 / 1024))
    local required_kb=$((required_gb * 1024 * 1024))
    
    log_debug "Disk space check: ${available_gb}GB available, ${required_gb}GB required"
    
    if [[ $available_kb -lt $required_kb ]]; then
        log_warning "Low disk space: ${available_gb}GB available (${required_gb}GB recommended)"
        return 1
    fi
    
    return 0
}

util_check_memory() {
    local required_gb=${1:-$MIN_MEMORY_GB}
    local available_kb
    available_kb=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "0")
    local available_gb=$((available_kb / 1024 / 1024))
    
    log_debug "Memory check: ${available_gb}GB available, ${required_gb}GB required"
    
    if [[ $available_gb -lt $required_gb ]]; then
        log_warning "Low memory: ${available_gb}GB available (${required_gb}GB recommended)"
        return 1
    fi
    
    return 0
}

util_check_internet() {
    log_info "Testing internet connectivity..."
    
    for url in "${NETWORK_TEST_URLS[@]}"; do
        if ping -c 1 -W "$NETWORK_TIMEOUT" "$url" &>/dev/null; then
            log_success "Internet connectivity confirmed via $url"
            return 0
        fi
    done
    
    log_error "No internet connection detected"
    return 1
}

util_check_ubuntu_version() {
    if ! lsb_release -d 2>/dev/null | grep -qi "ubuntu"; then
        log_warning "This script is designed for Ubuntu systems"
        if [[ "$FORCE_INSTALL" == "false" ]] && [[ "$INTERACTIVE" == "true" ]]; then
            ui_confirm "Continue anyway?" "n" || return 1
        fi
    fi
    return 0
}

util_check_prerequisites() {
    local missing_commands=()
    
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! util_command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        log_info "Installing missing prerequisites..."
        
        if [[ "$DRY_RUN" == "false" ]]; then
            sudo apt-get update -qq
            sudo apt-get install -y "${missing_commands[@]}"
        fi
    fi
    
    return 0
}

# ==============================================================================
# Sudo Privilege Checking
# ==============================================================================

util_check_sudo() {
    if util_is_root; then
        log_warning "Running as root user"
        return 0
    fi
    
    log_info "Checking sudo privileges..."
    
    if sudo -n true 2>/dev/null; then
        log_success "Password-less sudo access confirmed"
        return 0
    fi
    
    log_warning "Password-less sudo not configured"
    
    if sudo true; then
        log_success "Sudo access confirmed"
        return 0
    else
        log_error "This script requires sudo privileges"
        ui_show_error "Sudo access required" \
            "Run: sudo usermod -aG sudo $(whoami) or use: sudo $0"
        return 1
    fi
}

# ==============================================================================
# Retry Logic with Exponential Backoff
# ==============================================================================

util_retry() {
    local max_attempts="${1:-$RETRY_MAX_ATTEMPTS}"
    local delay="${2:-$RETRY_DELAY}"
    shift 2
    
    local attempt=1
    local current_delay="$delay"
    
    while [[ $attempt -le $max_attempts ]]; do
        log_debug "Attempt $attempt/$max_attempts: $*"
        
        if "$@"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            log_warning "Command failed. Retrying in ${current_delay}s... ($attempt/$max_attempts)"
            sleep "$current_delay"
            current_delay=$((current_delay * RETRY_BACKOFF_MULTIPLIER))
        else
            log_error "Command failed after $max_attempts attempts"
            return 1
        fi
        
        ((attempt++))
    done
    
    return 1
}

# ==============================================================================
# Download Functions
# ==============================================================================

util_download() {
    local url="$1"
    local output="$2"
    local description="${3:-Download}"
    
    log_info "Downloading: $description"
    log_debug "URL: $url -> $output"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would download: $url"
        return 0
    fi
    
    # Use wget with progress bar
    if util_command_exists wget; then
        wget --progress=bar:force:noscroll \
             --timeout="$NETWORK_TIMEOUT" \
             --tries="$RETRY_MAX_ATTEMPTS" \
             "$url" -O "$output" 2>&1 | \
        while IFS= read -r line; do
            if [[ $line =~ ([0-9]+)% ]]; then
                local percent="${BASH_REMATCH[1]}"
                ui_progress_bar "$percent" 100 "$description"
            fi
        done
        echo # New line after progress
        return "${PIPESTATUS[0]}"
    elif util_command_exists curl; then
        curl -L --progress-bar --connect-timeout "$NETWORK_TIMEOUT" \
             --retry "$RETRY_MAX_ATTEMPTS" \
             "$url" -o "$output"
        return $?
    else
        log_error "Neither wget nor curl is available"
        return 1
    fi
}

util_download_verify() {
    local url="$1"
    local output="$2"
    local checksum_url="${3:-}"
    local description="${4:-Download}"
    
    if ! util_download "$url" "$output" "$description"; then
        return 1
    fi
    
    # Verify checksum if provided
    if [[ -n "$checksum_url" ]] && util_command_exists sha256sum; then
        local checksum_file="${output}.sha256"
        if util_download "$checksum_url" "$checksum_file" "Checksum"; then
            log_info "Verifying checksum..."
            if sha256sum -c "$checksum_file" &>/dev/null; then
                log_success "Checksum verification passed"
                rm -f "$checksum_file"
                return 0
            else
                log_error "Checksum verification failed"
                rm -f "$output" "$checksum_file"
                return 1
            fi
        fi
    fi
    
    return 0
}

# ==============================================================================
# Git Operations
# ==============================================================================

util_git_clone() {
    local repo_url="$1"
    local dest_dir="$2"
    local description="${3:-Repository}"
    
    log_info "Cloning: $description"
    log_debug "Repo: $repo_url -> $dest_dir"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would clone: $repo_url"
        return 0
    fi
    
    if [[ -d "$dest_dir" ]]; then
        log_warning "$description already exists at $dest_dir"
        
        if [[ "$FORCE_INSTALL" == "true" ]]; then
            log_info "Force mode: updating existing repository"
            cd "$dest_dir" || return 1
            git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || return 1
            cd - >/dev/null || return 1
            return 0
        fi
        
        return 0
    fi
    
    git clone --depth=1 "$repo_url" "$dest_dir" 2>&1 | \
        grep -v "^Cloning" | \
        while IFS= read -r line; do
            log_debug "$line"
        done
    
    return "${PIPESTATUS[0]}"
}

util_git_update() {
    local repo_dir="$1"
    local description="${2:-Repository}"
    
    if [[ ! -d "$repo_dir/.git" ]]; then
        log_warning "$description is not a git repository"
        return 1
    fi
    
    log_info "Updating: $description"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would update: $repo_dir"
        return 0
    fi
    
    cd "$repo_dir" || return 1
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null
    local result=$?
    cd - >/dev/null || return 1
    
    return $result
}

# ==============================================================================
# Version Management
# ==============================================================================

util_get_tool_version() {
    local tool_name="$1"
    
    case "$tool_name" in
        go)
            go version 2>/dev/null | awk '{print $3}' | sed 's/go//'
            ;;
        rustc|rust)
            rustc --version 2>/dev/null | awk '{print $2}'
            ;;
        python|python3)
            python3 --version 2>/dev/null | awk '{print $2}'
            ;;
        zsh)
            zsh --version 2>/dev/null | awk '{print $2}'
            ;;
        *)
            if util_command_exists "$tool_name"; then
                "$tool_name" --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+(\.\d+)?' || echo "unknown"
            else
                echo "not installed"
            fi
            ;;
    esac
}

# ==============================================================================
# Manifest Management (JSON)
# ==============================================================================

util_manifest_init() {
    mkdir -p "$(dirname "$MANIFEST_FILE")"
    
    cat > "$MANIFEST_FILE" << EOF
{
    "version": "$SCRIPT_VERSION",
    "generated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "system": {
        "os": "$(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')",
        "kernel": "$(uname -r)",
        "arch": "$(uname -m)"
    },
    "tools": {}
}
EOF
}

util_manifest_add_tool() {
    local category="$1"
    local tool_name="$2"
    local version="$3"
    local install_path="${4:-}"
    
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        util_manifest_init
    fi
    
    # Use jq if available, otherwise simple append
    if util_command_exists jq; then
        local temp_file
        temp_file=$(mktemp)
        jq --arg cat "$category" \
           --arg name "$tool_name" \
           --arg ver "$version" \
           --arg path "$install_path" \
           '.tools[$cat] += [{name: $name, version: $ver, path: $path, installed: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))}]' \
           "$MANIFEST_FILE" > "$temp_file"
        mv "$temp_file" "$MANIFEST_FILE"
    fi
}

# ==============================================================================
# Cleanup and Temporary Files
# ==============================================================================

util_create_temp_file() {
    mktemp -t "security-tools.XXXXXX"
}

util_create_temp_dir() {
    mktemp -d -t "security-tools.XXXXXX"
}

util_cleanup_temp() {
    local temp_pattern="/tmp/security-tools.*"
    # shellcheck disable=SC2086
    rm -rf $temp_pattern 2>/dev/null || true
}

# ==============================================================================
# Environment Variables
# ==============================================================================

util_add_to_path() {
    local new_path="$1"
    
    if [[ ":$PATH:" != *":$new_path:"* ]]; then
        export PATH="$new_path:$PATH"
        log_debug "Added to PATH: $new_path"
    fi
}

# Setup Go environment variables in shell RC files
util_setup_go_env() {
    log_info "Configuring Go environment variables..."
    
    # Determine which shell RC file to use
    local rc_files=()
    
    # Check for ZSH
    if [[ -f "$HOME/.zshrc" ]]; then
        rc_files+=("$HOME/.zshrc")
    fi
    
    # Check for Bash
    if [[ -f "$HOME/.bashrc" ]]; then
        rc_files+=("$HOME/.bashrc")
    fi
    
    # If no RC files found, create bashrc
    if [[ ${#rc_files[@]} -eq 0 ]]; then
        rc_files+=("$HOME/.bashrc")
        touch "$HOME/.bashrc"
        log_info "Created $HOME/.bashrc"
    fi
    
    # Go environment configuration
    local go_config='
# Go Programming Language Configuration
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$(go env GOPATH)/bin
export GOPATH=$(go env GOPATH)
'
    
    for rc_file in "${rc_files[@]}"; do
        # Check if Go config already exists
        if grep -q "Go Programming Language Configuration" "$rc_file" 2>/dev/null; then
            log_info "Go environment already configured in $rc_file"
        else
            log_info "Adding Go environment to $rc_file"
            echo "$go_config" >> "$rc_file"
            log_success "Go environment added to $rc_file"
        fi
    done
    
    # Add to current session PATH
    export PATH="/usr/local/go/bin:$PATH"
    if command -v go &>/dev/null; then
        export PATH="$(go env GOPATH)/bin:$PATH"
        export GOPATH="$(go env GOPATH)"
    fi
    
    log_success "Go environment configured"
    log_info "Note: Run 'source ~/.zshrc' or 'source ~/.bashrc' to apply changes"
}

util_source_env() {
    local env_file="$1"
    
    if [[ -f "$env_file" ]]; then
        # shellcheck disable=SC1090
        source "$env_file"
        log_debug "Sourced environment: $env_file"
        return 0
    fi
    return 1
}

# ==============================================================================
# File Operations
# ==============================================================================

util_backup_file() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        log_info "Backed up: $file -> $backup"
        return 0
    fi
    return 1
}

util_append_unique() {
    local file="$1"
    local content="$2"
    
    if ! grep -Fq "$content" "$file" 2>/dev/null; then
        echo "$content" >> "$file"
        log_debug "Appended to $file: $content"
        return 0
    fi
    return 1
}

# ==============================================================================
# Process Management
# ==============================================================================

util_kill_process() {
    local process_name="$1"
    
    if pgrep -f "$process_name" >/dev/null; then
        log_warning "Killing process: $process_name"
        pkill -f "$process_name"
        sleep 1
        
        if pgrep -f "$process_name" >/dev/null; then
            pkill -9 -f "$process_name"
        fi
    fi
}

# ==============================================================================
# Validation Functions
# ==============================================================================

util_validate_url() {
    local url="$1"
    
    if [[ "$url" =~ ^https?:// ]]; then
        return 0
    fi
    return 1
}

util_validate_directory() {
    local dir="$1"
    
    if [[ -d "$dir" ]] && [[ -w "$dir" ]]; then
        return 0
    fi
    return 1
}

util_validate_tool_installed() {
    local tool="$1"
    
    if util_command_exists "$tool"; then
        log_success "$tool is installed"
        return 0
    else
        log_error "$tool is not installed"
        return 1
    fi
}
