#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  bbtk — Bug Bounty Toolkit Installer
#  Self-contained, idempotent security tool installer for Ubuntu servers.
#  https://github.com/shayanrsh/bug-bounty-toolkit-install-script
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

VERSION="2.2"
REPO_URL="https://github.com/shayanrsh/bug-bounty-toolkit-install-script.git"
CLONE_DIR="/tmp/bug-bounty-toolkit-install-script"

# ── Auto-clone when executed via curl pipe ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"

if [[ ! -f "$SCRIPT_DIR/lib/utils.sh" ]]; then
    echo "  [*] Detected curl-pipe execution — cloning repository…"
    command -v git &>/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq git; }
    rm -rf "$CLONE_DIR"
    git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
    chmod +x "$CLONE_DIR/install.sh"
    exec bash "$CLONE_DIR/install.sh" "$@"
fi

# ── Source libraries (order matters) ─────────────────────────────────────────
for _lib in utils ui tools; do
    if [[ ! -f "$SCRIPT_DIR/lib/${_lib}.sh" ]]; then
        echo "Error: lib/${_lib}.sh not found. Run from the project root." >&2
        exit 1
    fi
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/lib/${_lib}.sh"
done
unset _lib

# ── Traps ────────────────────────────────────────────────────────────────────
cleanup() { rm -f /tmp/toolkit-install-*.tmp 2>/dev/null || true; }
trap cleanup EXIT
trap 'printf "\n"; log_warn "Interrupted by user."; exit 130' INT

# ── Usage / help ─────────────────────────────────────────────────────────────
MODE=""

usage() {
    cat <<'EOF'
Usage: bbtk [OPTIONS]

Install options:
  --full           Install everything (non-interactive)
  --python         Install Python tools only
  --go             Install Go + Rust tools only
  --docker         Install Docker + Docker tools only
  --apt            Install APT/Snap tools only
  --wordlists      Install wordlists & payloads only
  --zsh            Install Zsh + Oh My Zsh only

Management:
  --update         Update all installed tools
  --update-wl      Update all wordlists
  --uninstall      Uninstall everything
  --uninstall-sel  Selective uninstall (interactive)

Other:
  --debug          Enable debug-level logging
  -v, --version    Show version
  -h, --help       Show this help message

If no flag is given, an interactive menu is shown.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --full)           MODE="full" ;;
            --python)         MODE="python" ;;
            --go)             MODE="go" ;;
            --docker)         MODE="docker" ;;
            --apt)            MODE="apt" ;;
            --wordlists)      MODE="wordlists" ;;
            --zsh)            MODE="zsh" ;;
            --update)         MODE="update" ;;
            --update-wl)      MODE="update-wl" ;;
            --uninstall)      MODE="uninstall" ;;
            --uninstall-sel)  MODE="uninstall-sel" ;;
            --debug)          LOG_LEVEL="debug" ;;
            -v|--version)     echo "bbtk v${VERSION}"; exit 0 ;;
            -h|--help)        usage; exit 0 ;;
            *)                log_error "Unknown option: $1"; usage; exit 1 ;;
        esac
        shift
    done
}

# ── Pre-flight checks ───────────────────────────────────────────────────────
preflight() {
    log_info "Running pre-flight checks…"
    check_os
    check_sudo
    check_internet
    check_disk_space 5000
    ensure_apt_deps
    printf "\n"
}

# ── Install the ‘bbtk’ shell alias ────────────────────────────────────────
install_bbtk_alias() {
    local real_path
    real_path="$(cd "$SCRIPT_DIR" && pwd)/install.sh"
    local marker="# bbtk alias (bug-bounty-toolkit)"
    local alias_line="alias bbtk='bash \"${real_path}\"'"
    local rc_file
    rc_file=$(get_rc_file)

    if grep -qF "$marker" "$rc_file" 2>/dev/null; then
        # Update the path in case the repo moved
        sed -i "/# bbtk alias/d; /alias bbtk=/d" "$rc_file" 2>/dev/null || true
    fi
    {
        echo ""
        echo "$marker"
        echo "$alias_line"
    } >> "$rc_file"
    log_debug "Installed bbtk alias in $rc_file"
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"

    show_banner
    printf "  ${DIM}Log: %s${RESET}\n\n" "$LOG_FILE"

    preflight
    install_bbtk_alias

    if [[ -z "$MODE" ]]; then
        show_menu
        MODE="$MENU_CHOICE"
    fi

    local summary_title="Installation Complete"

    case "$MODE" in
        1|full)           install_all ;;
        2|python)         install_python_suite ;;
        3|go)             install_go_suite ;;
        4|docker)         install_docker_suite ;;
        5|apt)            install_apt_suite ;;
        6|wordlists)      install_wordlists_suite ;;
        7|zsh)            install_zsh_suite ;;
        8|custom)         install_custom ;;
        9|update)         update_tools;      summary_title="Update Complete" ;;
        10|update-wl)     update_wordlists;  summary_title="Wordlist Update Complete" ;;
        11|uninstall)     uninstall_all;     summary_title="Uninstall Complete" ;;
        12|uninstall-sel) uninstall_custom;  summary_title="Uninstall Complete" ;;
        0)                printf "\n"; log_info "Goodbye!"; exit 0 ;;
        *)                log_error "Invalid choice: $MODE"; exit 1 ;;
    esac

    show_summary "$summary_title"
}

main "$@"
