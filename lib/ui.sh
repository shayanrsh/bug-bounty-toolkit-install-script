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
        echo "======================================================================"
    } > "$LOG_FILE"
}

# Generic log message function
_log_message() {
    local level="$1"
    local color="$2"
    local icon="$3"
    local message="$4"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Console output (colored)
    if [[ "$VERBOSE" == "true" ]] || [[ "$level" != "DEBUG" ]]; then
        echo -e "${color}${icon} [${level}] ${timestamp}${NC} ${message}"
    fi
    
    # File output (plain text)
    echo "[${level}] ${timestamp} ${message}" >> "$LOG_FILE"
}

log_debug()   { [[ "$DEBUG" == "true" ]] && _log_message "DEBUG"   "$PURPLE" "$ICON_DEBUG"   "$1"; }
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
    local percentage=$((current * 100 / total))
    local filled_width=$((current * PROGRESS_BAR_WIDTH / total))
    local empty_width=$((PROGRESS_BAR_WIDTH - filled_width))
    
    # Color coding based on percentage
    local bar_color="$RED"
    [[ $percentage -ge 75 ]] && bar_color="$GREEN"
    [[ $percentage -ge 50 && $percentage -lt 75 ]] && bar_color="$YELLOW"
    [[ $percentage -ge 25 && $percentage -lt 50 ]] && bar_color="$BLUE"
    
    # Create bars
    local filled_bar
    local empty_bar
    filled_bar=$(printf "█%.0s" $(seq 1 "$filled_width" 2>/dev/null))
    empty_bar=$(printf "░%.0s" $(seq 1 "$empty_width" 2>/dev/null))
    
    # Display progress
    printf "\r${CYAN}[${bar_color}%s${CYAN}%s] %3d%% (%d/%d)${NC} %s" \
           "$filled_bar" "$empty_bar" "$percentage" "$current" "$total" "$message"
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
    echo -e "${RED}╰──────────────────────────────────────────────────────────────────────────╯${NC}"
    echo
}
