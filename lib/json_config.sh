#!/bin/bash
# ==============================================================================
# JSON Configuration Loader Module
# ==============================================================================
# Purpose: Load and parse JSON configuration files for tool installation
# Requires: jq (JSON processor)
# ==============================================================================

# Configuration file paths
readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly DEFAULT_CONFIG_FILE="${CONFIG_DIR}/tools.json"
readonly USER_CONFIG_FILE="${HOME}/.security-tools/config.json"
readonly LOCAL_CONFIG_FILE="${SCRIPT_DIR}/local.json"

# Loaded configuration (cached)
declare -A JSON_CONFIG_CACHE=()
JSON_CONFIG_LOADED=false

# ==============================================================================
# Configuration Loading
# ==============================================================================

# Check if jq is available
json_config_check_jq() {
    if ! command -v jq &>/dev/null; then
        log_warning "jq is not installed. JSON configuration will be limited."
        log_info "Install jq: sudo apt-get install jq"
        return 1
    fi
    return 0
}

# Load JSON configuration file
# Usage: json_config_load [config_file]
json_config_load() {
    local config_file="${1:-$DEFAULT_CONFIG_FILE}"
    
    if ! json_config_check_jq; then
        return 1
    fi
    
    if [[ ! -f "$config_file" ]]; then
        log_debug "Configuration file not found: $config_file"
        return 1
    fi
    
    # Validate JSON syntax
    if ! jq empty "$config_file" 2>/dev/null; then
        log_error "Invalid JSON in configuration file: $config_file"
        return 1
    fi
    
    log_info "Loading configuration from: $config_file"
    
    # Store file path in cache
    JSON_CONFIG_CACHE["_file"]="$config_file"
    JSON_CONFIG_LOADED=true
    
    log_success "Configuration loaded successfully"
    return 0
}

# Load configuration with priority: local > user > default
json_config_load_with_priority() {
    local loaded=false
    
    # Try local config first (project-specific overrides)
    if [[ -f "$LOCAL_CONFIG_FILE" ]]; then
        if json_config_load "$LOCAL_CONFIG_FILE"; then
            log_info "Using local configuration"
            loaded=true
        fi
    fi
    
    # Try user config (user-specific preferences)
    if [[ "$loaded" == "false" ]] && [[ -f "$USER_CONFIG_FILE" ]]; then
        if json_config_load "$USER_CONFIG_FILE"; then
            log_info "Using user configuration"
            loaded=true
        fi
    fi
    
    # Fall back to default config
    if [[ "$loaded" == "false" ]] && [[ -f "$DEFAULT_CONFIG_FILE" ]]; then
        if json_config_load "$DEFAULT_CONFIG_FILE"; then
            log_info "Using default configuration"
            loaded=true
        fi
    fi
    
    return $([[ "$loaded" == "true" ]] && echo 0 || echo 1)
}

# ==============================================================================
# Configuration Query Functions
# ==============================================================================

# Get value from config using jq path
# Usage: json_config_get ".settings.parallel_jobs"
json_config_get() {
    local path="$1"
    local default="${2:-}"
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        echo "$default"
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    local value
    
    value=$(jq -r "$path // empty" "$config_file" 2>/dev/null)
    
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "$default"
        return 1
    fi
    
    echo "$value"
    return 0
}

