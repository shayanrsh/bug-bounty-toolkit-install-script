#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# lib/ui.sh — Terminal UI: colors, progress bars, banners, spinners, menus
# ─────────────────────────────────────────────────────────────────────────────

# ── Colors ───────────────────────────────────────────────────────────────────

setup_colors() {
    if [[ -t 1 ]] && [[ "${TERM:-dumb}" != "dumb" ]]; then
        RED='\033[0;31m'    GREEN='\033[0;32m'  YELLOW='\033[0;33m'
        BLUE='\033[0;34m'   CYAN='\033[0;36m'   WHITE='\033[1;37m'
        DIM='\033[2m'       BOLD='\033[1m'      RESET='\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' WHITE='' DIM='' BOLD='' RESET=''
    fi
}

setup_symbols() {
    if locale charmap 2>/dev/null | grep -qi 'utf-8'; then
        SYM_OK="✓"  SYM_FAIL="✗"  SYM_SKIP="⊘"  SYM_DEL="✕"
        BAR_FILL="█" BAR_EMPTY="░"
        SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    else
        SYM_OK="+"  SYM_FAIL="x"  SYM_SKIP="-"  SYM_DEL="x"
        BAR_FILL="#" BAR_EMPTY="-"
        SPINNER_FRAMES=('|' '/' '-' '\')
    fi
}

setup_colors
setup_symbols

# ── Banner ───────────────────────────────────────────────────────────────────

show_banner() {
    printf "\n"
    printf "  ${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}\n"
    printf "  ${CYAN}║${RESET}   ${BOLD}${WHITE}Bug Bounty Toolkit Installer${RESET}  ${DIM}v2.2${RESET}                    ${CYAN}║${RESET}\n"
    printf "  ${CYAN}║${RESET}   ${DIM}Security tools for Ubuntu servers${RESET}                      ${CYAN}║${RESET}\n"
    printf "  ${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}\n"
    printf "\n"
}

# ── Progress Tracking ────────────────────────────────────────────────────────

PROGRESS_TOTAL=0
PROGRESS_DONE=0
PROGRESS_SKIP=0
PROGRESS_FAIL=0
PROGRESS_ACTIVE=0
PROGRESS_PARTIAL=0

progress_init() {
    PROGRESS_TOTAL=$1
    PROGRESS_DONE=0
    PROGRESS_SKIP=0
    PROGRESS_FAIL=0
}

# Precompute bar strings once (width=20) to avoid loops in the hot path
_BAR_W=20
declare -a _BARS_FILL _BARS_EMPTY
_precompute_bars() {
    local i fill="" empty=""
    for (( i = 0; i <= _BAR_W; i++ )); do
        _BARS_FILL[$i]="$fill"
        fill+="${BAR_FILL}"
    done
    for (( i = _BAR_W; i >= 0; i-- )); do
        _BARS_EMPTY[$i]="$empty"
        empty+="${BAR_EMPTY}"
    done
}
_precompute_bars

# Precompute bouncing bar frames for per-tool activity indication
_BOUNCE_W=8
_BOUNCE_SEG=3
_BOUNCE_NFRAMES=0
declare -a _BOUNCE_FRAMES
_precompute_bounce() {
    local max_pos=$(( _BOUNCE_W - _BOUNCE_SEG ))
    local total=$(( max_pos * 2 ))
    (( total == 0 )) && total=1
    local f pos i bar
    for (( f = 0; f < total; f++ )); do
        pos=$f
        (( pos > max_pos )) && pos=$(( total - pos ))
        bar=""
        for (( i = 0; i < _BOUNCE_W; i++ )); do
            if (( i >= pos && i < pos + _BOUNCE_SEG )); then
                bar+="${BAR_FILL}"
            else
                bar+="${BAR_EMPTY}"
            fi
        done
        _BOUNCE_FRAMES+=("$bar")
    done
    _BOUNCE_NFRAMES=${#_BOUNCE_FRAMES[@]}
}
_precompute_bounce

# Precompute per-tool progress bars (width=_BOUNCE_W, 0..100)
declare -a _TOOL_BARS
_precompute_tool_bars() {
    local p filled i bar
    for (( p = 0; p <= 100; p++ )); do
        filled=$(( p * _BOUNCE_W / 100 ))
        bar=""
        for (( i = 0; i < _BOUNCE_W; i++ )); do
            if (( i < filled )); then
                bar+="${BAR_FILL}"
            else
                bar+="${BAR_EMPTY}"
            fi
        done
        _TOOL_BARS[$p]="$bar"
    done
}
_precompute_tool_bars

# ── Status line (bouncing bar + progress bar + live output on two lines) ─────
# All arithmetic is inlined — zero subshells in the hot path.

COLS=$(tput cols 2>/dev/null || echo 80)

_status_line() {
    local name="$1" frame="$2" detail="${3:-}"
    local done=$(( PROGRESS_DONE + PROGRESS_SKIP + PROGRESS_FAIL ))
    local done_milli=$(( done * 1000 ))
    if (( PROGRESS_ACTIVE == 1 )); then
        done_milli=$(( done_milli + PROGRESS_PARTIAL ))
    fi
    local total_milli=$(( PROGRESS_TOTAL * 1000 ))
    local pct=0
    (( total_milli > 0 )) && pct=$(( done_milli * 100 / total_milli ))
    (( pct > 100 )) && pct=100
    local filled=0
    (( total_milli > 0 )) && filled=$(( done_milli * _BAR_W / total_milli ))
    (( filled > _BAR_W )) && filled=$_BAR_W
    local bar="${_BARS_FILL[$filled]}${_BARS_EMPTY[$filled]}"

    printf "\r\033[2K  [${CYAN}%s${RESET}] %-18s ${DIM}│${RESET} [${GREEN}%s${RESET}] %3d%% (%d/%d)" \
        "$frame" "$name" "$bar" "$pct" "$done" "$PROGRESS_TOTAL"

    if [[ -n "$detail" ]]; then
        printf "\n\033[2K  ${DIM}    └─ %.${COLS}s${RESET}\033[A" "$detail"
    fi
}

# ── Print final result for a tool ───────────────────────────────────────────

print_result() {
    local name="$1" status="$2"
    printf "\r\033[2K\n\033[2K\033[A"
    case "$status" in
        done)
            printf "  ${GREEN}[${SYM_OK}]${RESET}  %-26s ${GREEN}installed${RESET}\n" "$name"
            (( PROGRESS_DONE++ )) || true
            ;;
        skip)
            printf "  ${YELLOW}[${SYM_SKIP}]${RESET}  %-26s ${DIM}already installed${RESET}\n" "$name"
            (( PROGRESS_SKIP++ )) || true
            ;;
        fail)
            printf "  ${RED}[${SYM_FAIL}]${RESET}  %-26s ${RED}failed${RESET}\n" "$name"
            (( PROGRESS_FAIL++ )) || true
            ;;
        removed)
            printf "  ${RED}[${SYM_DEL}]${RESET}  %-26s ${DIM}removed${RESET}\n" "$name"
            (( PROGRESS_DONE++ )) || true
            ;;
        updated)
            printf "  ${GREEN}[${SYM_OK}]${RESET}  %-26s ${CYAN}updated${RESET}\n" "$name"
            (( PROGRESS_DONE++ )) || true
            ;;
    esac
}

