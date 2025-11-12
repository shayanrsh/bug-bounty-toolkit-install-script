#!/bin/bash
# ==============================================================================
# Consolidated State Management System
# ==============================================================================
# Manages all installation state in a single unified JSON file
# Replaces manifest.json and individual .state files
# ==============================================================================

readonly STATE_FILE="${STATE_DIR}/installation-state.json"

# ==============================================================================
# State Structure
# ==============================================================================
# {
#   "version": "1.0",
#   "metadata": {
#     "installer_version": "3.0.0",
#     "installation_date": "2025-11-12T10:30:00Z",
#     "last_update": "2025-11-12T15:45:00Z",
#     "hostname": "localhost",
#     "os": "Ubuntu 22.04",
#     "mode": "full"
#   },
#   "steps": {
#     "tool_install_zsh": {
#       "status": "completed",
#       "started": "2025-11-12T10:31:00Z",
#       "completed": "2025-11-12T10:33:00Z",
#       "duration": 120,
#       "exit_code": 0
#     }
#   },
#   "tools": {
#     "zsh": {
#       "category": "languages",
#       "version": "5.9",
#       "path": "/usr/bin/zsh",
#       "installed_at": "2025-11-12T10:33:00Z",
#       "verified": true
#     }
#   },
#   "configuration": {
#     "parallel_jobs": 4,
#     "go_tools_parallel": true
#   },
#   "errors": []
# }
# ==============================================================================

# Initialize state file with default structure
state_init() {
    mkdir -p "$STATE_DIR"
    
    if [[ -f "$STATE_FILE" ]]; then
        log_debug "State file already exists: $STATE_FILE"
        return 0
    fi
    
    log_info "Initializing state file..."
    
    cat > "$STATE_FILE" << EOF
{
  "version": "1.0",
  "metadata": {
    "installer_version": "$SCRIPT_VERSION",
    "installation_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "last_update": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "hostname": "$(hostname)",
    "os": "$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")",
    "mode": ""
  },
  "steps": {},
  "tools": {},
  "configuration": {},
  "errors": []
}
EOF
    
    log_success "State file initialized: $STATE_FILE"
}

# Update metadata
state_set_metadata() {
    local key="$1"
    local value="$2"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        state_init
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    jq ".metadata.$key = \"$value\"" "$STATE_FILE" > "$temp_file"
    mv "$temp_file" "$STATE_FILE"
    
    state_update_timestamp
}

# Update last modified timestamp
state_update_timestamp() {
    if [[ ! -f "$STATE_FILE" ]]; then
        return 1
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    jq ".metadata.last_update = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$STATE_FILE" > "$temp_file"
    mv "$temp_file" "$STATE_FILE"
}

# Set step status
state_set_step() {
    local step_id="$1"
    local status="$2"  # pending, running, completed, failed
    
    if [[ ! -f "$STATE_FILE" ]]; then
        state_init
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    case "$status" in
        running)
            jq ".steps[\"$step_id\"].status = \"running\" | \
                .steps[\"$step_id\"].started = \"$timestamp\"" \
                "$STATE_FILE" > "$temp_file"
            ;;
        completed)
            local started
            started=$(jq -r ".steps[\"$step_id\"].started // \"$timestamp\"" "$STATE_FILE")
            local duration
            duration=$(( $(date -d "$timestamp" +%s) - $(date -d "$started" +%s) ))
            
            jq ".steps[\"$step_id\"].status = \"completed\" | \
                .steps[\"$step_id\"].completed = \"$timestamp\" | \
                .steps[\"$step_id\"].duration = $duration | \
                .steps[\"$step_id\"].exit_code = 0" \
                "$STATE_FILE" > "$temp_file"
            ;;
        failed)
            local exit_code="${3:-1}"
            jq ".steps[\"$step_id\"].status = \"failed\" | \
                .steps[\"$step_id\"].completed = \"$timestamp\" | \
                .steps[\"$step_id\"].exit_code = $exit_code" \
                "$STATE_FILE" > "$temp_file"
            ;;
        *)
            jq ".steps[\"$step_id\"].status = \"$status\"" \
                "$STATE_FILE" > "$temp_file"
            ;;
    esac
    
    mv "$temp_file" "$STATE_FILE"
    state_update_timestamp
}

# Get step status
state_get_step() {
    local step_id="$1"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "not_found"
        return 1
    fi
    
    jq -r ".steps[\"$step_id\"].status // \"not_found\"" "$STATE_FILE"
}

# Add tool to state
state_add_tool() {
    local tool_name="$1"
    local category="$2"
    local version="$3"
    local path="$4"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        state_init
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq ".tools[\"$tool_name\"] = {
        \"category\": \"$category\",
        \"version\": \"$version\",
        \"path\": \"$path\",
        \"installed_at\": \"$timestamp\",
        \"verified\": false
    }" "$STATE_FILE" > "$temp_file"
    
    mv "$temp_file" "$STATE_FILE"
    state_update_timestamp
}

