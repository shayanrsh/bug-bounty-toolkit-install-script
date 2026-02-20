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
    if [[ -n "$_DETECTED_SHELL" ]]; then
        echo "$_DETECTED_SHELL"
        return 0
    fi

    # Prefer the user’s login shell ($SHELL) so running via `bash install.sh`
    # still configures the shell the user actually uses.
    if [[ -n "${SHELL-}" ]] && [[ "${SHELL##*/}" == "zsh" ]]; then
        _DETECTED_SHELL="zsh"
    elif [[ -n "${ZSH_VERSION-}" ]]; then
        _DETECTED_SHELL="zsh"
    elif [[ -n "${BASH_VERSION-}" ]]; then
        _DETECTED_SHELL="bash"
    else
        _DETECTED_SHELL="bash"
    fi

    echo "$_DETECTED_SHELL"
}

get_rc_file_for_shell() {
    local shell_name="${1:-bash}"
    case "$shell_name" in
        zsh) echo "${HOME}/.zshrc" ;;
        *)   echo "${HOME}/.bashrc" ;;
    esac
}

get_rc_file() {
    if [[ -z "$_CACHED_RC_FILE" ]]; then
        _CACHED_RC_FILE="$(get_rc_file_for_shell "$(detect_shell)")"
    fi
    echo "$_CACHED_RC_FILE"
}

add_to_rc_file() {
    local rc_file="$1" line="$2"
    [[ -z "$rc_file" ]] && return 1
    touch "$rc_file" 2>/dev/null || true
    grep -qF "$line" "$rc_file" 2>/dev/null || { echo "$line" >> "$rc_file"; log_debug "Added to $rc_file: $line"; }
}

remove_from_rc_file() {
    local rc_file="$1" pattern="$2"
    [[ -z "$rc_file" ]] && return 1
    if [[ -f "$rc_file" ]]; then
        sed -i "\|${pattern}|d" "$rc_file" 2>/dev/null || true
    fi
}

_known_rc_files() {
    # Keep deterministic ordering
    echo "${HOME}/.bashrc"
    echo "${HOME}/.zshrc"
}

add_to_all_rc() {
    local line="$1"
    local rc
    while IFS= read -r rc; do
        add_to_rc_file "$rc" "$line"
    done < <(_known_rc_files)
}

remove_from_all_rc() {
    local pattern="$1"
    local rc
    while IFS= read -r rc; do
        remove_from_rc_file "$rc" "$pattern"
    done < <(_known_rc_files)
}

add_to_rc() {
    local line="$1"
    local rc_file
    rc_file=$(get_rc_file)
    add_to_rc_file "$rc_file" "$line"
}

remove_from_rc() {
    local pattern="$1"
    local rc_file
    rc_file=$(get_rc_file)
    remove_from_rc_file "$rc_file" "$pattern"
}

# ── Prerequisite bootstrap ──────────────────────────────────────────────────

ensure_apt_deps() {
    local missing=()
    for cmd in curl wget git; do
        cmd_exists "$cmd" || missing+=("$cmd")
    done
    if (( ${#missing[@]} > 0 )); then
        log_info "Installing prerequisites: ${missing[*]}"
        sudo apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 update -qq >> "$LOG_FILE" 2>&1
        DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a sudo apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 install -y "${missing[@]}" >> "$LOG_FILE" 2>&1
    fi
    # Ensure python3 + venv
    if ! cmd_exists python3; then
        DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a sudo apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 install -y python3 python3-pip python3-venv >> "$LOG_FILE" 2>&1
    fi
    if ! python3 -c "import venv" 2>/dev/null; then
        DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a sudo apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 install -y python3-venv >> "$LOG_FILE" 2>&1
    fi
    if ! cmd_exists pipx; then
        DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a sudo apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 install -y pipx >> "$LOG_FILE" 2>&1 || true
        pipx ensurepath >> "$LOG_FILE" 2>&1 || true
        export PATH="$PATH:$HOME/.local/bin"
    fi

    # Ensure launchers are usable in future sessions (pipx + toolkit wrappers)
    add_to_rc 'export PATH="$PATH:$HOME/.local/bin"'
    log_ok "Prerequisites satisfied"
}
