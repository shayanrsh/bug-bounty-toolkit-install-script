#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  bbtk — Bug Bounty Toolkit Installer
#  Self-contained, idempotent security tool installer for Ubuntu servers.
#  https://github.com/shayanrsh/bug-bounty-toolkit-install-script
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

VERSION="2.3"
REPO_URL="https://github.com/shayanrsh/bug-bounty-toolkit-install-script.git"
CLONE_DIR="/tmp/bug-bounty-toolkit-install-script"
PERSIST_DIR="${HOME}/.local/share/bbtk"

# ── Auto-clone when executed via curl pipe ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"

if [[ ! -f "$SCRIPT_DIR/lib/utils.sh" ]]; then
    echo "  [*] Detected curl-pipe execution — cloning repository…"
    command -v git &>/dev/null || { sudo apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 update -qq && DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a sudo apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 install -y git; }
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
    --update-script  Update the toolkit script (git pull)
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
            --update-script)  MODE="update-script" ;;
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
    # Optional arg: explicit rc file path. Defaults to detected shell rc.
    local rc_file="${1:-}"
    [[ -z "$rc_file" ]] && rc_file=$(get_rc_file)

    local real_path
    real_path="$(cd "$SCRIPT_DIR" && pwd)/install.sh"
    local marker="# bbtk alias (bug-bounty-toolkit)"
    local alias_line="alias bbtk='bash \"${real_path}\"'"

    touch "$rc_file" 2>/dev/null || true

    if grep -qF "$marker" "$rc_file" 2>/dev/null; then
        # Update the path in case the repo moved
        sed -i "/^# bbtk alias (bug-bounty-toolkit)$/,/^alias bbtk=/d" "$rc_file" 2>/dev/null || true
        sed -i "/^alias bbtk=/d" "$rc_file" 2>/dev/null || true
    fi

    {
        echo ""
        echo "$marker"
        echo "$alias_line"
    } >> "$rc_file"
    log_debug "Installed bbtk alias in $rc_file"
}

install_bbtk_alias_for_shell() {
    local shell_name="$1"
    install_bbtk_alias "$(get_rc_file_for_shell "$shell_name")"
}

# ── Install bbtk as a real command (preferred over alias) ───────────────────
install_bbtk_command() {
        # Persist a copy/clone so bbtk keeps working even if the current repo lives in /tmp
        mkdir -p "${HOME}/.local/share" "${HOME}/.local/bin" 2>/dev/null || true

        if [[ ! -x "${PERSIST_DIR}/install.sh" ]]; then
                rm -rf "${PERSIST_DIR}" 2>/dev/null || true
                if [[ -d "${SCRIPT_DIR}/.git" ]]; then
                        # Copy current working tree (fast, no network needed)
                        cp -a "${SCRIPT_DIR}" "${PERSIST_DIR}" 2>/dev/null || true
                fi
                if [[ ! -x "${PERSIST_DIR}/install.sh" ]]; then
                        # Fallback: clone
                        command -v git &>/dev/null || { sudo apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 update -qq && DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a sudo apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 install -y git; }
                        git clone --depth 1 "${REPO_URL}" "${PERSIST_DIR}" >> "$LOG_FILE" 2>&1 || true
                fi
                chmod +x "${PERSIST_DIR}/install.sh" 2>/dev/null || true
        fi

        local wrapper_content
        wrapper_content=$(cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/shayanrsh/bug-bounty-toolkit-install-script.git"
PERSIST_DIR="${HOME}/.local/share/bbtk"

if [[ ! -x "${PERSIST_DIR}/install.sh" ]]; then
    mkdir -p "${HOME}/.local/share" 2>/dev/null || true
    rm -rf "${PERSIST_DIR}" 2>/dev/null || true
    command -v git >/dev/null 2>&1 || {
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 update -qq && DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a sudo apt-get -o DPkg::Lock::Timeout=300 -o Acquire::Retries=3 install -y git
        else
            echo "Error: git is required to install bbtk." >&2
            exit 1
        fi
    }
    git clone --depth 1 "${REPO_URL}" "${PERSIST_DIR}" >/dev/null 2>&1
    chmod +x "${PERSIST_DIR}/install.sh" 2>/dev/null || true
fi

exec bash "${PERSIST_DIR}/install.sh" "$@"
EOF
)

        # Prefer system-wide location so it works in any shell without PATH tweaks
        if sudo -n true 2>/dev/null; then
                echo "$wrapper_content" | sudo tee /usr/local/bin/bbtk >/dev/null
                sudo chmod 0755 /usr/local/bin/bbtk
                log_debug "Installed bbtk command in /usr/local/bin/bbtk"
                return 0
        fi

        # Fallback per-user
        printf "%s\n" "$wrapper_content" > "${HOME}/.local/bin/bbtk"
        chmod 0755 "${HOME}/.local/bin/bbtk" 2>/dev/null || true
        export PATH="$PATH:${HOME}/.local/bin"
        add_to_all_rc 'export PATH="$PATH:$HOME/.local/bin"'
        log_debug "Installed bbtk command in $HOME/.local/bin/bbtk"
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"

    show_banner
    printf "  ${DIM}Log: %s${RESET}\n\n" "$LOG_FILE"

    preflight
    install_bbtk_command
    install_bbtk_alias

    # Non-interactive modes run once and exit.
    if [[ -n "$MODE" ]]; then
        local summary_title="Installation Complete"
        case "$MODE" in
            full)           install_all ;;
            python)         install_python_suite ;;
            go)             install_go_suite ;;
            docker)         install_docker_suite ;;
            apt)            install_apt_suite ;;
            wordlists)      install_wordlists_suite ;;
            zsh)            install_zsh_suite ;;
            update)         update_tools;      summary_title="Update Complete" ;;
            update-wl)      update_wordlists;  summary_title="Wordlist Update Complete" ;;
            update-script)  update_script;     summary_title="Script Update Complete" ;;
            uninstall)      uninstall_all;     summary_title="Uninstall Complete" ;;
            uninstall-sel)  uninstall_custom;  summary_title="Uninstall Complete" ;;
            *)              log_error "Invalid mode: $MODE"; exit 1 ;;
        esac
        show_summary "$summary_title"
        return 0
    fi

    # Interactive mode: loop back to the menu after each operation.
    while true; do
        progress_init 0
        show_menu
        MODE="$MENU_CHOICE"

        local summary_title="Installation Complete"
        case "$MODE" in
            1)  install_all ;;
            2)  install_python_suite ;;
            3)  install_go_suite ;;
            4)  install_docker_suite ;;
            5)  install_apt_suite ;;
            6)  install_wordlists_suite ;;
            7)  install_zsh_suite ;;
            8)  install_custom ;;
            9)  update_tools;      summary_title="Update Complete" ;;
            10) update_wordlists;  summary_title="Wordlist Update Complete" ;;
            11) update_script;     summary_title="Script Update Complete" ;;
            12) uninstall_all;     summary_title="Uninstall Complete" ;;
            13) uninstall_custom;  summary_title="Uninstall Complete" ;;
            0)
                printf "\n"
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid choice: $MODE"
                continue
                ;;
        esac

        # If the operation didn't run anything (e.g., backed out), skip summary.
        if (( PROGRESS_TOTAL > 0 )) || (( PROGRESS_DONE + PROGRESS_SKIP + PROGRESS_FAIL > 0 )); then
            show_summary "$summary_title"
        fi
        read -rp "  Press Enter to return to the main menu…" _
        MODE=""
    done
}

main "$@"
