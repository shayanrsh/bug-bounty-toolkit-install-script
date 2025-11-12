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

# Package installation cache to avoid repeated dpkg calls
declare -A PACKAGE_CACHE=()

util_command_exists() {
    command -v "$1" &>/dev/null
}

util_package_installed() {
    local pkg="$1"
    
    # Check cache first
    if [[ -n "${PACKAGE_CACHE[$pkg]:-}" ]]; then
        [[ "${PACKAGE_CACHE[$pkg]}" == "installed" ]] && return 0 || return 1
    fi
    
    # Check actual installation and cache result
    if dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
        PACKAGE_CACHE[$pkg]="installed"
        return 0
    else
        PACKAGE_CACHE[$pkg]="not_installed"
        return 1
    fi
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
# APT Lock Handling - IMPROVED
# ==============================================================================

# Track if APT has been updated this session
APT_UPDATED=false

util_apt_update() {
    if [[ "$APT_UPDATED" == "true" ]]; then
        log_debug "APT cache already updated this session, skipping"
        return 0
    fi
    
    log_info "Updating package lists..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would update APT cache"
        APT_UPDATED=true
        return 0
    fi
    
    # Acquire lock first
    if ! util_apt_lock_acquire; then
        log_error "Could not acquire APT lock for update"
        return 1
    fi
    
    if sudo apt-get update 2>&1 | tee -a "$LOG_FILE" | grep -q "^Reading"; then
        APT_UPDATED=true
        log_success "Package lists updated successfully"
        return 0
    else
        log_error "Failed to update package lists"
        return 1
    fi
}

util_apt_lock_acquire() {
    # Try to acquire APT lock by running a dummy apt-get command
    local max_wait="$APT_LOCK_TIMEOUT"
    local check_interval="$APT_LOCK_CHECK_INTERVAL"
    local waited=0
    
    while [[ $waited -lt $max_wait ]]; do
        # Try to acquire lock by running apt-get check
        if sudo flock -n /var/lib/dpkg/lock-frontend true 2>/dev/null; then
            return 0
        fi
        
        if (( waited % 10 == 0 )); then
            log_info "Waiting for APT lock... (${waited}s/${max_wait}s)"
            util_log_apt_lock_holders
        fi
        
        sleep "$check_interval"
        ((waited+=check_interval))
    done
    
    log_error "Timeout waiting for APT lock after ${max_wait}s"
    return 1
}

util_wait_for_apt_lock() {
    local max_wait="$APT_LOCK_TIMEOUT"
    local waited=0
    local last_report=-10
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
        if ! util_get_apt_lock_holders >/dev/null 2>&1; then
            printf '\r\033[K'
            log_success "APT lock released"
            sleep 1  # Brief pause to ensure lock is fully released
            return 0
        fi

        if (( waited - last_report >= 10 )); then
            util_log_apt_lock_holders
            last_report=$waited
        fi

        printf "\r${YELLOW}⏳${NC} Waiting for APT lock... (%ds/%ds)" "$waited" "$max_wait"
        sleep 2
        ((waited+=2))
    done
    
    printf '\r\033[K'
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

# ==============================================================================
# Root/Sudo Handling
# ==============================================================================

util_is_root() {
    [[ "$EUID" -eq 0 ]]
}

util_sudo() {
    # Smart sudo wrapper - if already root, run directly; otherwise use sudo
    if util_is_root; then
        "$@"  # Already root, no sudo needed
    else
        sudo -n "$@" 2>/dev/null || sudo "$@"  # Try non-interactive first
    fi
}

# ==============================================================================
# APT Lock Holders
# ==============================================================================

util_get_apt_lock_holders() {
    local lock_files=(
        "/var/lib/dpkg/lock-frontend"
        "/var/lib/dpkg/lock"
        "/var/lib/apt/lists/lock"
        "/var/cache/apt/archives/lock"
    )
    local holders=()

    for lock_file in "${lock_files[@]}"; do
        local pids
        pids=$(sudo lsof -t "$lock_file" 2>/dev/null | sort -u | tr '\n' ' ')
        if [[ -z "$pids" ]]; then
            continue
        fi
        for pid in $pids; do
            local cmd user
            cmd=$(ps -p "$pid" -o comm= 2>/dev/null | tr -d '\n' || echo "unknown")
            user=$(ps -p "$pid" -o user= 2>/dev/null | tr -d '\n' || echo "unknown")
            holders+=("${pid}|${user}|${cmd}|${lock_file}")
        done
    done

    if [[ ${#holders[@]} -eq 0 ]]; then
        return 1
    fi

    printf '%s\n' "${holders[@]}"
    return 0
}

util_log_apt_lock_holders() {
    local holders
    if ! holders=$(util_get_apt_lock_holders); then
        return 1
    fi

    log_info "APT lock currently held by:"
    while IFS='|' read -r pid user cmd lock_file; do
        log_info "  PID ${pid} (${cmd}) by ${user} -> ${lock_file}"
    done <<< "$holders"
}

util_is_root() {
    [[ $EUID -eq 0 ]]
}

# ==============================================================================
# Input Validation
# ==============================================================================

util_validate_url() {
    local url="$1"
    
    # Basic URL validation
    if [[ ! "$url" =~ ^https?:// ]]; then
        return 1
    fi
    
    # Check for suspicious characters
    if [[ "$url" =~ [[:space:]] ]] || [[ "$url" =~ [\;\&\|] ]]; then
        return 1
    fi
    
    return 0
}

util_validate_path() {
    local path="$1"
    
    # Check for path traversal attempts
    if [[ "$path" == *".."* ]]; then
        log_warning "Path contains '..' which may be a traversal attempt: $path"
        return 1
    fi
    
    # Check for suspicious characters
    if [[ "$path" =~ [\;\&\|\$\`] ]]; then
        log_warning "Path contains suspicious characters: $path"
        return 1
    fi
    
    return 0
}

util_validate_profile_name() {
    local profile="$1"
    
    # Only allow alphanumeric, dash, underscore
    if [[ ! "$profile" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Invalid profile name: $profile (only alphanumeric, dash, underscore allowed)"
        return 1
    fi
    
    return 0
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

# Get Ubuntu version number
util_get_ubuntu_version() {
    lsb_release -rs 2>/dev/null || echo "unknown"
}

# Get Ubuntu codename
util_get_ubuntu_codename() {
    lsb_release -cs 2>/dev/null || echo "unknown"
}

# Check if Ubuntu version is supported
util_is_ubuntu_version_supported() {
    local version
    version=$(util_get_ubuntu_version)
    
    case "$version" in
        24.04|22.04|20.04)
            return 0
            ;;
        *)
            log_warning "Ubuntu $version may not be fully supported (tested on 20.04, 22.04, 24.04)"
            return 1
            ;;
    esac
}

# Get version-specific package name if needed
# Usage: util_get_version_specific_package "base_name"
util_get_version_specific_package() {
    local base_name="$1"
    local version
    version=$(util_get_ubuntu_version)
    
    # Some packages have version-specific names
    case "$base_name" in
        python3-venv)
            case "$version" in
                20.04)
                    echo "python3.8-venv"
                    ;;
                22.04)
                    echo "python3.10-venv"
                    ;;
                24.04)
                    echo "python3.12-venv"
                    ;;
                *)
                    echo "python3-venv"
                    ;;
            esac
            ;;
        *)
            echo "$base_name"
            ;;
    esac
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
            util_wait_for_apt_lock || return 1
            if ! ui_stream_command "Updating package lists" sudo apt-get update; then
                return 1
            fi
            if ! ui_stream_command "Installing prerequisites" sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing_commands[@]}"; then
                return 1
            fi
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

util_download_cached() {
    local url="$1"
    local output="$2"
    local description="${3:-Download}"
    local cache_key
    cache_key=$(echo -n "$url" | md5sum | awk '{print $1}')
    local cached_file="$CACHE_DIR/$cache_key"
    
    # Create cache directory if needed
    mkdir -p "$CACHE_DIR"
    
    # Check if cached file exists and is recent (< 24 hours)
    if [[ -f "$cached_file" ]]; then
        local file_age_hours
        file_age_hours=$(( ($(date +%s) - $(stat -c %Y "$cached_file" 2>/dev/null || stat -f %m "$cached_file" 2>/dev/null || echo 0)) / 3600 ))
        
        if [[ $file_age_hours -lt $CACHE_MAX_AGE_HOURS ]]; then
            log_info "Using cached file for $description (age: ${file_age_hours}h)"
            cp "$cached_file" "$output"
            return 0
        else
            log_debug "Cached file expired (age: ${file_age_hours}h), re-downloading"
        fi
    fi
    
    # Download fresh copy
    if util_download "$url" "$output" "$description"; then
        # Cache the downloaded file
        cp "$output" "$cached_file"
        return 0
    fi
    
    return 1
}

util_download() {
    local url="$1"
    local output="$2"
    local description="${3:-Download}"
    
    # Validate URL
    if ! util_validate_url "$url"; then
        log_error "Invalid URL: $url"
        return 1
    fi
    
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
    
    if ui_stream_command "Cloning ${description}" git clone --depth=1 "$repo_url" "$dest_dir"; then
        return 0
    else
        # Clean up partial clone on failure
        log_warning "Clone failed, cleaning up partial directory"
        rm -rf "$dest_dir" 2>/dev/null || true
        return 1
    fi
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
    local version="unknown"
    
    case "$tool_name" in
        go)
            version=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
            ;;
        rustc|rust)
            version=$(rustc --version 2>/dev/null | awk '{print $2}')
            ;;
        python|python3)
            version=$(python3 --version 2>/dev/null | awk '{print $2}')
            ;;
        zsh)
            version=$(zsh --version 2>/dev/null | awk '{print $2}')
            ;;
        *)
            if util_command_exists "$tool_name"; then
                # Try multiple version flags in order
                for flag in "--version" "-version" "-v" "version"; do
                    version=$("$tool_name" $flag 2>/dev/null | head -n1 | grep -oP '\d+\.\d+(\.\d+)?' || true)
                    [[ -n "$version" ]] && break
                done
                
                # If still no version, try help output
                if [[ -z "$version" || "$version" == "unknown" ]]; then
                    version=$("$tool_name" --help 2>/dev/null | head -n5 | grep -oP '\d+\.\d+(\.\d+)?' | head -n1 || echo "unknown")
                fi
            else
                version="not installed"
            fi
            ;;
    esac
    
    echo "${version:-unknown}"
}

# ==============================================================================
# Manifest Management (JSON)
# ==============================================================================

util_manifest_init() {
    local force="${1:-false}"
    mkdir -p "$(dirname "$MANIFEST_FILE")"
    if [[ -f "$MANIFEST_FILE" ]] && [[ "$force" != "true" ]]; then
        return 0
    fi
    
    cat > "$MANIFEST_FILE" << EOF
{
    "version": "$SCRIPT_VERSION",
    "generated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "system": {
        "os": "$(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')",
        "kernel": "$(uname -r)",
        "arch": "$(uname -m)"
    },
    "tools": {},
    "steps": {}
}
EOF
}

util_manifest_add_tool() {
    local category="$1"
    local tool_name="$2"
    local version="$3"
    local install_path="${4:-}"
    
    # Skip manifest modifications in dry run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        log_debug "[DRY RUN] Would add to manifest: $category/$tool_name v$version"
        return 0
    fi
    
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
    else
        printf '%s|%s|%s|%s\n' "$category" "$tool_name" "$version" "$install_path" >> "${MANIFEST_FILE}.fallback"
    fi
}

util_manifest_set_step() {
    local step_id="$1"
    local status="$2"
    local description="${3:-}"
    local detail="${4:-}"

    if [[ -z "$step_id" ]]; then
        return 0
    fi
    
    # Skip manifest modifications in dry run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        log_debug "[DRY RUN] Would update manifest step: $step_id -> $status"
        return 0
    fi

    util_manifest_init

    if util_command_exists jq; then
        local temp_file
        temp_file=$(mktemp)
        jq --arg id "$step_id" \
           --arg status "$status" \
           --arg desc "$description" \
           --arg detail "$detail" \
           '.steps[$id] = {
                status: $status,
                description: $desc,
                detail: $detail,
                updated: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
            }' \
            "$MANIFEST_FILE" > "$temp_file"
        mv "$temp_file" "$MANIFEST_FILE"
    fi
}

util_generate_manifest() {
    util_manifest_init

    if [[ ! -f "${MANIFEST_FILE}.fallback" ]]; then
        return 0
    fi

    if ! util_command_exists jq; then
        log_debug "jq not available, keeping manifest fallback entries"
        return 0
    fi

    while IFS='|' read -r category tool version path; do
        util_manifest_add_tool "$category" "$tool" "$version" "$path"
    done < "${MANIFEST_FILE}.fallback"

    rm -f "${MANIFEST_FILE}.fallback"
}

# ==============================================================================
# Tool Health Checks
# ==============================================================================

util_verify_tool() {
    local tool="$1"
    local test_args="${2:---version}"
    
    log_debug "Verifying tool: $tool"
    
    # Check if command exists
    if ! util_command_exists "$tool"; then
        log_error "Tool not found in PATH: $tool"
        return 1
    fi
    
    # Try to execute with test args
    if timeout 5 "$tool" $test_args >/dev/null 2>&1; then
        log_success "✓ $tool is working"
        return 0
    else
        log_warning "⚠ $tool exists but may not be working properly"
        return 1
    fi
}

util_health_check() {
    local category="$1"
    shift
    local tools=("$@")
    local failed=()
    
    ui_section_header "Health Check: $category" "$CYAN"
    
    for tool in "${tools[@]}"; do
        if ! util_verify_tool "$tool"; then
            failed+=("$tool")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_warning "Some tools failed health check: ${failed[*]}"
        return 1
    fi
    
    log_success "All $category tools passed health check"
    return 0
}

# ==============================================================================
# State Management
# ==============================================================================

util_state_step_file() {
    local step_id="$1"
    echo "${STEP_STATE_DIR}/${step_id}.state"
}

util_state_prepare() {
    local mode="${1:-reset}"
    mkdir -p "$STEP_STATE_DIR"
    if [[ "$mode" == "reset" ]]; then
        rm -f "$STEP_STATE_DIR"/*.state 2>/dev/null || true
    fi
}

util_state_mark_step() {
    local step_id="$1"
    local status="$2"
    local description="${3:-}"
    local detail="${4:-}"
    local step_file
    step_file=$(util_state_step_file "$step_id")

    mkdir -p "$STEP_STATE_DIR"
    printf '%s|%s|%s|%s\n' "$status" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$description" "$detail" > "$step_file"
    util_manifest_set_step "$step_id" "$status" "$description" "$detail"
}

util_state_get_step_status() {
    local step_id="$1"
    local step_file
    step_file=$(util_state_step_file "$step_id")
    if [[ -f "$step_file" ]]; then
        cut -d'|' -f1 "$step_file"
    fi
}

util_state_get_step_description() {
    local step_id="$1"
    local step_file
    step_file=$(util_state_step_file "$step_id")
    if [[ -f "$step_file" ]]; then
        cut -d'|' -f3 "$step_file"
    fi
}

util_state_get_step_detail() {
    local step_id="$1"
    local step_file
    step_file=$(util_state_step_file "$step_id")
    if [[ -f "$step_file" ]]; then
        cut -d'|' -f4 "$step_file"
    fi
}

util_state_clear_step() {
    local step_id="$1"
    local step_file
    step_file=$(util_state_step_file "$step_id")
    rm -f "$step_file" 2>/dev/null || true
}

# ==============================================================================
# Cleanup and Temporary Files
# ==============================================================================

# Track temporary files for cleanup
declare -a TEMP_FILES=()
declare -a TEMP_DIRS=()

util_create_temp_file() {
    local temp_file
    temp_file=$(mktemp -t "security-tools.XXXXXX")
    TEMP_FILES+=("$temp_file")
    echo "$temp_file"
}

util_create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d -t "security-tools.XXXXXX")
    TEMP_DIRS+=("$temp_dir")
    echo "$temp_dir"
}

util_cleanup_temp() {
    # Clean tracked temporary files
    for temp_file in "${TEMP_FILES[@]}"; do
        if [[ -f "$temp_file" ]]; then
            rm -f "$temp_file" 2>/dev/null || true
            log_trace "Cleaned temp file: $temp_file"
        fi
    done
    
    # Clean tracked temporary directories
    for temp_dir in "${TEMP_DIRS[@]}"; do
        if [[ -d "$temp_dir" ]]; then
            rm -rf "$temp_dir" 2>/dev/null || true
            log_trace "Cleaned temp dir: $temp_dir"
        fi
    done
    
    # Clean any remaining temp files matching pattern
    local temp_pattern="/tmp/security-tools.*"
    # shellcheck disable=SC2086
    rm -rf $temp_pattern 2>/dev/null || true
}

util_cleanup_single_temp() {
    local temp_path="$1"
    
    if [[ -f "$temp_path" ]]; then
        rm -f "$temp_path" 2>/dev/null || true
        log_trace "Cleaned single temp file: $temp_path"
    elif [[ -d "$temp_path" ]]; then
        rm -rf "$temp_path" 2>/dev/null || true
        log_trace "Cleaned single temp dir: $temp_path"
    fi
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
    
    # Go environment configuration - FIXED: Use literal variables, not command substitution
    local go_config='
# Go Programming Language Configuration
export GOROOT="/usr/local/go"
export GOPATH="${HOME}/go"
export PATH="${PATH}:${GOROOT}/bin:${GOPATH}/bin"
'
    
    for rc_file in "${rc_files[@]}"; do
        # Check if Go config already exists
        if grep -q "Go Programming Language Configuration" "$rc_file" 2>/dev/null; then
            log_info "Go environment already configured in $rc_file"
        else
            # Show preview if interactive
            if [[ "$INTERACTIVE" == "true" ]]; then
                util_preview_rc_changes "$rc_file" "$go_config" "Go environment configuration"
            fi
            
            log_info "Adding Go environment to $rc_file"
            echo "$go_config" >> "$rc_file"
            log_success "Go environment added to $rc_file"
        fi
    done
    
    # Add to current session PATH
    export GOROOT="/usr/local/go"
    export GOPATH="${HOME}/go"
    export PATH="/usr/local/go/bin:${GOPATH}/bin:$PATH"
    
    log_success "Go environment configured"
    log_info "Note: Run 'source ~/.zshrc' or 'source ~/.bashrc' to apply changes"
}

# Preview changes before modifying RC files
# Usage: util_preview_rc_changes "rc_file" "new_content" "description"
util_preview_rc_changes() {
    local rc_file="$1"
    local new_content="$2"
    local description="${3:-configuration}"
    
    echo ""
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${CYAN}  Preview: Changes to $(basename "$rc_file")${NC}"
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "${YELLOW}The following $description will be added:${NC}"
    echo ""
    echo "${GREEN}$new_content${NC}"
    echo ""
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if ! ui_confirm "Apply these changes to $rc_file?" "y"; then
        log_warning "Skipped modifications to $rc_file"
        return 1
    fi
    
    return 0
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

# ==============================================================================
# Common Pattern Abstractions (DRY)
# ==============================================================================

# Install APT packages with common pattern
# Usage: util_apt_install "description" package1 package2 ...
util_apt_install() {
    local description="$1"
    shift
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_error "No packages specified for installation"
        return 1
    fi
    
    # Filter already installed packages
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! util_package_installed "$pkg"; then
            to_install+=("$pkg")
        else
            log_debug "Package already installed: $pkg"
        fi
    done
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_info "All packages already installed: ${packages[*]}"
        return 0
    fi
    
    log_info "Installing ${#to_install[@]} package(s): ${to_install[*]}"
    
    if ! ui_stream_command "$description" sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${to_install[@]}"; then
        log_error "Failed to install packages: ${to_install[*]}"
        return 1
    fi
    
    # Update cache
    for pkg in "${to_install[@]}"; do
        PACKAGE_CACHE[$pkg]="installed"
    done
    
    log_success "Installed packages: ${to_install[*]}"
    return 0
}

# Clone git repository with automatic cleanup on failure
# Usage: util_git_clone_safe "repo_url" "dest_dir" "description"
util_git_clone_safe() {
    local repo_url="$1"
    local dest_dir="$2"
    local description="${3:-repository}"
    
    if [[ -d "$dest_dir" ]]; then
        log_info "$description already cloned at $dest_dir"
        return 0
    fi
    
    log_info "Cloning $description..."
    
    # Set up cleanup trap
    local cleanup_needed=true
    trap 'if [[ "$cleanup_needed" == "true" ]] && [[ -d "$dest_dir" ]]; then rm -rf "$dest_dir"; fi' RETURN
    
    if ! util_git_clone "$repo_url" "$dest_dir"; then
        log_error "Failed to clone $description"
        return 1
    fi
    
    cleanup_needed=false  # Success, don't cleanup
    log_success "Cloned $description to $dest_dir"
    return 0
}

# Run command with progress and capture output
# Usage: util_run_with_progress "description" command args...
util_run_with_progress() {
    local description="$1"
    shift
    local cmd=("$@")
    
    log_info "$description..."
    
    local temp_log
    temp_log=$(util_create_temp_file)
    
    if ui_stream_command "$description" "${cmd[@]}" > "$temp_log" 2>&1; then
        log_success "$description completed"
        util_cleanup_single_temp "$temp_log"
        return 0
    else
        log_error "$description failed"
        log_debug "Last 10 lines of output:"
        tail -n 10 "$temp_log" | while IFS= read -r line; do
            log_debug "  $line"
        done
        util_cleanup_single_temp "$temp_log"
        return 1
    fi
}

# Download file with retry and progress
# Usage: util_download_with_retry "url" "output_path" "description" [max_retries]
util_download_with_retry() {
    local url="$1"
    local output="$2"
    local description="$3"
    local max_retries="${4:-3}"
    
    for ((attempt=1; attempt<=max_retries; attempt++)); do
        if [[ $attempt -gt 1 ]]; then
            log_warning "Retry attempt $attempt/$max_retries for $description"
            sleep 2
        fi
        
        if util_download "$url" "$output" "$description"; then
            log_success "Downloaded $description"
            return 0
        fi
        
        if [[ $attempt -lt $max_retries ]]; then
            log_warning "Download failed, retrying..."
        fi
    done
    
    log_error "Failed to download $description after $max_retries attempts"
    return 1
}

# Extract common progress bar pattern
# Usage: util_for_each_with_progress "description" callback_func "${array[@]}"
util_for_each_with_progress() {
    local description="$1"
    local callback="$2"
    shift 2
    local items=("$@")
    
    local total=${#items[@]}
    local current=0
    local failed=()
    
    for item in "${items[@]}"; do
        ((current++))
        ui_progress_bar "$current" "$total" "$description: $item"
        
        if ! "$callback" "$item"; then
            failed+=("$item")
            log_warning "Failed: $item"
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_warning "Failed items ($description): ${failed[*]}"
        return 1
    fi
    
    log_success "Completed: $description"
    return 0
}
