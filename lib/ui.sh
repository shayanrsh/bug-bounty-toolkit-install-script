#!/bin/bash
# ==============================================================================
# Security Tools Installer - UI/UX Module
# ==============================================================================
# Purpose: All user interface functions including progress bars, menus, and logging
# ==============================================================================

# shellcheck disable=SC2155

# ==============================================================================
# Logging Functions
# ==============================================================================

# Initialize logging
ui_log_init() {
    mkdir -p "$(dirname "$LOG_FILE")"
    {
        echo "======================================================================"
        echo "$SCRIPT_NAME v$SCRIPT_VERSION"
        echo "======================================================================"
        echo "Started: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
        echo "User: $(whoami)"
        echo "Home: $HOME"
        echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Unknown')"
        echo "Kernel: $(uname -r)"
        echo "Log Level: ${LOG_LEVEL:-INFO}"
        echo "======================================================================"
    } > "$LOG_FILE"
}

# Logging levels: TRACE=0, DEBUG=1, INFO=2, WARNING=3, ERROR=4
declare -A LOG_LEVELS=([TRACE]=0 [DEBUG]=1 [INFO]=2 [WARNING]=3 [ERROR]=4)
LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Check if message should be logged based on level
_should_log() {
    local msg_level="$1"
    local current_level="${LOG_LEVELS[$LOG_LEVEL]:-2}"
    local message_level="${LOG_LEVELS[$msg_level]:-2}"
    
    [[ $message_level -ge $current_level ]]
}

# Generic log message function
_log_message() {
    local level="$1"
    local color="$2"
    local icon="$3"
    local message="$4"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if we should log this level
    if ! _should_log "$level"; then
        return 0
    fi
    
    # Console output (colored)
    if [[ "$VERBOSE" == "true" ]] || [[ "$level" != "DEBUG" && "$level" != "TRACE" ]]; then
        echo -e "${color}${icon} [${level}] ${timestamp}${NC} ${message}"
    fi
    
    # File output (plain text)
    echo "[${level}] ${timestamp} ${message}" >> "$LOG_FILE"
}

log_trace()   { _log_message "TRACE"   "$GRAY"   "→"             "$1"; }
log_debug()   { _log_message "DEBUG"   "$PURPLE" "$ICON_DEBUG"   "$1"; }
log_info()    { _log_message "INFO"    "$BLUE"   "$ICON_INFO"    "$1"; }
log_success() { _log_message "SUCCESS" "$GREEN"  "$ICON_SUCCESS" "$1"; }
log_warning() { _log_message "WARNING" "$YELLOW" "$ICON_WARNING" "$1"; }
log_error()   { _log_message "ERROR"   "$RED"    "$ICON_ERROR"   "$1"; }

# ==============================================================================
# Progress Indicators
# ==============================================================================

# Draw progress bar
ui_progress_bar() {
    local current="$1"
    local total="$2"
    local message="${3:-Processing}"
    
    # Safety checks for division by zero
    local safe_total=$((total > 0 ? total : 1))
    local safe_current=$((current > safe_total ? safe_total : current))
    ((safe_current < 0)) && safe_current=0
    
    local percentage=$((safe_current * 100 / safe_total))
    local filled_width=$((safe_current * PROGRESS_BAR_WIDTH / safe_total))
    ((filled_width > PROGRESS_BAR_WIDTH)) && filled_width=$PROGRESS_BAR_WIDTH
    ((filled_width < 0)) && filled_width=0
    local empty_width=$((PROGRESS_BAR_WIDTH - filled_width))
    ((empty_width < 0)) && empty_width=0
    
    # Color coding based on percentage
    local bar_color="$RED"
    [[ $percentage -ge 75 ]] && bar_color="$GREEN"
    [[ $percentage -ge 50 && $percentage -lt 75 ]] && bar_color="$YELLOW"
    [[ $percentage -ge 25 && $percentage -lt 50 ]] && bar_color="$BLUE"
    
    # Create bars
    local filled_bar=""
    local empty_bar=""
    if ((filled_width > 0)); then
        filled_bar=$(printf "█%.0s" $(seq 1 "$filled_width" 2>/dev/null))
    fi
    if ((empty_width > 0)); then
        empty_bar=$(printf "░%.0s" $(seq 1 "$empty_width" 2>/dev/null))
    fi
    
    # Display progress - clear line first, then show new progress
    printf "\r\033[K${CYAN}[${bar_color}%s${CYAN}%s] %3d%% (%d/%d)${NC} %s" \
           "$filled_bar" "$empty_bar" "$percentage" "$safe_current" "$total" "$message"
}

