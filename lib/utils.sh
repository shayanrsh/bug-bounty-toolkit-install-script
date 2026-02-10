#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# lib/utils.sh — Logging, validation, shell detection, helpers
# ─────────────────────────────────────────────────────────────────────────────

LOG_LEVEL="${LOG_LEVEL:-info}"
LOG_FILE="${LOG_FILE:-/tmp/toolkit-install-$(date +%Y%m%d-%H%M%S).log}"
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/toolkit-install.log"

TOOLS_DIR="$HOME/tools"
WORDLISTS_DIR="$HOME/wordlists"

# ── Logging ──────────────────────────────────────────────────────────────────

_log_file() { printf -v _ts '%(%H:%M:%S)T' -1; echo "[$_ts] [$1] $2" >> "$LOG_FILE"; }

log_debug() {
    _log_file "DEBUG" "$*"
    [[ "$LOG_LEVEL" == "debug" ]] && printf "  ${DIM:-}[DBG]${RESET:-} %s\n" "$*"
    return 0
}

log_info() {
    _log_file "INFO" "$*"
    printf "  ${CYAN:-}[*]${RESET:-} %s\n" "$*"
}

log_ok() {
    _log_file "OK" "$*"
    printf "  ${GREEN:-}[✓]${RESET:-} %s\n" "$*"
}

log_warn() {
    _log_file "WARN" "$*"
    printf "  ${YELLOW:-}[!]${RESET:-} %s\n" "$*"
}

log_error() {
    _log_file "ERROR" "$*"
    printf "  ${RED:-}[✗]${RESET:-} %s\n" "$*" >&2
}

# ── Command helpers ──────────────────────────────────────────────────────────

cmd_exists() { command -v "$1" &>/dev/null; }

is_apt_installed() { dpkg -l "$1" 2>/dev/null | grep -q "^ii"; }

is_snap_installed() { snap list "$1" 2>/dev/null | grep -q "^$1"; }

# ── System checks ───────────────────────────────────────────────────────────

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_warn "Cannot detect OS (/etc/os-release missing)"
        return 0
    fi
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "ubuntu" ]]; then
        log_warn "Designed for Ubuntu; detected: ${ID:-unknown} ${VERSION_ID:-}"
    else
        log_ok "OS: Ubuntu ${VERSION_ID}"
    fi
}

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        log_warn "Running as root — consider a normal user with sudo instead"
        return 0
    fi
    if ! sudo -v 2>/dev/null; then
        log_error "Sudo access required."
        exit 1
    fi
    log_ok "Sudo access verified"
}

check_internet() {
    if curl -s --connect-timeout 5 https://github.com >/dev/null 2>&1; then
        log_ok "Internet connectivity verified"
    elif ping -c1 -W3 8.8.8.8 >/dev/null 2>&1; then
        log_warn "DNS may have issues, but network is reachable"
    else
        log_error "No internet connectivity — cannot proceed"
        exit 1
    fi
}

check_disk_space() {
    local required_mb="${1:-5000}"
    local avail_mb
    avail_mb=$(df -m / | awk 'NR==2{print $4}')
    if (( avail_mb < required_mb )); then
        log_error "Need ${required_mb}MB disk space; only ${avail_mb}MB available"
        exit 1
    fi
    log_ok "Disk space: ${avail_mb}MB available"
}

# ── Shell detection (cached) ──────────────────────────────────────────────

_DETECTED_SHELL=""
_CACHED_RC_FILE=""

detect_shell() {
    if [[ -z "$_DETECTED_SHELL" ]]; then
        if cmd_exists zsh; then _DETECTED_SHELL="zsh"; else _DETECTED_SHELL="bash"; fi
    fi
    echo "$_DETECTED_SHELL"
}

get_rc_file() {
    if [[ -z "$_CACHED_RC_FILE" ]]; then
        case "$(detect_shell)" in
            zsh) _CACHED_RC_FILE="${HOME}/.zshrc" ;;
            *)   _CACHED_RC_FILE="${HOME}/.bashrc" ;;
        esac
    fi
    echo "$_CACHED_RC_FILE"
}

add_to_rc() {
    local line="$1"
    local rc_file
    rc_file=$(get_rc_file)
    grep -qF "$line" "$rc_file" 2>/dev/null || { echo "$line" >> "$rc_file"; log_debug "Added to $rc_file: $line"; }
}

remove_from_rc() {
    local pattern="$1"
    local rc_file
    rc_file=$(get_rc_file)
    if [[ -f "$rc_file" ]]; then
        sed -i "\|${pattern}|d" "$rc_file" 2>/dev/null || true
    fi
}

# ── Prerequisite bootstrap ──────────────────────────────────────────────────

ensure_apt_deps() {
    local missing=()
    for cmd in curl wget git; do
        cmd_exists "$cmd" || missing+=("$cmd")
    done
    if (( ${#missing[@]} > 0 )); then
        log_info "Installing prerequisites: ${missing[*]}"
        sudo apt-get update -qq >> "$LOG_FILE" 2>&1
        sudo apt-get install -y -qq "${missing[@]}" >> "$LOG_FILE" 2>&1
    fi
    # Ensure python3 + venv
    if ! cmd_exists python3; then
        sudo apt-get install -y -qq python3 python3-pip python3-venv >> "$LOG_FILE" 2>&1
    fi
    if ! python3 -c "import venv" 2>/dev/null; then
        sudo apt-get install -y -qq python3-venv >> "$LOG_FILE" 2>&1
    fi
    if ! cmd_exists pipx; then
        sudo apt-get install -y -qq pipx >> "$LOG_FILE" 2>&1 || true
        pipx ensurepath >> "$LOG_FILE" 2>&1 || true
        export PATH="$PATH:$HOME/.local/bin"
    fi
    log_ok "Prerequisites satisfied"
}