# ── _run_cmd — unified bouncing bar + live output tail ────────────────────────
# Usage: _run_cmd <name> <ok_status> <command_string>
# ok_status is "done" for install, "removed" for uninstall, "updated" for update

_run_cmd() {
    local name="$1" ok_status="$2"; shift 2
    local cmd="$*"
    local cmdout="/tmp/toolkit-cmd-$$-${RANDOM}.out"
    local use_stdbuf=0
    cmd_exists stdbuf && use_stdbuf=1

    PROGRESS_ACTIVE=0
    PROGRESS_PARTIAL=0

    log_debug "Running: $cmd"
    : > "$cmdout"

    # Command output goes to its own temp file (not the global log)
    if (( use_stdbuf == 1 )); then
        stdbuf -oL -eL bash -lc "$cmd" >> "$cmdout" 2>&1 &
    else
        eval "$cmd" >> "$cmdout" 2>&1 &
    fi
    local pid=$!
    local idx=0
    local start_s=$SECONDS

    while kill -0 "$pid" 2>/dev/null; do
        local last_line=""
        if [[ -s "$cmdout" ]]; then
            last_line=$(tail -1 "$cmdout" 2>/dev/null) || true
            last_line="${last_line#"${last_line%%[![:space:]]*}"}"  # trim leading whitespace
            last_line="${last_line//$'\r'/}"                       # strip \r
        fi

        local elapsed_s=$(( SECONDS - start_s ))
        local elapsed_str="${elapsed_s}s"
        (( elapsed_s >= 60 )) && elapsed_str="$(( elapsed_s / 60 ))m$(( elapsed_s % 60 ))s"

        local detail
        if [[ -n "$last_line" ]]; then
            detail="${last_line}  │  ${elapsed_str}"
        else
            detail="working…  │  ${elapsed_str}"
        fi

        _status_line "$name" "${_BOUNCE_FRAMES[$idx]}" "$detail"
        idx=$(( (idx + 1) % _BOUNCE_NFRAMES ))
        sleep 0.12
    done

    local rc=0
    wait "$pid" || rc=$?

    # Append command output to main log, then clean up
    cat "$cmdout" >> "$LOG_FILE" 2>/dev/null
    rm -f "$cmdout"

    if (( rc == 0 )); then
        print_result "$name" "$ok_status"
    else
        print_result "$name" fail
        log_debug "FAIL $name (exit $rc) — see $LOG_FILE"
    fi
    return "$rc"
}