# Verify tool in state
state_verify_tool() {
    local tool_name="$1"
    local verified="${2:-true}"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        return 1
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    jq ".tools[\"$tool_name\"].verified = $verified" "$STATE_FILE" > "$temp_file"
    mv "$temp_file" "$STATE_FILE"
}

# Get tool info from state
state_get_tool() {
    local tool_name="$1"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "{}"
        return 1
    fi
    
    jq ".tools[\"$tool_name\"] // {}" "$STATE_FILE"
}

# Check if tool is installed
state_is_tool_installed() {
    local tool_name="$1"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        return 1
    fi
    
    local tool_exists
    tool_exists=$(jq -r ".tools[\"$tool_name\"] // null" "$STATE_FILE")
    
    [[ "$tool_exists" != "null" ]]
}

# Add error to state
state_add_error() {
    local error_msg="$1"
    local step_id="${2:-unknown}"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        state_init
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq ".errors += [{
        \"timestamp\": \"$timestamp\",
        \"step\": \"$step_id\",
        \"message\": \"$error_msg\"
    }]" "$STATE_FILE" > "$temp_file"
    
    mv "$temp_file" "$STATE_FILE"
}

# Set configuration value
state_set_config() {
    local key="$1"
    local value="$2"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        state_init
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    jq ".configuration.$key = \"$value\"" "$STATE_FILE" > "$temp_file"
    mv "$temp_file" "$STATE_FILE"
}

# Get configuration value
state_get_config() {
    local key="$1"
    local default="${2:-}"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "$default"
        return 1
    fi
    
    jq -r ".configuration.$key // \"$default\"" "$STATE_FILE"
}

# Export state as JSON (for backup or migration)
state_export() {
    local export_file="${1:-${STATE_DIR}/state-backup-$(date +%Y%m%d-%H%M%S).json}"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        log_error "No state file to export"
        return 1
    fi
    
    cp "$STATE_FILE" "$export_file"
    log_success "State exported to: $export_file"
}

# Import state from JSON (for restoration)
state_import() {
    local import_file="$1"
    
    if [[ ! -f "$import_file" ]]; then
        log_error "Import file not found: $import_file"
        return 1
    fi
    
    # Validate JSON
    if ! jq empty "$import_file" 2>/dev/null; then
        log_error "Invalid JSON in import file"
        return 1
    fi
    
    # Backup current state
    if [[ -f "$STATE_FILE" ]]; then
        cp "$STATE_FILE" "${STATE_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    cp "$import_file" "$STATE_FILE"
    log_success "State imported from: $import_file"
}

# Get summary statistics
state_get_summary() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "No state file found"
        return 1
    fi
    
    echo "Installation State Summary"
    echo "=========================="
    echo ""
    echo "Installer Version: $(jq -r '.metadata.installer_version' "$STATE_FILE")"
    echo "Installation Date: $(jq -r '.metadata.installation_date' "$STATE_FILE")"
    echo "Last Update:       $(jq -r '.metadata.last_update' "$STATE_FILE")"
    echo "Mode:              $(jq -r '.metadata.mode' "$STATE_FILE")"
    echo ""
    echo "Steps:"
    echo "  Completed: $(jq '[.steps[] | select(.status == "completed")] | length' "$STATE_FILE")"
    echo "  Failed:    $(jq '[.steps[] | select(.status == "failed")] | length' "$STATE_FILE")"
    echo "  Running:   $(jq '[.steps[] | select(.status == "running")] | length' "$STATE_FILE")"
    echo ""
    echo "Tools:"
    echo "  Total:     $(jq '.tools | length' "$STATE_FILE")"
    echo "  Verified:  $(jq '[.tools[] | select(.verified == true)] | length' "$STATE_FILE")"
    echo ""
    echo "Errors:      $(jq '.errors | length' "$STATE_FILE")"
}

# Migrate from old manifest.json to new state system
state_migrate_from_manifest() {
    local old_manifest="${HOME}/.security-tools/manifest.json"
    
    if [[ ! -f "$old_manifest" ]]; then
        log_info "No old manifest to migrate"
        return 0
    fi
    
    log_info "Migrating from old manifest.json..."
    
    state_init
    
    # Migrate tools
    local temp_file
    temp_file=$(mktemp)
    
    jq -s '.[0] * {"tools": .[1]}' "$STATE_FILE" "$old_manifest" > "$temp_file"
    mv "$temp_file" "$STATE_FILE"
    
    # Backup old manifest
    mv "$old_manifest" "${old_manifest}.backup-$(date +%Y%m%d-%H%M%S)"
    
    log_success "Migration completed"
}

# Clean up old state files
state_cleanup_old() {
    log_info "Cleaning up old state files..."
    
    if [[ -d "$STEP_STATE_DIR" ]]; then
        rm -rf "$STEP_STATE_DIR"
        log_info "Removed old step state directory"
    fi
    
    find "$STATE_DIR" -name "*.state" -delete 2>/dev/null || true
    log_success "Cleanup completed"
}