# Get boolean value from config
# Usage: json_config_get_bool ".settings.go_tools_parallel" "false"
json_config_get_bool() {
    local path="$1"
    local default="${2:-false}"
    
    local value
    value=$(json_config_get "$path" "$default")
    
    if [[ "$value" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Get array from config
# Usage: json_config_get_array ".categories.go_tools.tools | keys" tools_array
json_config_get_array() {
    local path="$1"
    local -n result_array=$2
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    mapfile -t result_array < <(jq -r "$path | .[]" "$config_file" 2>/dev/null)
    
    return 0
}

# Check if category is enabled
# Usage: json_config_category_enabled "go_tools"
json_config_category_enabled() {
    local category="$1"
    json_config_get_bool ".categories.${category}.enabled" "true"
}

# Check if tool is enabled
# Usage: json_config_tool_enabled "go_tools" "nuclei"
json_config_tool_enabled() {
    local category="$1"
    local tool="$2"
    
    # Check if category is enabled first
    if ! json_config_category_enabled "$category"; then
        return 1
    fi
    
    # Check if tool is enabled
    json_config_get_bool ".categories.${category}.tools.${tool}.enabled" "true"
}

# ==============================================================================
# Tool Configuration Helpers
# ==============================================================================

# Get all enabled Go tools from config
json_config_get_go_tools() {
    local -n tools_ref=$1
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    # Get all enabled Go tools with their packages
    while IFS='|' read -r name package description; do
        if [[ -n "$name" && -n "$package" ]]; then
            tools_ref["$name"]="${package}|${description}"
        fi
    done < <(jq -r '
        .categories.go_tools.tools // {} |
        to_entries[] |
        select(.value.enabled == true) |
        "\(.key)|\(.value.package)|\(.value.description // "")"
    ' "$config_file" 2>/dev/null)
    
    return 0
}

# Get all enabled Python tools from config
json_config_get_python_tools() {
    local -n tools_ref=$1
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    while IFS='|' read -r name repo desc reqs script; do
        if [[ -n "$name" && -n "$repo" ]]; then
            tools_ref["$name"]="git|${repo}|${desc}|${reqs}|${script}"
        fi
    done < <(jq -r '
        .categories.python_tools.tools // {} |
        to_entries[] |
        select(.value.enabled == true) |
        "\(.key)|\(.value.repository)|\(.value.description // "")|\(.value.requirements // "")|\(.value.install_script // "")"
    ' "$config_file" 2>/dev/null)
    
    return 0
}

# Get all enabled wordlists from config
json_config_get_wordlists() {
    local -n wordlists_ref=$1
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    while IFS='|' read -r name type url target; do
        if [[ -n "$name" ]]; then
            wordlists_ref["$name"]="${url}|${type}|${target}"
        fi
    done < <(jq -r '
        .categories.wordlists.tools // {} |
        to_entries[] |
        select(.value.enabled == true) |
        "\(.key)|\(.value.type)|\(.value.url // .value.repository)|\(.value.target_name // .value.target_path)"
    ' "$config_file" 2>/dev/null)
    
    return 0
}

# Get enabled APT packages from config
json_config_get_apt_packages() {
    local -n packages_ref=$1
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    while IFS='|' read -r name desc; do
        if [[ -n "$name" ]]; then
            packages_ref["$name"]="${name}|${desc}"
        fi
    done < <(jq -r '
        .categories.apt_tools.packages // {} |
        to_entries[] |
        select(.value.enabled == true) |
        "\(.key)|\(.value.description // "")"
    ' "$config_file" 2>/dev/null)
    
    return 0
}

# Get enabled Rust tools from config
json_config_get_rust_tools() {
    local -n tools_ref=$1
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    while IFS='|' read -r name crate desc; do
        if [[ -n "$name" ]]; then
            tools_ref["$name"]="cargo|${crate}|${desc}"
        fi
    done < <(jq -r '
        .categories.rust_tools.tools // {} |
        to_entries[] |
        select(.value.enabled == true) |
        "\(.key)|\(.value.crate)|\(.value.description // "")"
    ' "$config_file" 2>/dev/null)
    
    return 0
}

# Get enabled Snap tools from config
json_config_get_snap_tools() {
    local -n tools_ref=$1
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    while IFS='|' read -r name desc; do
        if [[ -n "$name" ]]; then
            tools_ref["$name"]="${name}|${desc}"
        fi
    done < <(jq -r '
        .categories.snap_tools.packages // {} |
        to_entries[] |
        select(.value.enabled == true) |
        "\(.key)|\(.value.description // "")"
    ' "$config_file" 2>/dev/null)
    
    return 0
}

# Get enabled Pipx tools from config
json_config_get_pipx_tools() {
    local -n tools_ref=$1
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    while IFS='|' read -r name desc; do
        if [[ -n "$name" ]]; then
            tools_ref["$name"]="${name}|${desc}"
        fi
    done < <(jq -r '
        .categories.pipx_tools.packages // {} |
        to_entries[] |
        select(.value.enabled == true) |
        "\(.key)|\(.value.description // "")"
    ' "$config_file" 2>/dev/null)
    
    return 0
}


# ==============================================================================
# Profile Handling
# ==============================================================================

# Get profile configuration
# Usage: json_config_get_profile "minimal"
json_config_get_profile() {
    local profile_name="$1"
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    jq -r ".profiles.${profile_name} // empty" "$config_file" 2>/dev/null
}

# Check if profile exists
json_config_profile_exists() {
    local profile_name="$1"
    
    local profile
    profile=$(json_config_get_profile "$profile_name")
    
    [[ -n "$profile" && "$profile" != "null" ]]
}

# Get enabled categories for a profile
json_config_profile_categories() {
    local profile_name="$1"
    local -n categories_ref=$2
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    mapfile -t categories_ref < <(jq -r "
        .profiles.${profile_name}.enabled_categories // [] | .[]
    " "$config_file" 2>/dev/null)
    
    return 0
}

# Get enabled tools for a profile
json_config_profile_tools() {
    local profile_name="$1"
    local -n tools_ref=$2
    
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    mapfile -t tools_ref < <(jq -r "
        .profiles.${profile_name}.enabled_tools // [] | .[]
    " "$config_file" 2>/dev/null)
    
    return 0
}

# ==============================================================================
# Settings Helpers
# ==============================================================================

# Apply JSON config settings to global variables
json_config_apply_settings() {
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        return 1
    fi
    
    log_info "Applying configuration settings..."
    
    # Log level
    local log_level
    log_level=$(json_config_get ".settings.log_level" "INFO")
    if [[ -n "$log_level" ]]; then
        LOG_LEVEL="$log_level"
        log_debug "Set LOG_LEVEL=$log_level"
    fi
    
    # Parallel jobs
    local parallel_jobs
    parallel_jobs=$(json_config_get ".settings.parallel_jobs" "4")
    if [[ -n "$parallel_jobs" ]]; then
        PARALLEL_JOBS="$parallel_jobs"
        log_debug "Set PARALLEL_JOBS=$parallel_jobs"
    fi
    
    # Go tools parallel
    if json_config_get_bool ".settings.go_tools_parallel" "true"; then
        GO_TOOLS_PARALLEL="true"
        log_debug "Enabled GO_TOOLS_PARALLEL"
    fi
    
    # Skip confirmations
    if json_config_get_bool ".settings.skip_confirmations" "false"; then
        FORCE="true"
        log_debug "Enabled skip confirmations (FORCE=true)"
    fi
    
    log_success "Configuration settings applied"
    return 0
}

# ==============================================================================
# Configuration Validation
# ==============================================================================

# Validate configuration file
json_config_validate() {
    local config_file="${1:-$DEFAULT_CONFIG_FILE}"
    
    if ! json_config_check_jq; then
        return 1
    fi
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    log_info "Validating configuration: $config_file"
    
    # Check JSON syntax
    if ! jq empty "$config_file" 2>/dev/null; then
        log_error "Invalid JSON syntax"
        return 1
    fi
    
    # Check required fields
    local version
    version=$(jq -r '.version // empty' "$config_file")
    if [[ -z "$version" ]]; then
        log_error "Missing required field: version"
        return 1
    fi
    
    local categories
    categories=$(jq -r '.categories // empty' "$config_file")
    if [[ -z "$categories" ]]; then
        log_error "Missing required field: categories"
        return 1
    fi
    
    # Validate Go tool packages
    local invalid_tools=()
    while IFS= read -r tool; do
        local package
        package=$(jq -r ".categories.go_tools.tools.${tool}.package // empty" "$config_file")
        if [[ -n "$package" ]] && [[ ! "$package" =~ ^github\.com/ ]]; then
            invalid_tools+=("$tool")
        fi
    done < <(jq -r '.categories.go_tools.tools // {} | keys[]' "$config_file" 2>/dev/null)
    
    if [[ ${#invalid_tools[@]} -gt 0 ]]; then
        log_warning "Invalid Go package paths: ${invalid_tools[*]}"
    fi
    
    log_success "Configuration validation passed"
    return 0
}

# ==============================================================================
# Configuration Display
# ==============================================================================

# Show configuration summary
json_config_show_summary() {
    if [[ "$JSON_CONFIG_LOADED" != "true" ]]; then
        log_error "No configuration loaded"
        return 1
    fi
    
    local config_file="${JSON_CONFIG_CACHE["_file"]}"
    
    echo
    echo -e "${CYAN}╭─ Configuration Summary ────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} File: ${GREEN}$config_file${NC}"
    echo -e "${CYAN}│${NC} Version: ${GREEN}$(json_config_get ".version")${NC}"
    echo -e "${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}Enabled Categories:${NC}"
    
    local categories
    mapfile -t categories < <(jq -r '.categories | to_entries[] | select(.value.enabled == true) | .key' "$config_file" 2>/dev/null)
    
    for cat in "${categories[@]}"; do
        local tool_count
        tool_count=$(jq -r ".categories.${cat}.tools // {} | to_entries | map(select(.value.enabled == true)) | length" "$config_file" 2>/dev/null)
        local pkg_count
        pkg_count=$(jq -r ".categories.${cat}.packages // {} | to_entries | map(select(.value.enabled == true)) | length" "$config_file" 2>/dev/null)
        
        local count=$((tool_count + pkg_count))
        echo -e "${CYAN}│${NC}   ${GREEN}✓${NC} ${cat} (${count} items)"
    done
    
    echo -e "${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}Available Profiles:${NC}"
    
    local profiles
    mapfile -t profiles < <(jq -r '.profiles | keys[]' "$config_file" 2>/dev/null)
    
    for profile in "${profiles[@]}"; do
        local desc
        desc=$(jq -r ".profiles.${profile}.description // \"\"" "$config_file")
        echo -e "${CYAN}│${NC}   ${BLUE}•${NC} ${profile}: ${desc}"
    done
    
    echo -e "${CYAN}│${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────────────╯${NC}"
    echo
}

# ==============================================================================
# Initialization
# ==============================================================================

# Initialize JSON configuration system
json_config_init() {
    log_info "Initializing JSON configuration system..."
    
    # Check for jq
    if ! json_config_check_jq; then
        log_warning "JSON configuration disabled (jq not available)"
        return 1
    fi
    
    # Load configuration with priority
    if ! json_config_load_with_priority; then
        log_warning "No configuration file found, using built-in defaults"
        return 1
    fi
    
    # Apply settings
    json_config_apply_settings
    
    return 0
}