# ── run_steps — multi-step command with monotonic tool progress ─────────────
# Usage: run_steps <name> <ok_status> <total_steps> <label1> <cmd1> ...

run_steps() {
    local name="$1" ok_status="$2" total_steps="$3"; shift 3
    local cmdout="/tmp/toolkit-cmd-$$-${RANDOM}.out"
    local use_stdbuf=0
    cmd_exists stdbuf && use_stdbuf=1

    log_debug "Running (steps): $name"
    : > "$cmdout"

    local step_idx=1
    while (( $# >= 2 )); do
        local label="$1" cmd="$2"; shift 2
        local start_s=$SECONDS
        local idx=0

        PROGRESS_ACTIVE=1
        PROGRESS_PARTIAL=$(( (step_idx - 1) * 1000 / total_steps ))

        if (( use_stdbuf == 1 )); then
            stdbuf -oL -eL bash -lc "$cmd" >> "$cmdout" 2>&1 &
        else
            eval "$cmd" >> "$cmdout" 2>&1 &
        fi
        local pid=$!

        while kill -0 "$pid" 2>/dev/null; do
            local last_line=""
            if [[ -s "$cmdout" ]]; then
                last_line=$(tail -1 "$cmdout" 2>/dev/null) || true
                last_line="${last_line#"${last_line%%[![:space:]]*}"}"
                last_line="${last_line//$'\r'/}"
            fi

            local elapsed_s=$(( SECONDS - start_s ))
            local elapsed_str="${elapsed_s}s"
            (( elapsed_s >= 60 )) && elapsed_str="$(( elapsed_s / 60 ))m$(( elapsed_s % 60 ))s"

            local tool_pct=$(( (step_idx - 1) * 100 / total_steps ))
            local detail="step ${step_idx}/${total_steps} (${tool_pct}%) - ${label}"
            if [[ -n "$last_line" ]]; then
                detail="${detail} - ${last_line}"
            fi
            detail="${detail}  |  ${elapsed_str}"

            _status_line "$name" "${_TOOL_BARS[$tool_pct]}" "$detail"
            idx=$(( (idx + 1) % _BOUNCE_NFRAMES ))
            sleep 0.12
        done

        local rc=0
        wait "$pid" || rc=$?
        if (( rc != 0 )); then
            cat "$cmdout" >> "$LOG_FILE" 2>/dev/null
            rm -f "$cmdout"
            PROGRESS_ACTIVE=0
            PROGRESS_PARTIAL=0
            print_result "$name" fail
            log_debug "FAIL $name (step $step_idx/$total_steps, exit $rc) — see $LOG_FILE"
            return "$rc"
        fi

        PROGRESS_PARTIAL=$(( step_idx * 1000 / total_steps ))
        (( step_idx++ ))
    done

    cat "$cmdout" >> "$LOG_FILE" 2>/dev/null
    rm -f "$cmdout"
    PROGRESS_ACTIVE=0
    PROGRESS_PARTIAL=0
    print_result "$name" "$ok_status"
    return 0
}

# ── run_bg_with_spinner — shows activity without counting toward progress ────
# Used for batch operations where individual results are tracked separately.

run_bg_with_spinner() {
    local name="$1"; shift
    local cmd="$*"
    local cmdout="/tmp/toolkit-cmd-$$-${RANDOM}.out"
    local use_stdbuf=0
    cmd_exists stdbuf && use_stdbuf=1

    log_debug "Running (no-count): $cmd"
    : > "$cmdout"

    PROGRESS_ACTIVE=0
    PROGRESS_PARTIAL=0
    if (( use_stdbuf == 1 )); then
        stdbuf -oL -eL bash -lc "$cmd" >> "$cmdout" 2>&1 &
    else
        eval "$cmd" >> "$cmdout" 2>&1 &
    fi
    local pid=$!
    local idx=0
    local start_s=$SECONDS

    while kill -0 "$pid" 2>/dev/null; do
        local last_line=""
        if [[ -s "$cmdout" ]]; then
            last_line=$(tail -1 "$cmdout" 2>/dev/null) || true
            last_line="${last_line#"${last_line%%[![:space:]]*}"}"
            last_line="${last_line//$'\r'/}"
        fi

        local elapsed_s=$(( SECONDS - start_s ))
        local elapsed_str="${elapsed_s}s"
        (( elapsed_s >= 60 )) && elapsed_str="$(( elapsed_s / 60 ))m$(( elapsed_s % 60 ))s"

        local detail="${last_line:-working…}  │  ${elapsed_str}"
        _status_line "$name" "${_BOUNCE_FRAMES[$idx]}" "$detail"
        idx=$(( (idx + 1) % _BOUNCE_NFRAMES ))
        sleep 0.12
    done

    local rc=0; wait "$pid" || rc=$?

    # Append to log and clean up
    cat "$cmdout" >> "$LOG_FILE" 2>/dev/null
    rm -f "$cmdout"

    printf "\r\033[2K\n\033[2K\033[A"   # clear status line without counting
    return "$rc"
}

# Convenience wrappers
run_install() { local n="$1"; shift; _run_cmd "$n" done "$@"; }
run_action()  { local n="$1" s="$2"; shift 2; _run_cmd "$n" "$s" "$@"; }

# ── Section headers / footers ───────────────────────────────────────────────

section_header() {
    local title="$1" count="$2"
    printf "\n  ${BOLD}── %s (%d) ──────────────────────────────────────${RESET}\n\n" "$title" "$count"
}

section_footer() {
    local title="$1"
    local done=$(( PROGRESS_DONE + PROGRESS_SKIP + PROGRESS_FAIL ))
    local pct=0
    (( PROGRESS_TOTAL > 0 )) && pct=$(( done * 100 / PROGRESS_TOTAL ))
    (( pct > 100 )) && pct=100
    # Use wider bar (30) for footer — compute inline
    local filled=$(( pct * 30 / 100 )) empty=$(( 30 - pct * 30 / 100 ))
    (( filled > 30 )) && filled=30
    (( empty < 0 )) && empty=0
    local bar="" i
    for (( i = 0; i < filled; i++ )); do bar+="${BAR_FILL}"; done
    for (( i = 0; i < empty; i++ ));  do bar+="${BAR_EMPTY}"; done
    printf "\n  ${DIM}── %s done${RESET}  [${GREEN}%s${RESET}] %d%%  " "$title" "$bar" "$pct"
    printf "(${GREEN}${SYM_OK}%d${RESET} ${YELLOW}${SYM_SKIP}%d${RESET} ${RED}${SYM_FAIL}%d${RESET})\n" \
        "$PROGRESS_DONE" "$PROGRESS_SKIP" "$PROGRESS_FAIL"
}

# ── Interactive menu ─────────────────────────────────────────────────────────

MENU_CHOICE=""

show_menu() {
    while true; do
        printf "  ${BOLD}Select an option:${RESET}\n\n"
        printf "    ${CYAN} 1${RESET})  Full Install             ${DIM}— all tools, wordlists, payloads${RESET}\n"
        printf "    ${CYAN} 2${RESET})  Python Tools             ${DIM}— shodan, sqlmap, waymore …${RESET}\n"
        printf "    ${CYAN} 3${RESET})  Go Tools                 ${DIM}— subfinder, nuclei, httpx …${RESET}\n"
        printf "    ${CYAN} 4${RESET})  Docker + Docker Tools    ${DIM}— docker, jwt_tool${RESET}\n"
        printf "    ${CYAN} 5${RESET})  APT / Snap Tools         ${DIM}— dalfox, hydra, whois …${RESET}\n"
        printf "    ${CYAN} 6${RESET})  Wordlists & Payloads     ${DIM}— SecLists, assetnote …${RESET}\n"
        printf "    ${CYAN} 7${RESET})  Zsh + Oh My Zsh          ${DIM}— zsh, powerlevel10k, plugins${RESET}\n"
        printf "    ${CYAN} 8${RESET})  Custom Select            ${DIM}— pick categories or individual tools${RESET}\n"
        printf "    ${BOLD}${CYAN} 9${RESET})  Update Tools             ${DIM}— update all installed tools${RESET}\n"
        printf "    ${BOLD}${CYAN}10${RESET})  Update Wordlists         ${DIM}— git pull all wordlists${RESET}\n"
        printf "    ${BOLD}${CYAN}11${RESET})  Update Script            ${DIM}— git pull the toolkit repo${RESET}\n"
        printf "    ${RED}12${RESET})  Uninstall Everything     ${DIM}— remove all installed tools${RESET}\n"
        printf "    ${RED}13${RESET})  Selective Uninstall      ${DIM}— choose what to remove${RESET}\n"
        printf "    ${CYAN} 0${RESET})  Exit\n"
        printf "\n"
        read -rp "  Choice [0-13]: " MENU_CHOICE

        # Validate input
        if [[ "$MENU_CHOICE" =~ ^[0-9]+$ ]] && (( MENU_CHOICE >= 0 && MENU_CHOICE <= 13 )); then
            break
        fi
        printf "\n  ${RED}[!] Invalid input: '%s'. Please enter a number between 0 and 13.${RESET}\n\n" "$MENU_CHOICE"
    done
}

# ── Custom select sub-menu ─────────────────────────────────────────────────────

CUSTOM_MODE=""

show_custom_mode() {
    while true; do
        printf "\n  ${BOLD}Custom Select:${RESET}\n\n"
        printf "    ${CYAN}1${RESET})  By Category         ${DIM}— select entire categories${RESET}\n"
        printf "    ${CYAN}2${RESET})  By Individual Tool  ${DIM}— pick specific tools${RESET}\n"
        printf "    ${CYAN}0${RESET})  Back\n"
        printf "\n"
        read -rp "  Choice [0-2]: " CUSTOM_MODE

        if [[ "$CUSTOM_MODE" =~ ^[0-2]$ ]]; then
            break
        fi
        printf "\n  ${RED}[!] Invalid input: '%s'. Please enter 0, 1, or 2.${RESET}\n" "$CUSTOM_MODE"
    done
}

# ── Individual tool picker (multi-select with comma/range input) ───────────

SELECTED_TOOL_INDICES=()

show_tool_picker() {
    printf "\n  ${BOLD}Available tools:${RESET}\n"
    printf "  ${DIM}Enter numbers separated by commas or ranges (e.g. 1,3,8-15,31)${RESET}\n"
    printf "  ${DIM}Type ${RESET}all${DIM} for everything, or press Enter to go back.${RESET}\n"

    local i last_group="" col=0 num
    for (( i = 0; i < _REG_COUNT; i++ )); do
        if [[ "${_REG_GROUP[$i]}" != "$last_group" ]]; then
            (( col > 0 )) && printf "\n"
            printf "\n  ${BOLD}── %s ─────────────────────────────────────────────────${RESET}\n" "${_REG_GROUP[$i]}"
            last_group="${_REG_GROUP[$i]}"
            col=0
        fi
        num=$(( i + 1 ))
        printf "  ${CYAN}%3d${RESET}) %-18s" "$num" "${_REG_NAMES[$i]}"
        (( col++ ))
        if (( col >= 3 )); then
            printf "\n"
            col=0
        fi
    done
    (( col > 0 )) && printf "\n"
    printf "\n"

    local input
    read -rp "  Tools: " input

    SELECTED_TOOL_INDICES=()
    [[ -z "$input" ]] && return 1   # back

    if [[ "$input" == "all" ]]; then
        for (( i = 0; i < _REG_COUNT; i++ )); do
            SELECTED_TOOL_INDICES+=("$i")
        done
        return 0
    fi

    # Parse comma-separated numbers and ranges (e.g. 1,3,8-15)
    local IFS=','
    local token
    for token in $input; do
        token="${token// /}"  # strip spaces
        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            local start="${BASH_REMATCH[1]}" end="${BASH_REMATCH[2]}"
            for (( i = start; i <= end; i++ )); do
                if (( i >= 1 && i <= _REG_COUNT )); then
                    SELECTED_TOOL_INDICES+=("$(( i - 1 ))")
                fi
            done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            if (( token >= 1 && token <= _REG_COUNT )); then
                SELECTED_TOOL_INDICES+=("$(( token - 1 ))")
            fi
        fi
    done

    (( ${#SELECTED_TOOL_INDICES[@]} > 0 ))
}

# ── Uninstall select sub-menu ─────────────────────────────────────────────────

UNINSTALL_MODE=""

show_uninstall_mode() {
    while true; do
        printf "\n  ${BOLD}Selective Uninstall:${RESET}\n\n"
        printf "    ${CYAN}1${RESET})  By Category         ${DIM}— remove entire categories${RESET}\n"
        printf "    ${CYAN}2${RESET})  By Individual Tool  ${DIM}— pick specific tools to remove${RESET}\n"
        printf "    ${CYAN}0${RESET})  Back\n"
        printf "\n"
        read -rp "  Choice [0-2]: " UNINSTALL_MODE

        if [[ "$UNINSTALL_MODE" =~ ^[0-2]$ ]]; then
            break
        fi
        printf "\n  ${RED}[!] Invalid input: '%s'. Please enter 0, 1, or 2.${RESET}\n" "$UNINSTALL_MODE"
    done
}

# ── Confirmation prompt ─────────────────────────────────────────────────────

confirm() {
    local msg="${1:-Proceed?}"
    printf "  ${YELLOW}%s${RESET} [Y/n] " "$msg"
    local reply
    read -r reply
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

# ── Final summary box ───────────────────────────────────────────────────────

show_summary() {
    local title="${1:-Operation Complete}"
    printf "\n"
    printf "  ${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}\n"
    printf "  ${CYAN}║${RESET}   ${BOLD}%-53s${RESET}${CYAN}║${RESET}\n" "$title"
    printf "  ${CYAN}╠═══════════════════════════════════════════════════════════╣${RESET}\n"
    printf "  ${CYAN}║${RESET}   ${GREEN}${SYM_OK} Done:        %-5d${RESET}                                   ${CYAN}║${RESET}\n" "$PROGRESS_DONE"
    printf "  ${CYAN}║${RESET}   ${YELLOW}${SYM_SKIP} Skipped:     %-5d${RESET}                                   ${CYAN}║${RESET}\n" "$PROGRESS_SKIP"
    printf "  ${CYAN}║${RESET}   ${RED}${SYM_FAIL} Failed:      %-5d${RESET}                                   ${CYAN}║${RESET}\n" "$PROGRESS_FAIL"
    printf "  ${CYAN}╠═══════════════════════════════════════════════════════════╣${RESET}\n"
    printf "  ${CYAN}║${RESET}   ${DIM}Log: %-51s${RESET}${CYAN}║${RESET}\n" "$LOG_FILE"
    printf "  ${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}\n"

    if (( PROGRESS_FAIL > 0 )); then
        printf "\n  ${YELLOW}Tip: Check the log file for details on failures.${RESET}\n"
    fi
    if (( PROGRESS_DONE > 0 )); then
        printf "\n  ${DIM}Restart your shell or run:  source $(get_rc_file)${RESET}\n"
    fi
    printf "\n"
}