# Enhanced progress bar with spinner for active installations
ui_progress_with_spinner() {
    local current="$1"
    local total="$2"
    local message="${3:-Processing}"
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local spinner_index=$((RANDOM % ${#spinner_chars}))
    local spinner_char="${spinner_chars:$spinner_index:1}"
    
    local percentage=$((current * 100 / total))
    local filled_width=$((current * PROGRESS_BAR_WIDTH / total))
    local empty_width=$((PROGRESS_BAR_WIDTH - filled_width))
    
    local bar_color="$RED"
    [[ $percentage -ge 75 ]] && bar_color="$GREEN"
    [[ $percentage -ge 50 && $percentage -lt 75 ]] && bar_color="$YELLOW"
    [[ $percentage -ge 25 && $percentage -lt 50 ]] && bar_color="$BLUE"
    
    local filled_bar=$(printf "█%.0s" $(seq 1 "$filled_width" 2>/dev/null))
    local empty_bar=$(printf "░%.0s" $(seq 1 "$empty_width" 2>/dev/null))
    
    printf "\r\033[K${CYAN}[${bar_color}%s${CYAN}%s] %3d%% (%d/%d)${NC} ${YELLOW}%s${NC} %s" \
           "$filled_bar" "$empty_bar" "$percentage" "$current" "$total" "$spinner_char" "$message"
}

# Render live progress line with animated pulse for the active task
ui_draw_live_progress() {
    local step_index="$1"
    local total="$2"
    local tick="$3"
    local spinner_char="$4"
    local message="$5"
    local status_text="${6:-}"

    local safe_total=$(( total > 0 ? total : 1 ))
    local completed_steps=$((step_index - 1))
    ((completed_steps < 0)) && completed_steps=0
    ((completed_steps > safe_total)) && completed_steps=safe_total

    local filled_width=$((completed_steps * PROGRESS_BAR_WIDTH / safe_total))
    ((filled_width > PROGRESS_BAR_WIDTH)) && filled_width=$PROGRESS_BAR_WIDTH

    local unit_width=$((PROGRESS_BAR_WIDTH / safe_total))
    ((unit_width < 1)) && unit_width=1

    local available=$((PROGRESS_BAR_WIDTH - filled_width))
    local pulse_width=0
    if ((available > 0)); then
        pulse_width=$(( (tick % unit_width) + 1 ))
        ((pulse_width > available)) && pulse_width=$available
    fi

    local empty_width=$((PROGRESS_BAR_WIDTH - filled_width - pulse_width))
    ((empty_width < 0)) && empty_width=0

    local filled_bar=""
    if ((filled_width > 0)); then
        printf -v filled_bar "%*s" "$filled_width" ""
        filled_bar=${filled_bar// /█}
    fi

    local pulse_bar=""
    if ((pulse_width > 0)); then
        printf -v pulse_bar "%*s" "$pulse_width" ""
        pulse_bar=${pulse_bar// /▒}
    fi

    local empty_bar=""
    if ((empty_width > 0)); then
        printf -v empty_bar "%*s" "$empty_width" ""
        empty_bar=${empty_bar// /░}
    fi

    local percentage=$(( (filled_width + pulse_width) * 100 / PROGRESS_BAR_WIDTH ))
    if ((percentage > 99)) && ((completed_steps < safe_total)); then
        percentage=99
    fi

    local bar_color="$RED"
    [[ $percentage -ge 75 ]] && bar_color="$GREEN"
    [[ $percentage -ge 50 && $percentage -lt 75 ]] && bar_color="$YELLOW"
    [[ $percentage -ge 25 && $percentage -lt 50 ]] && bar_color="$BLUE"

    printf "\r\033[K${CYAN}[${bar_color}%s${YELLOW}%s${CYAN}%s${NC}] %3d%% (%d/%d) ${YELLOW}%s${NC} %s%s" \
        "$filled_bar" "$pulse_bar" "$empty_bar" "$percentage" "$step_index" "$safe_total" "$spinner_char" "$message" "$status_text"
}

# Nested progress bar - shows parent and child progress
# Usage: ui_progress_nested "parent_text" parent_current parent_total "child_text" child_current child_total
ui_progress_nested() {
    local parent_text="$1"
    local parent_current="$2"
    local parent_total="$3"
    local child_text="$4"
    local child_current="$5"
    local child_total="$6"
    
    # Calculate percentages
    local safe_parent_total=$((parent_total > 0 ? parent_total : 1))
    local safe_child_total=$((child_total > 0 ? child_total : 1))
    
    local parent_pct=$((parent_current * 100 / safe_parent_total))
    local child_pct=$((child_current * 100 / safe_child_total))
    
    # Parent progress bar (abbreviated)
    local parent_width=30
    local parent_filled=$((parent_current * parent_width / safe_parent_total))
    ((parent_filled > parent_width)) && parent_filled=$parent_width
    local parent_empty=$((parent_width - parent_filled))
    
    local parent_bar=""
    ((parent_filled > 0)) && parent_bar=$(printf "█%.0s" $(seq 1 "$parent_filled" 2>/dev/null))
    local parent_empty_bar=""
    ((parent_empty > 0)) && parent_empty_bar=$(printf "░%.0s" $(seq 1 "$parent_empty" 2>/dev/null))
    
    # Child progress bar (full width)
    local child_width=$PROGRESS_BAR_WIDTH
    local child_filled=$((child_current * child_width / safe_child_total))
    ((child_filled > child_width)) && child_filled=$child_width
    local child_empty=$((child_width - child_filled))
    
    local child_bar=""
    ((child_filled > 0)) && child_bar=$(printf "█%.0s" $(seq 1 "$child_filled" 2>/dev/null))
    local child_empty_bar=""
    ((child_empty > 0)) && child_empty_bar=$(printf "░%.0s" $(seq 1 "$child_empty" 2>/dev/null))
    
    # Color based on progress
    local child_color="$RED"
    [[ $child_pct -ge 75 ]] && child_color="$GREEN"
    [[ $child_pct -ge 50 && $child_pct -lt 75 ]] && child_color="$YELLOW"
    [[ $child_pct -ge 25 && $child_pct -lt 50 ]] && child_color="$BLUE"
    
    # Display nested progress
    # Line 1: Parent progress
    printf "\r\033[K${GRAY}[${GREEN}%s${GRAY}%s] %3d%% %s${NC}\n" \
           "$parent_bar" "$parent_empty_bar" "$parent_pct" "$parent_text"
    
    # Line 2: Child progress with indentation
    printf "\r\033[K  ${CYAN}└─[${child_color}%s${CYAN}%s] %3d%% (%d/%d)${NC} %s" \
           "$child_bar" "$child_empty_bar" "$child_pct" "$child_current" "$child_total" "$child_text"
    
    # Move cursor up 1 line for next update
    printf "\033[1A"
}

# Clear nested progress (move down and clear both lines)
ui_progress_nested_clear() {
    printf "\033[1B"  # Move down
    printf "\r\033[K\n\033[K"  # Clear both lines
}

# Finalise progress output for a completed or failed task
ui_progress_finalize() {
    local step_index="$1"
    local total="$2"
    local completed_steps="$3"
    local icon="$4"
    local color="$5"
    local message="$6"
    local status_text="${7:-}"

    local safe_total=$(( total > 0 ? total : 1 ))
    ((completed_steps < 0)) && completed_steps=0
    ((completed_steps > safe_total)) && completed_steps=safe_total

    local filled_width=$((completed_steps * PROGRESS_BAR_WIDTH / safe_total))
    ((filled_width > PROGRESS_BAR_WIDTH)) && filled_width=$PROGRESS_BAR_WIDTH
    local empty_width=$((PROGRESS_BAR_WIDTH - filled_width))
    ((empty_width < 0)) && empty_width=0

    local filled_bar=""
    if ((filled_width > 0)); then
        printf -v filled_bar "%*s" "$filled_width" ""
        filled_bar=${filled_bar// /█}
    fi

    local empty_bar=""
    if ((empty_width > 0)); then
        printf -v empty_bar "%*s" "$empty_width" ""
        empty_bar=${empty_bar// /░}
    fi

    local percentage=$((completed_steps * 100 / safe_total))

    printf "\r\033[K${CYAN}[${color}%s${CYAN}%s${NC}] %3d%% (%d/%d) ${color}%s${NC} %s%s\n" \
        "$filled_bar" "$empty_bar" "$percentage" "$step_index" "$safe_total" "$icon" "$message" "$status_text"
}

# Execute a command while rendering a live progress indicator
ui_run_with_live_progress() {
    local step_index="$1"
    local total="$2"
    local message="$3"
    shift 3
    local command=("$@")

    if [[ ${#command[@]} -eq 0 ]]; then
        log_error "ui_run_with_live_progress called without a command"
        return 1
    fi

    local safe_total=$(( total > 0 ? total : 1 ))
    local temp_log
    temp_log=$(mktemp -t security-tools-XXXXXX)
    local start_time=$(date +%s)

    if command -v stdbuf &>/dev/null; then
        stdbuf -oL -eL "${command[@]}" >"$temp_log" 2>&1 &
    else
        "${command[@]}" >"$temp_log" 2>&1 &
    fi

    local pid=$!
    local tick=0
    local spinner_length=${#SPINNER_CHARS}

    while kill -0 "$pid" 2>/dev/null; do
        local spinner_char="${SPINNER_CHARS:$((tick % spinner_length)):1}"
        local elapsed=$(( $(date +%s) - start_time ))
        local last_line=""
        if [[ -s "$temp_log" ]]; then
            last_line=$(tail -n1 "$temp_log" | tr -d '\r')
            last_line=${last_line//$'\t'/ }
            last_line=$(printf "%.48s" "$last_line")
            [[ -n "$last_line" ]] && last_line=" ${DIM}| ${last_line}${NC}"
        fi
        local status_text=" ${DIM}[${elapsed}s]${NC}${last_line}"
        ui_draw_live_progress "$step_index" "$safe_total" "$tick" "$spinner_char" "$message" "$status_text"
        tick=$((tick + 1))
        sleep 0.15
    done

    wait "$pid"
    local exit_code=$?
    local elapsed_total=$(( $(date +%s) - start_time ))
    cat "$temp_log" >> "$LOG_FILE"

    if [[ $exit_code -eq 0 ]]; then
        ui_progress_finalize "$step_index" "$safe_total" "$step_index" "$ICON_SUCCESS" "$GREEN" "$message" " ${DIM}[${elapsed_total}s]${NC}"
    else
        ui_progress_finalize "$step_index" "$safe_total" $((step_index - 1)) "$ICON_ERROR" "$RED" "$message" " ${DIM}[${elapsed_total}s]${NC}"
        if [[ -s "$temp_log" ]]; then
            echo -e "${YELLOW}─ Last 10 lines ─${NC}"
            tail -n 10 "$temp_log"
        fi
    fi

    rm -f "$temp_log"
    return $exit_code
}

ui_stream_command() {
    local message="$1"
    shift

    if [[ $# -eq 0 ]]; then
        log_error "ui_stream_command called without a command"
        return 1
    fi

    ui_run_with_live_progress 1 1 "$message" "$@"
}

# Spinner for background operations
ui_spinner() {
    local pid=$1
    local message="${2:-Processing}"
    local spinner_index=0
    
    echo -ne "\n"
    while kill -0 "$pid" 2>/dev/null; do
        local spinner_char="${SPINNER_CHARS:$spinner_index:1}"
        printf "\r${YELLOW}%s${NC} %s" "$spinner_char" "$message"
        spinner_index=$(( (spinner_index + 1) % ${#SPINNER_CHARS} ))
        sleep 0.1
    done
    
    # Check exit status
    wait "$pid"
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        printf "\r${GREEN}✓${NC} %s\n" "$message"
    else
        printf "\r${RED}✗${NC} %s (failed with code %d)\n" "$message" "$exit_code"
    fi
    return $exit_code
}

# Execute command with progress feedback
ui_exec_with_progress() {
    local message="$1"
    shift
    local command=("$@")
    
    log_info "$message"
    printf "${YELLOW}⠿${NC} %s " "$message"
    
    # Execute command and capture output
    local output
    local exit_code
    if output=$("${command[@]}" 2>&1); then
        exit_code=0
        printf "\r${GREEN}✓${NC} %s\n" "$message"
    else
        exit_code=$?
        printf "\r${RED}✗${NC} %s (exit code: %d)\n" "$message" "$exit_code"
        if [[ -n "$output" ]]; then
            log_error "Command output:"
            echo "$output" | tee -a "$LOG_FILE" >&2
        fi
    fi
    
    # Log output
    echo "$output" >> "$LOG_FILE"
    
    return $exit_code
}

# Estimated time remaining
ui_eta() {
    local start_time=$1
    local current=$2
    local total=$3
    
    local elapsed=$(($(date +%s) - start_time))
    local rate=$((current > 0 ? elapsed / current : 0))
    local remaining=$((rate * (total - current)))
    
    if [[ $remaining -gt 0 ]]; then
        printf "ETA: %02d:%02d:%02d" $((remaining/3600)) $((remaining%3600/60)) $((remaining%60))
    else
        echo "Calculating..."
    fi
}

# ==============================================================================
# Box Drawing Functions
# ==============================================================================

ui_draw_box() {
    local text="$1"
    local color="${2:-$CYAN}"
    local width=$((${#text} + 4))
    
    echo -e "${color}╔$(printf "═%.0s" $(seq 1 $((width - 2))))╗${NC}"
    echo -e "${color}║ ${text} ║${NC}"
    echo -e "${color}╚$(printf "═%.0s" $(seq 1 $((width - 2))))╝${NC}"
}

ui_section_header() {
    local title="$1"
    local color="${2:-$BLUE}"
    local width=79
    local padding=$(( (width - ${#title} - 2) / 2 ))
    
    echo
    echo -e "${color}╭─$(printf "─%.0s" $(seq 1 $((width - 2))))─╮${NC}"
    printf "${color}│%*s%s%*s│${NC}\n" $padding "" "$title" $padding ""
    echo -e "${color}╰─$(printf "─%.0s" $(seq 1 $((width - 2))))─╯${NC}"
    echo
}

ui_step_header() {
    local step_num="$1"
    local total_steps="$2"
    local description="$3"
    local padding=$((75 - ${#description}))
    
    echo
    echo -e "${PURPLE}┌─ Step ${step_num}/${total_steps} $(printf "─%.0s" $(seq 1 60))┐${NC}"
    printf "${PURPLE}│ ${description}%*s│${NC}\n" "$padding" ""
    echo -e "${PURPLE}└$(printf "─%.0s" $(seq 1 78))┘${NC}"
}

# ==============================================================================
# ASCII Art and Banners
# ==============================================================================

ui_show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    ███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗           ║
║    ██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝           ║
║    ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝            ║
║    ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝             ║
║    ███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║              ║
║    ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝              ║
║                                                                              ║
║         ████████╗ ██████╗  ██████╗ ██╗     ███████╗                         ║
║         ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝                         ║
║            ██║   ██║   ██║██║   ██║██║     ███████╗                         ║
║            ██║   ██║   ██║██║   ██║██║     ╚════██║                         ║
║            ██║   ╚██████╔╝╚██████╔╝███████╗███████║                         ║
║            ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝                         ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${WHITE}                    Version $SCRIPT_VERSION - Professional Edition${NC}"
    echo -e "${GRAY}                    $SCRIPT_AUTHOR${NC}"
    echo
}

ui_show_success_banner() {
    echo
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    ███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗██╗             ║
║    ██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝██║             ║
║    ███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗██║             ║
║    ╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║╚═╝             ║
║    ███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║██╗             ║
║    ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝╚═╝             ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# ==============================================================================
# Interactive Menu System
# ==============================================================================

ui_menu_main() {
    local os_info
    os_info=$(lsb_release -d 2>/dev/null | cut -f2 | cut -c1-30 || echo "Unknown")
    local arch
    arch=$(uname -m)
    
    echo -e "${PURPLE}┌─ System Information ────────────────────────────────────────────────────┐${NC}"
    printf "${PURPLE}│ ${NC}Version: %-15s OS: %-35s ${PURPLE}│${NC}\n" "$SCRIPT_VERSION" "$os_info"
    printf "${PURPLE}│ ${NC}User: %-18s Architecture: %-28s ${PURPLE}│${NC}\n" "$(whoami)" "$arch"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    echo -e "${YELLOW}╭─ Installation Options ───────────────────────────────────────────────────╮${NC}"
    echo -e "${YELLOW}│                                                                          │${NC}"
    echo -e "${GREEN}│  1)${NC} 🚀 Full Installation (recommended)                                 ${YELLOW}│${NC}"
    echo -e "${BLUE}│  2)${NC} 🐚 ZSH + Oh My ZSH Only                                             ${YELLOW}│${NC}"
    echo -e "${PURPLE}│  3)${NC} 🔧 Security Tools Only                                             ${YELLOW}│${NC}"
    echo -e "${CYAN}│  4)${NC} ⚡ Go Tools Only                                                    ${YELLOW}│${NC}"
    echo -e "${GREEN}│  5)${NC} 🐍 Python Tools Only                                               ${YELLOW}│${NC}"
    echo -e "${BLUE}│  6)${NC} 📚 Wordlists Only                                                   ${YELLOW}│${NC}"
    echo -e "${PURPLE}│  7)${NC} 🎯 Profile-based Installation (minimal/full/pentest/developer)    ${YELLOW}│${NC}"
    echo -e "${CYAN}│  8)${NC} ⚙️  Custom Installation                                             ${YELLOW}│${NC}"
    echo -e "${GREEN}│  9)${NC} 🔄 Update Existing Tools                                           ${YELLOW}│${NC}"
    echo -e "${RED}│  10)${NC} 🗑️  Uninstall Tools                                                 ${YELLOW}│${NC}"
    echo -e "${BLUE}│  11)${NC} 🧪 Dry Run (Preview Only)                                          ${YELLOW}│${NC}"
    echo -e "${YELLOW}│  0)${NC} ❌ Exit                                                            ${YELLOW}│${NC}"
    echo -e "${YELLOW}│                                                                          │${NC}"
    echo -e "${YELLOW}╰──────────────────────────────────────────────────────────────────────────╯${NC}"
    echo
}

ui_menu_custom() {
    echo -e "${CYAN}╭─ Custom Installation ────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│ Select components to install (space-separated numbers):                 │${NC}"
    echo -e "${CYAN}│                                                                          │${NC}"
    echo -e "${CYAN}│  1)${NC} ZSH + Oh My ZSH           ${CYAN}│  6)${NC} Rust Tools                     ${CYAN}│${NC}"
    echo -e "${CYAN}│  2)${NC} Go Programming Language   ${CYAN}│  7)${NC} Other Tools (apt/snap)         ${CYAN}│${NC}"
    echo -e "${CYAN}│  3)${NC} Rust Programming Language ${CYAN}│  8)${NC} Wordlists                      ${CYAN}│${NC}"
    echo -e "${CYAN}│  4)${NC} Go Security Tools         ${CYAN}│  9)${NC} All Components                 ${CYAN}│${NC}"
    echo -e "${CYAN}│  5)${NC} Python Security Tools     ${CYAN}│                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│                                                                          │${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────────────────╯${NC}"
    echo
}

ui_confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response
    
    # Auto-accept if force flag is set
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    if [[ "$INTERACTIVE" == "false" ]]; then
        echo "$default"
        return 0
    fi
    
    if [[ "$default" == "y" ]]; then
        read -r -p "$(echo -e "${YELLOW}${prompt} [Y/n]:${NC} ")" response
        response=${response:-y}
    else
        read -r -p "$(echo -e "${YELLOW}${prompt} [y/N]:${NC} ")" response
        response=${response:-n}
    fi
    
    [[ "$response" =~ ^[Yy]$ ]] && return 0 || return 1
}

# ==============================================================================
# Installation Summary
# ==============================================================================

ui_show_summary() {
    local -n installed_tools=$1
    
    echo
    ui_section_header "Installation Summary" "$CYAN"
    
    echo -e "${CYAN}╭─ Installed Components ───────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│                                                                          │${NC}"
    
    for tool in "${installed_tools[@]}"; do
        printf "${CYAN}│${NC} ${GREEN}✓${NC} %-70s ${CYAN}│${NC}\n" "$tool"
    done
    
    echo -e "${CYAN}│                                                                          │${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────────────────╯${NC}"
    
    echo
    echo -e "${BLUE}📁 Installation Locations:${NC}"
    echo -e "   Tools:     ${GREEN}${TOOLS_DIR}${NC}"
    echo -e "   Wordlists: ${GREEN}${WORDLISTS_DIR}${NC}"
    echo -e "   Log file:  ${GREEN}${LOG_FILE}${NC}"
    echo -e "   Manifest:  ${GREEN}${MANIFEST_FILE}${NC}"
    echo
}

ui_show_next_steps() {
    echo -e "${YELLOW}╭─ Next Steps ─────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${YELLOW}│                                                                          │${NC}"
    echo -e "${YELLOW}│ 1.${NC} 🔄 Reload shell configuration: ${CYAN}source ~/.zshrc${NC}                 ${YELLOW}│${NC}"
    echo -e "${YELLOW}│ 2.${NC} 🎨 Configure Powerlevel10k:    ${CYAN}p10k configure${NC}                  ${YELLOW}│${NC}"
    echo -e "${YELLOW}│ 3.${NC} 🐚 Set ZSH as default shell:   ${CYAN}chsh -s /bin/zsh${NC}                ${YELLOW}│${NC}"
    echo -e "${YELLOW}│ 4.${NC} 🔍 Verify installations:       ${CYAN}ls -la ~/tools${NC}                  ${YELLOW}│${NC}"
    echo -e "${YELLOW}│ 5.${NC} 📚 Check wordlists:            ${CYAN}ls -la ~/wordlists${NC}              ${YELLOW}│${NC}"
    echo -e "${YELLOW}│                                                                          │${NC}"
    echo -e "${YELLOW}╰──────────────────────────────────────────────────────────────────────────╯${NC}"
    echo
}

# ==============================================================================
# Error Display
# ==============================================================================

ui_show_error() {
    local error_msg="$1"
    local troubleshooting="${2:-}"
    
    echo
    echo -e "${RED}╭─ ERROR ──────────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${RED}│                                                                          │${NC}"
    printf "${RED}│${NC} %s\n" "$error_msg" | fold -s -w 74 | sed "s/^/${RED}│${NC} /"
    
    if [[ -n "$troubleshooting" ]]; then
        echo -e "${RED}│                                                                          │${NC}"
        echo -e "${RED}│${NC} ${YELLOW}Troubleshooting:${NC}                                                     ${RED}│${NC}"
        printf "${RED}│${NC} %s\n" "$troubleshooting" | fold -s -w 74 | sed "s/^/${RED}│${NC} /"
    fi
    
    echo -e "${RED}│                                                                          │${NC}"
    echo -e "${RED}│${NC} ${CYAN}Log file: ${LOG_FILE}${NC}"
    echo -e "${RED}│${NC} ${CYAN}Run with: LOG_LEVEL=DEBUG for more details${NC}"
    echo -e "${RED}│                                                                          │${NC}"
    echo -e "${RED}╰──────────────────────────────────────────────────────────────────────────╯${NC}"
    echo
}

ui_error_network() {
    local component="$1"
    ui_show_error \
        "Network error downloading $component" \
        "Check internet connection. Try: ping google.com | Verify firewall settings | Use VPN if behind restrictive network"
}

ui_error_disk_space() {
    local required="$1"
    local available="$2"
    ui_show_error \
        "Insufficient disk space (need ${required}GB, have ${available}GB)" \
        "Free up space: sudo apt-get clean | Remove old logs: journalctl --vacuum-time=7d | Check: df -h"
}

ui_error_permission() {
    local operation="$1"
    ui_show_error \
        "Permission denied: $operation" \
        "Ensure you're not running as root (use regular user) | Check file permissions: ls -la | Try: sudo chmod +x install.sh"
}

ui_error_dependency() {
    local missing="$1"
    ui_show_error \
        "Missing dependency: $missing" \
        "Install with: sudo apt-get install $missing | Or run: sudo apt-get update && sudo apt-get install -y curl wget git"
}

ui_show_completion() {
    echo
    ui_show_success_banner
    ui_show_next_steps
    
    echo -e "${CYAN}╭─ Installation Complete ──────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│                                                                          │${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}✓${NC} All components have been successfully installed                     ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}✓${NC} Configuration files have been updated                               ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}✓${NC} Manifest file has been generated                                    ${CYAN}│${NC}"
    echo -e "${CYAN}│                                                                          │${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────────────────╯${NC}"
    echo
}

# ==============================================================================
# Installation Plan Preview
# ==============================================================================

ui_show_installation_plan() {
    local mode="$1"
    
    echo
    ui_section_header "Installation Plan" "$CYAN"
    echo
    echo -e "${YELLOW}╭─ What Will Be Installed ─────────────────────────────────────╮${NC}"
    echo -e "${YELLOW}│${NC} Mode: ${CYAN}$(tr '[:lower:]' '[:upper:]' <<< ${mode:0:1})${mode:1}${NC}"
    echo -e "${YELLOW}│${NC}"
    
    case "$mode" in
        full)
            echo -e "${YELLOW}│${NC} Components:"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} ZSH + Oh My ZSH + Powerlevel10k"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} Go programming language"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} Rust programming language"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} ${#GO_TOOLS[@]} Go-based security tools"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} ${#PYTHON_TOOLS[@]} Python-based tools"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} ${#RUST_TOOLS[@]} Rust-based tools"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} ${#APT_TOOLS[@]} system packages"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} ${#WORDLISTS[@]} wordlist collections"
            echo -e "${YELLOW}│${NC}"
            echo -e "${YELLOW}│${NC} Estimates:"
            echo -e "${YELLOW}│${NC}  Disk Space: ${CYAN}~3.5 GB${NC}"
            echo -e "${YELLOW}│${NC}  Download: ${CYAN}~2.8 GB${NC}"
            echo -e "${YELLOW}│${NC}  Time: ${CYAN}10-15 minutes${NC}"
            ;;
        zsh)
            echo -e "${YELLOW}│${NC} Components:"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} ZSH shell"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} Oh My ZSH framework"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} Powerlevel10k theme"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} Plugins: git, zsh-syntax-highlighting, zsh-autosuggestions"
            echo -e "${YELLOW}│${NC}"
            echo -e "${YELLOW}│${NC} Estimates:"
            echo -e "${YELLOW}│${NC}  Disk Space: ${CYAN}~50 MB${NC}"
            echo -e "${YELLOW}│${NC}  Download: ${CYAN}~25 MB${NC}"
            echo -e "${YELLOW}│${NC}  Time: ${CYAN}2-3 minutes${NC}"
            ;;
        go_tools)
            echo -e "${YELLOW}│${NC} Components:"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} Go programming language"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} ${#GO_TOOLS[@]} Go-based security tools"
            echo -e "${YELLOW}│${NC}"
            echo -e "${YELLOW}│${NC} Estimates:"
            echo -e "${YELLOW}│${NC}  Disk Space: ${CYAN}~1.2 GB${NC}"
            echo -e "${YELLOW}│${NC}  Download: ${CYAN}~800 MB${NC}"
            echo -e "${YELLOW}│${NC}  Time: ${CYAN}3-5 minutes${NC}"
            ;;
        python_tools)
            echo -e "${YELLOW}│${NC} Components:"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} Python virtual environment"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} ${#PYTHON_TOOLS[@]} Python-based security tools"
            echo -e "${YELLOW}│${NC}"
            echo -e "${YELLOW}│${NC} Estimates:"
            echo -e "${YELLOW}│${NC}  Disk Space: ${CYAN}~500 MB${NC}"
            echo -e "${YELLOW}│${NC}  Download: ${CYAN}~300 MB${NC}"
            echo -e "${YELLOW}│${NC}  Time: ${CYAN}2-4 minutes${NC}"
            ;;
        rust_tools)
            echo -e "${YELLOW}│${NC} Components:"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} Rust programming language"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} ${#RUST_TOOLS[@]} Rust-based security tools"
            echo -e "${YELLOW}│${NC}"
            echo -e "${YELLOW}│${NC} Estimates:"
            echo -e "${YELLOW}│${NC}  Disk Space: ${CYAN}~400 MB${NC}"
            echo -e "${YELLOW}│${NC}  Download: ${CYAN}~250 MB${NC}"
            echo -e "${YELLOW}│${NC}  Time: ${CYAN}3-5 minutes${NC}"
            ;;
        wordlists)
            echo -e "${YELLOW}│${NC} Components:"
            echo -e "${YELLOW}│${NC}  ${GREEN}✓${NC} ${#WORDLISTS[@]} wordlist collections"
            echo -e "${YELLOW}│${NC}"
            echo -e "${YELLOW}│${NC} Estimates:"
            echo -e "${YELLOW}│${NC}  Disk Space: ${CYAN}~1.5 GB${NC}"
            echo -e "${YELLOW}│${NC}  Download: ${CYAN}~1.2 GB${NC}"
            echo -e "${YELLOW}│${NC}  Time: ${CYAN}3-6 minutes${NC}"
            ;;
    esac
    
    echo -e "${YELLOW}│${NC}"
    echo -e "${YELLOW}│${NC} Installation Locations:"
    echo -e "${YELLOW}│${NC}  Tools: ${CYAN}${TOOLS_DIR}${NC}"
    echo -e "${YELLOW}│${NC}  Wordlists: ${CYAN}${WORDLISTS_DIR}${NC}"
    echo -e "${YELLOW}│${NC}  Log: ${CYAN}${LOG_FILE}${NC}"
    echo -e "${YELLOW}│${NC}  Manifest: ${CYAN}${MANIFEST_FILE}${NC}"
    echo -e "${YELLOW}╰──────────────────────────────────────────────────────────────╯${NC}"
    echo
    
    if [[ "$INTERACTIVE" == "true" ]] && [[ "$FORCE" != "true" ]]; then
        ui_confirm "Proceed with installation?" "y" || exit 0
    fi
}
    echo -e "${CYAN}│                                                                          │${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────────────────────╯${NC}"
    echo
}
