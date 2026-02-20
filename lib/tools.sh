#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# lib/tools.sh — Tool registry + install / uninstall / update functions
# ─────────────────────────────────────────────────────────────────────────────

# ══════════════════════════════════════════════════════════════════════════════
#  TOOL REGISTRY — edit these to add / remove tools
# ══════════════════════════════════════════════════════════════════════════════

# ── Python tools (each gets its own venv in ~/tools/<name>) ──────────────────

PYTHON_PIP_TOOLS=(shodan waymore)   # installed via pip in venv
PYTHON_PIPX_TOOLS=(uro)             # installed via pipx

declare -A PYTHON_GIT_TOOLS=(
    [commix]="https://github.com/commixproject/commix.git"
    [sqlmap]="https://github.com/sqlmapproject/sqlmap.git"
    [ghauri]="https://github.com/r0oth3x49/ghauri.git"
    [SSTImap]="https://github.com/vladko312/SSTImap.git"
)

# ── Go tools ────────────────────────────────────────────────────────────────

declare -A GO_TOOLS=(
    [subfinder]="go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    [amass]="CGO_ENABLED=0 go install -v github.com/owasp-amass/amass/v5/cmd/amass@main"
    [ffuf]="go install github.com/ffuf/ffuf/v2@latest"
    [waybackurls]="go install github.com/tomnomnom/waybackurls@latest"
    [gau]="go install github.com/lc/gau/v2/cmd/gau@latest"
    [katana]="CGO_ENABLED=1 go install github.com/projectdiscovery/katana/cmd/katana@latest"
    [dnsx]="go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    [httpx]="go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
    [unfurl]="go install github.com/tomnomnom/unfurl@latest"
    [fallparams]="go install github.com/ImAyrix/fallparams@latest"
    [nuclei]="go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    [cookiemonster]="go install github.com/iangcarroll/cookiemonster/cmd/cookiemonster@latest"
    [sourcemapper]="go install github.com/denandz/sourcemapper@latest"
    [TInjA]="go install -v github.com/Hackmanit/TInjA@latest"
    [interactsh-client]="go install -v github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
)

# Sorted list for deterministic order
GO_TOOLS_ORDER=(subfinder amass ffuf waybackurls gau katana dnsx httpx unfurl
                fallparams nuclei cookiemonster sourcemapper TInjA interactsh-client)

# ── APT / Snap tools ────────────────────────────────────────────────────────

APT_TOOLS=(whois dnsutils hydra netcat-openbsd)
SNAP_TOOLS=(dalfox)

# ── Wordlists (~/wordlists/) ────────────────────────────────────────────────

declare -A WORDLIST_GIT=(
    [Bo0oM]="https://github.com/Bo0oM/fuzz.txt.git"
    [RobotsDisallowed]="https://github.com/danielmiessler/RobotsDisallowed.git"
    [my-wordlists]="https://github.com/shayanrsh/wordlist.git"
    [Auto_Wordlists]="https://github.com/carlospolop/Auto_Wordlists.git"
    [FuzzDB]="https://github.com/fuzzdb-project/fuzzdb.git"
    [nmap_vulners]="https://github.com/vulnersCom/nmap-vulners.git"
    [Commonspeak2]="https://github.com/assetnote/commonspeak2-wordlists.git"
    [api_wordlist]="https://github.com/chrislockard/api_wordlist.git"
)

WORDLIST_GIT_ORDER=(Bo0oM RobotsDisallowed my-wordlists Auto_Wordlists
                    FuzzDB nmap_vulners Commonspeak2 api_wordlist)

# ── Payloads ─────────────────────────────────────────────────────────────────

declare -A PAYLOAD_GIT=(
    [PayloadsAllTheThings]="https://github.com/swisskyrepo/PayloadsAllTheThings.git"
)

# ══════════════════════════════════════════════════════════════════════════════
#  COUNTING  (computed once, cached)
# ══════════════════════════════════════════════════════════════════════════════

_CNT_PYTHON=$(( ${#PYTHON_PIP_TOOLS[@]} + ${#PYTHON_PIPX_TOOLS[@]} + ${#PYTHON_GIT_TOOLS[@]} ))
_CNT_GO=$(( 1 + 2 + ${#GO_TOOLS[@]} ))   # go + rust + x8 + go_tools
_CNT_DOCKER=2
_CNT_APT=$(( ${#APT_TOOLS[@]} + ${#SNAP_TOOLS[@]} ))
_CNT_WORDLISTS=$(( 2 + ${#WORDLIST_GIT[@]} + ${#PAYLOAD_GIT[@]} ))
_CNT_ZSH=5   # zsh + oh-my-zsh + autosuggestions + syntax-highlighting + powerlevel10k
_CNT_ALL=$(( _CNT_PYTHON + _CNT_GO + _CNT_DOCKER + _CNT_APT + _CNT_WORDLISTS + _CNT_ZSH ))

count_python()    { echo $_CNT_PYTHON; }
count_go()        { echo $_CNT_GO; }
count_docker()    { echo $_CNT_DOCKER; }
count_apt()       { echo $_CNT_APT; }
count_wordlists() { echo $_CNT_WORDLISTS; }
count_zsh()       { echo $_CNT_ZSH; }
count_all()       { echo $_CNT_ALL; }

# ══════════════════════════════════════════════════════════════════════════════
#  MASTER TOOL REGISTRY  (for individual tool picker)
# ══════════════════════════════════════════════════════════════════════════════

_REG_NAMES=()    # display name
_REG_CAT=()      # install category tag
_REG_KEY=()      # extra data (URL, command, etc.)
_REG_GROUP=()    # display group header

_PYTHON_GIT_ORDER=(commix sqlmap ghauri SSTImap)

_reg() { _REG_NAMES+=("$1"); _REG_CAT+=("$2"); _REG_KEY+=("$3"); _REG_GROUP+=("$4"); }

for _t in "${PYTHON_PIP_TOOLS[@]}";    do _reg "$_t" py-pip      ""                            "Python";               done
for _t in "${PYTHON_PIPX_TOOLS[@]}";   do _reg "$_t" py-pipx     ""                            "Python";               done
for _t in "${_PYTHON_GIT_ORDER[@]}";   do _reg "$_t" py-git      "${PYTHON_GIT_TOOLS[$_t]}"    "Python";               done
for _t in "${GO_TOOLS_ORDER[@]}";      do _reg "$_t" go          "${GO_TOOLS[$_t]}"            "Go + Rust";            done
_reg "x8"        rust        ""                            "Go + Rust"
_reg "docker"    docker      ""                            "Docker"
_reg "jwt_tool"  docker-tool ""                            "Docker"
for _t in "${APT_TOOLS[@]}";           do _reg "$_t" apt         ""                            "APT / Snap";           done
for _t in "${SNAP_TOOLS[@]}";          do _reg "$_t" snap        ""                            "APT / Snap";           done
_reg "SecLists"   wl-seclists  ""                           "Wordlists & Payloads"
_reg "assetnote"  wl-assetnote ""                           "Wordlists & Payloads"
for _t in "${WORDLIST_GIT_ORDER[@]}";  do _reg "$_t" wl-git      "${WORDLIST_GIT[$_t]}"        "Wordlists & Payloads"; done
for _t in "${!PAYLOAD_GIT[@]}";        do _reg "$_t" payload     "${PAYLOAD_GIT[$_t]}"         "Wordlists & Payloads"; done

# ── Zsh + Oh My Zsh ──────────────────────────────────────────────────────────
ZSH_COMPONENTS_ORDER=(zsh oh-my-zsh zsh-autosuggestions zsh-syntax-highlighting powerlevel10k)

_reg "zsh"                      zsh-apt    ""  "Zsh + Oh My Zsh"
_reg "oh-my-zsh"                zsh-omz    ""  "Zsh + Oh My Zsh"
_reg "zsh-autosuggestions"      zsh-plugin ""  "Zsh + Oh My Zsh"
_reg "zsh-syntax-highlighting"  zsh-plugin ""  "Zsh + Oh My Zsh"
_reg "powerlevel10k"            zsh-theme  ""  "Zsh + Oh My Zsh"

unset -f _reg
unset _t

_REG_COUNT=${#_REG_NAMES[@]}

# ══════════════════════════════════════════════════════════════════════════════
#  INSTALL — GO LANGUAGE
# ══════════════════════════════════════════════════════════════════════════════

install_go_lang() {
    if cmd_exists go; then
        print_result "go (language)" skip
        return 0
    fi
    if ! cmd_exists snap; then
        sudo apt-get install -y -qq snapd >> "$LOG_FILE" 2>&1
    fi
    run_install "go (language)" "sudo snap install go --classic" || return 1

    local rc_file marker
    rc_file=$(get_rc_file)
    marker="# Go environment (toolkit)"
    if ! grep -qF "$marker" "$rc_file" 2>/dev/null; then
        {
            echo ""
            echo "$marker"
            echo 'export PATH=$PATH:/usr/local/go/bin'
            echo 'export PATH=$PATH:$(go env GOPATH)/bin'
        } >> "$rc_file"
    fi
    export PATH="$PATH:/snap/bin:/usr/local/go/bin"
    local gopath
    gopath=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
    export PATH="$PATH:${gopath}/bin"
    export GOPATH="$gopath"
    mkdir -p "${gopath}"/{bin,src,pkg} 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
#  INSTALL — RUST + x8
# ══════════════════════════════════════════════════════════════════════════════

install_rust_and_x8() {
    # ── Rust ────────────────────────────────────────────────────────────
    if cmd_exists cargo; then
        print_result "rust (language)" skip
    else
        run_install "rust (language)" \
            "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" || return 1
        # shellcheck disable=SC1091
        [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
        add_to_rc '. "$HOME/.cargo/env"'
        export PATH="$PATH:$HOME/.cargo/bin"
    fi

    # Build deps for x8
    sudo apt-get install -y -qq build-essential pkg-config libssl-dev >> "$LOG_FILE" 2>&1 || true

    # ── x8 ──────────────────────────────────────────────────────────────
    if cmd_exists x8; then
        print_result "x8" skip
    else
        # Ensure cargo is on PATH for this session
        [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
        run_install "x8" "cargo install x8" || true
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  INSTALL — GO TOOLS
# ══════════════════════════════════════════════════════════════════════════════

install_go_tools_category() {
    section_header "Go + Rust Tools" "$(count_go)"

    install_go_lang
    install_rust_and_x8

    if ! cmd_exists go; then
        log_error "Go is not installed — skipping Go tools"
        local t; for t in "${GO_TOOLS_ORDER[@]}"; do print_result "$t" fail; done
        section_footer "Go + Rust Tools"
        return 1
    fi

    sudo -v 2>/dev/null || true

    # ── Parallel Go installs (up to 4 at a time) ──────────────────────
    local MAX_PARALLEL=4
    local running=0
    declare -A bg_pids=()  # tool -> pid

    for tool in "${GO_TOOLS_ORDER[@]}"; do
        if cmd_exists "$tool"; then
            print_result "$tool" skip
            continue
        fi

        local cmd="${GO_TOOLS[$tool]}"
        log_debug "Parallel go install: $tool"
        eval "$cmd" >> "$LOG_FILE" 2>&1 &
        bg_pids[$tool]=$!
        (( running++ ))

        # When we hit the limit, wait for any one to finish
        if (( running >= MAX_PARALLEL )); then
            for t in "${!bg_pids[@]}"; do
                if ! kill -0 "${bg_pids[$t]}" 2>/dev/null; then
                    local rc=0
                    wait "${bg_pids[$t]}" || rc=$?
                    if (( rc == 0 )); then print_result "$t" done; else print_result "$t" fail; fi
                    unset "bg_pids[$t]"
                    (( running-- ))
                fi
            done
            # If all still running, block on any
            if (( running >= MAX_PARALLEL )); then
                wait -n 2>/dev/null || true
                for t in "${!bg_pids[@]}"; do
                    if ! kill -0 "${bg_pids[$t]}" 2>/dev/null; then
                        local rc=0
                        wait "${bg_pids[$t]}" || rc=$?
                        if (( rc == 0 )); then print_result "$t" done; else print_result "$t" fail; fi
                        unset "bg_pids[$t]"
                        (( running-- ))
                    fi
                done
            fi
        fi
    done

    # Wait for remaining
    for t in "${!bg_pids[@]}"; do
        local rc=0
        wait "${bg_pids[$t]}" || rc=$?
        if (( rc == 0 )); then print_result "$t" done; else print_result "$t" fail; fi
    done

    section_footer "Go + Rust Tools"
}

# ══════════════════════════════════════════════════════════════════════════════
#  INSTALL — PYTHON TOOLS  (venv per tool in ~/tools/)
# ══════════════════════════════════════════════════════════════════════════════

_python_venv_has_pkg() {
    local dir="$1" pkg="$2"
    [[ -x "$dir/venv/bin/python" ]] && "$dir/venv/bin/python" -m pip show "$pkg" >/dev/null 2>&1
}

_python_venv_marker_ok() {
    local dir="$1"
    [[ -f "$dir/.installed.ok" ]] && [[ -x "$dir/venv/bin/python" ]]
}

_install_python_venv_pip() {
    local name="$1"
    local dir="${TOOLS_DIR}/${name}"
    if _python_venv_has_pkg "$dir" "$name"; then
        print_result "$name" skip
        return 0
    fi
    # Clean up any corrupted/leftover directory from incomplete uninstall
    [[ -d "$dir" ]] && rm -rf "$dir" 2>/dev/null
    if run_steps "$name" done 3 \
        "Create venv" "mkdir -p '${dir}' && python3 -m venv '${dir}/venv'" \
        "Upgrade pip" "'${dir}/venv/bin/pip' install --upgrade pip -q" \
        "Install package" "'${dir}/venv/bin/pip' install '${name}' -q"; then
        # Create convenience symlink (non-fatal, runs only if install succeeded)
        [[ -x "${dir}/venv/bin/${name}" ]] && ln -sf "${dir}/venv/bin/${name}" "$HOME/.local/bin/${name}" 2>/dev/null || true
        : > "$dir/.installed.ok"
    fi
}

_install_python_venv_git() {
    local name="$1" url="$2"
    local dir="${TOOLS_DIR}/${name}"
    if [[ -d "$dir/.git" ]] && _python_venv_marker_ok "$dir"; then
        print_result "$name" skip
        return 0
    fi
    # Clean up any leftover directory from incomplete uninstall
    [[ -d "$dir" ]] && rm -rf "$dir" 2>/dev/null
    if run_steps "$name" done 5 \
        "Clone repository" "git clone --depth 1 '${url}' '${dir}'" \
        "Create venv" "python3 -m venv '${dir}/venv'" \
        "Upgrade pip" "'${dir}/venv/bin/pip' install --upgrade pip -q" \
        "Install requirements" "if [[ -f '${dir}/requirements.txt' ]]; then '${dir}/venv/bin/pip' install -r '${dir}/requirements.txt' -q; fi" \
        "Install package" "if [[ -f '${dir}/setup.py' ]]; then '${dir}/venv/bin/pip' install -e '${dir}' -q; fi; if [[ -f '${dir}/pyproject.toml' ]]; then '${dir}/venv/bin/pip' install -e '${dir}' -q; fi"; then
        : > "$dir/.installed.ok"
    fi
}

_install_python_pipx() {
    local name="$1"
    if cmd_exists "$name"; then
        print_result "$name" skip
        return 0
    fi
    run_install "$name" "pipx install $name" || true
}

install_python_tools_category() {
    section_header "Python Tools" "$(count_python)"

    mkdir -p "$TOOLS_DIR" "$HOME/.local/bin" 2>/dev/null || true
    export PATH="$PATH:$HOME/.local/bin"

    local tool
    for tool in "${PYTHON_PIP_TOOLS[@]}"; do
        _install_python_venv_pip "$tool"
    done
    for tool in "${PYTHON_PIPX_TOOLS[@]}"; do
        _install_python_pipx "$tool"
    done
    local url
    for tool in "${!PYTHON_GIT_TOOLS[@]}"; do
        url="${PYTHON_GIT_TOOLS[$tool]}"
        _install_python_venv_git "$tool" "$url"
    done

    section_footer "Python Tools"
}

# ══════════════════════════════════════════════════════════════════════════════
#  INSTALL — DOCKER + JWT_TOOL
# ══════════════════════════════════════════════════════════════════════════════

_install_docker_engine() {
    if cmd_exists docker && docker --version 2>/dev/null | grep -q "Docker"; then
        print_result "docker" skip
        return 0
    fi
    run_install "docker" "
        sudo apt-get remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null || true
        sudo apt-get update -qq
        sudo apt-get install -y -qq ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        . /etc/os-release
        ARCH=\$(dpkg --print-architecture)
        CODENAME=\"\${UBUNTU_CODENAME:-\${VERSION_CODENAME}}\"
        printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu %s stable\\n' \"\$ARCH\" \"\$CODENAME\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl enable docker --now 2>/dev/null || true
        sudo usermod -aG docker \"\$(whoami)\" 2>/dev/null || true
    " || true
}

_install_jwt_tool() {
    local rc_file
    rc_file=$(get_rc_file)
    local jwt_alias='alias jwt_tool='\''docker run -it --network "host" --rm -v "${PWD}:/tmp" -v "${HOME}/.jwt_tool:/root/.jwt_tool" ticarpi/jwt_tool'\'''
    if grep -qF "jwt_tool" "$rc_file" 2>/dev/null; then
        print_result "jwt_tool (alias)" skip
        return 0
    fi
    # Ensure Docker is available
    if ! cmd_exists docker; then
        _install_docker_engine
    fi
    run_install "jwt_tool (alias)" "
        docker pull ticarpi/jwt_tool && \
        echo '${jwt_alias}' >> '${rc_file}' && \
        mkdir -p '${HOME}/.jwt_tool'
    " || true
}

install_docker_category() {
    section_header "Docker" "$(count_docker)"
    sudo -v 2>/dev/null || true
    _install_docker_engine
    _install_jwt_tool
    section_footer "Docker"
}

# ══════════════════════════════════════════════════════════════════════════════
#  INSTALL — APT / SNAP TOOLS
# ══════════════════════════════════════════════════════════════════════════════

install_apt_snap_category() {
    section_header "APT / Snap Tools" "$(count_apt)"

    sudo apt-get update -qq >> "$LOG_FILE" 2>&1 || true

    # ── Batch-install all missing APT packages in one command ──────────
    local missing=() already=() tool
    for tool in "${APT_TOOLS[@]}"; do
        if is_apt_installed "$tool"; then
            already+=("$tool")
        else
            missing+=("$tool")
        fi
    done
    for tool in "${already[@]}"; do
        print_result "$tool" skip
    done
    if (( ${#missing[@]} > 0 )); then
        # Run batch install with spinner but without counting (individual results counted below)
        run_bg_with_spinner "apt: ${missing[*]}" "sudo apt-get install -y -qq ${missing[*]}"
        # Report individual results (these are what count toward progress)
        for tool in "${missing[@]}"; do
            if is_apt_installed "$tool"; then
                print_result "$tool" done
            else
                print_result "$tool" fail
            fi
        done
    fi

    # Snap tools
    if ! cmd_exists snap; then
        sudo apt-get install -y -qq snapd >> "$LOG_FILE" 2>&1
    fi
    for tool in "${SNAP_TOOLS[@]}"; do
        if is_snap_installed "$tool"; then
            print_result "$tool" skip
        else
            run_install "$tool" "sudo snap install $tool" || true
        fi
    done

    section_footer "APT / Snap Tools"
}

# ══════════════════════════════════════════════════════════════════════════════
#  INSTALL — WORDLISTS & PAYLOADS
# ══════════════════════════════════════════════════════════════════════════════

install_wordlists_category() {
    section_header "Wordlists & Payloads" "$(count_wordlists)"

    mkdir -p "$WORDLISTS_DIR" 2>/dev/null || true

    # ── SecLists (zip download — requires unzip) ────────────────────────
    if [[ -d "$WORDLISTS_DIR/SecLists-master" ]]; then
        print_result "SecLists" skip
    else
        cmd_exists unzip || sudo apt-get install -y -qq unzip >> "$LOG_FILE" 2>&1
        run_install "SecLists" "
            cd '$WORDLISTS_DIR' && \
            wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip && \
            unzip -qo SecList.zip && \
            rm -f SecList.zip
        " || true
    fi

    # ── Assetnote (wget mirror) ────────────────────────────────────────
    if [[ -d "$WORDLISTS_DIR/data" ]]; then
        print_result "assetnote" skip
    else
        run_install "assetnote" "
            cd '$WORDLISTS_DIR' && \
            wget -r --no-parent -R 'index.html*' https://wordlists-cdn.assetnote.io/data/ -nH -e robots=off
        " || true
    fi

    # ── Git-cloned wordlists ──────────────────────────────────────────
    local name url target
    for name in "${WORDLIST_GIT_ORDER[@]}"; do
        url="${WORDLIST_GIT[$name]}"
        target="$WORDLISTS_DIR/$name"
        if [[ -d "$target/.git" ]]; then
            print_result "$name" skip
        else
            run_install "$name" "git clone --depth 1 '${url}' '${target}'" || true
        fi
    done

    # ── Payloads ──────────────────────────────────────────────────────
    local pname purl ptarget
    for pname in "${!PAYLOAD_GIT[@]}"; do
        purl="${PAYLOAD_GIT[$pname]}"
        ptarget="$WORDLISTS_DIR/$pname"
        if [[ -d "$ptarget/.git" ]]; then
            print_result "$pname" skip
        else
            run_install "$pname" "git clone --depth 1 '${purl}' '${ptarget}'" || true
        fi
    done

    section_footer "Wordlists & Payloads"
}

# ══════════════════════════════════════════════════════════════════════════════
#  INSTALL — ZSH + OH MY ZSH
# ══════════════════════════════════════════════════════════════════════════════

_configure_zshrc() {
    if [[ ! -f "$HOME/.zshrc" ]]; then
        log_debug "No .zshrc found, skipping configuration"
        return 0
    fi

    # Set theme
    sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc" 2>/dev/null || true

    # Set plugins
    sed -i 's|^plugins=.*|plugins=(git zsh-autosuggestions zsh-syntax-highlighting)|' "$HOME/.zshrc" 2>/dev/null || true

    # Copy p10k config
    if [[ -f "$SCRIPT_DIR/.p10k.zsh" ]]; then
        cp "$SCRIPT_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
    fi

    # Source p10k config
    if ! grep -qF '.p10k.zsh' "$HOME/.zshrc" 2>/dev/null; then
        echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> "$HOME/.zshrc"
    fi

    # Change default shell to zsh
    if cmd_exists zsh; then
        sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null || true
    fi

    log_debug "Configured .zshrc with powerlevel10k theme and plugins"
}

install_zsh_category() {
    section_header "Zsh + Oh My Zsh" "$(count_zsh)"

    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # 1. Install zsh + dependencies
    if cmd_exists zsh; then
        print_result "zsh" skip
    else
        run_install "zsh" "sudo apt-get install -y -qq zsh git fonts-font-awesome" || true
    fi

    # 2. Install Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_result "oh-my-zsh" skip
    else
        run_install "oh-my-zsh" "RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended" || true
    fi

    # Update zsh_custom after oh-my-zsh install
    zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # 3. Install zsh-autosuggestions
    if [[ -d "${zsh_custom}/plugins/zsh-autosuggestions" ]]; then
        print_result "zsh-autosuggestions" skip
    else
        run_install "zsh-autosuggestions" "git clone https://github.com/zsh-users/zsh-autosuggestions '${zsh_custom}/plugins/zsh-autosuggestions'" || true
    fi

    # 4. Install zsh-syntax-highlighting
    if [[ -d "${zsh_custom}/plugins/zsh-syntax-highlighting" ]]; then
        print_result "zsh-syntax-highlighting" skip
    else
        run_install "zsh-syntax-highlighting" "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git '${zsh_custom}/plugins/zsh-syntax-highlighting'" || true
    fi

    # 5. Install powerlevel10k
    if [[ -d "${zsh_custom}/themes/powerlevel10k" ]]; then
        print_result "powerlevel10k" skip
    else
        run_install "powerlevel10k" "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git '${zsh_custom}/themes/powerlevel10k'" || true
    fi

    # Configure .zshrc, p10k, default shell
    _configure_zshrc

    section_footer "Zsh + Oh My Zsh"
}

# ══════════════════════════════════════════════════════════════════════════════
#  ORCHESTRATORS — INSTALL
# ══════════════════════════════════════════════════════════════════════════════

install_all() {
    local total
    total=$(count_all)
    progress_init "$total"
    printf "  ${BOLD}Full install — %d items${RESET}\n" "$total"
    confirm "Continue?" || { log_info "Aborted."; exit 0; }

    install_python_tools_category
    install_go_tools_category
    install_docker_category
    install_apt_snap_category
    install_wordlists_category
    install_zsh_category
}

install_python_suite()    { progress_init "$(count_python)";    install_python_tools_category; }
install_go_suite()        { progress_init "$(count_go)";        install_go_tools_category; }
install_docker_suite()    { progress_init "$(count_docker)";    install_docker_category; }
install_apt_suite()       { progress_init "$(count_apt)";       install_apt_snap_category; }
install_wordlists_suite() { progress_init "$(count_wordlists)"; install_wordlists_category; }
install_zsh_suite()       { progress_init "$(count_zsh)";       install_zsh_category; }

install_custom() {
    show_custom_mode

    case "$CUSTOM_MODE" in
        1) _install_custom_by_category ;;
        2)
            if show_tool_picker; then
                install_selected_tools
            else
                log_info "No tools selected."
            fi
            ;;
        0|"") return 0 ;;
        *)  log_error "Invalid choice."; return 1 ;;
    esac
}

_install_custom_by_category() {
    printf "\n  ${BOLD}Select categories to install:${RESET}\n\n"
    local total=0

    local do_py=0 do_go=0 do_docker=0 do_apt=0 do_wl=0 do_zsh=0
    if confirm "  Python tools? ($(count_python) tools)";   then do_py=1;     (( total += $(count_python) ));    fi
    if confirm "  Go + Rust tools? ($(count_go) tools)";    then do_go=1;     (( total += $(count_go) ));        fi
    if confirm "  Docker + tools? ($(count_docker) tools)"; then do_docker=1; (( total += $(count_docker) ));    fi
    if confirm "  APT/Snap tools? ($(count_apt) tools)";    then do_apt=1;    (( total += $(count_apt) ));       fi
    if confirm "  Wordlists & Payloads? ($(count_wordlists) items)"; then do_wl=1; (( total += $(count_wordlists) )); fi
    if confirm "  Zsh + Oh My Zsh? ($(count_zsh) items)"; then do_zsh=1; (( total += $(count_zsh) )); fi

    if (( total == 0 )); then log_warn "Nothing selected."; return 0; fi
    progress_init "$total"

    (( do_py ))     && install_python_tools_category
    (( do_go ))     && install_go_tools_category
    (( do_docker )) && install_docker_category
    (( do_apt ))    && install_apt_snap_category
    (( do_wl ))     && install_wordlists_category
    (( do_zsh ))    && install_zsh_category
}

# ══════════════════════════════════════════════════════════════════════════════
#  INDIVIDUAL TOOL INSTALLER  (for custom picker)
# ══════════════════════════════════════════════════════════════════════════════

_install_single_tool() {
    local idx="$1"
    local name="${_REG_NAMES[$idx]}"
    local cat="${_REG_CAT[$idx]}"
    local key="${_REG_KEY[$idx]}"

    case "$cat" in
        py-pip)      _install_python_venv_pip "$name" ;;
        py-pipx)     _install_python_pipx "$name" ;;
        py-git)      _install_python_venv_git "$name" "$key" ;;
        go)
            if ! cmd_exists go; then
                print_result "$name" fail
            elif cmd_exists "$name"; then
                print_result "$name" skip
            else
                run_install "$name" "$key" || true
            fi
            ;;
        rust)        install_rust_and_x8 ;;
        docker)      _install_docker_engine ;;
        docker-tool) _install_jwt_tool ;;
        apt)
            if is_apt_installed "$name"; then
                print_result "$name" skip
            else
                run_install "$name" "sudo apt-get install -y -qq $name" || true
            fi
            ;;
        snap)
            if ! cmd_exists snap; then
                sudo apt-get install -y -qq snapd >> "$LOG_FILE" 2>&1
            fi
            if is_snap_installed "$name"; then
                print_result "$name" skip
            else
                run_install "$name" "sudo snap install $name" || true
            fi
            ;;
        wl-seclists)
            mkdir -p "$WORDLISTS_DIR" 2>/dev/null || true
            if [[ -d "$WORDLISTS_DIR/SecLists-master" ]]; then
                print_result "SecLists" skip
            else
                cmd_exists unzip || sudo apt-get install -y -qq unzip >> "$LOG_FILE" 2>&1
                run_install "SecLists" "
                    cd '$WORDLISTS_DIR' && \\
                    wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip && \\
                    unzip -qo SecList.zip && rm -f SecList.zip
                " || true
            fi
            ;;
        wl-assetnote)
            mkdir -p "$WORDLISTS_DIR" 2>/dev/null || true
            if [[ -d "$WORDLISTS_DIR/data" ]]; then
                print_result "assetnote" skip
            else
                run_install "assetnote" "
                    cd '$WORDLISTS_DIR' && \\
                    wget -r --no-parent -R 'index.html*' https://wordlists-cdn.assetnote.io/data/ -nH -e robots=off
                " || true
            fi
            ;;
        wl-git)
            mkdir -p "$WORDLISTS_DIR" 2>/dev/null || true
            local target="$WORDLISTS_DIR/$name"
            if [[ -d "$target/.git" ]]; then
                print_result "$name" skip
            else
                run_install "$name" "git clone --depth 1 '$key' '$target'" || true
            fi
            ;;
        payload)
            mkdir -p "$WORDLISTS_DIR" 2>/dev/null || true
            local target="$WORDLISTS_DIR/$name"
            if [[ -d "$target/.git" ]]; then
                print_result "$name" skip
            else
                run_install "$name" "git clone --depth 1 '$key' '$target'" || true
            fi
            ;;
        zsh-apt)
            if cmd_exists zsh; then
                print_result "zsh" skip
            else
                run_install "zsh" "sudo apt-get install -y -qq zsh git fonts-font-awesome" || true
            fi
            ;;
        zsh-omz)
            if [[ -d "$HOME/.oh-my-zsh" ]]; then
                print_result "oh-my-zsh" skip
            else
                run_install "oh-my-zsh" "RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended" || true
            fi
            ;;
        zsh-plugin)
            local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
            local plug_dir="${zsh_custom}/plugins/${name}"
            if [[ -d "$plug_dir" ]]; then
                print_result "$name" skip
            else
                local plug_url=""
                case "$name" in
                    zsh-autosuggestions)      plug_url="https://github.com/zsh-users/zsh-autosuggestions" ;;
                    zsh-syntax-highlighting)  plug_url="https://github.com/zsh-users/zsh-syntax-highlighting.git" ;;
                esac
                run_install "$name" "git clone '$plug_url' '$plug_dir'" || true
            fi
            ;;
        zsh-theme)
            local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
            if [[ -d "${zsh_custom}/themes/powerlevel10k" ]]; then
                print_result "powerlevel10k" skip
            else
                run_install "powerlevel10k" "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git '${zsh_custom}/themes/powerlevel10k'" || true
            fi
            _configure_zshrc
            ;;
    esac
}

install_selected_tools() {
    local indices=("${SELECTED_TOOL_INDICES[@]}")

    # Deduplicate
    local -A seen=()
    local unique=()
    local idx
    for idx in "${indices[@]}"; do
        if [[ -z "${seen[$idx]:-}" ]]; then
            seen[$idx]=1
            unique+=("$idx")
        fi
    done

    if (( ${#unique[@]} == 0 )); then
        log_warn "Nothing selected."
        return 0
    fi

    # Detect prerequisite needs
    local need_go=0 need_rust=0 need_docker_pre=0
    local need_python=0 need_apt_update=0
    local has_docker=0

    for idx in "${unique[@]}"; do
        case "${_REG_CAT[$idx]}" in
            go)               need_go=1 ;;
            rust)             need_rust=1 ;;
            docker)           has_docker=1 ;;
            docker-tool)      need_docker_pre=1 ;;
            py-pip|py-pipx|py-git) need_python=1 ;;
            apt|snap)         need_apt_update=1 ;;
        esac
    done

    # If docker is also selected, no extra prereq needed
    (( has_docker )) && need_docker_pre=0

    # Calculate total — only count prerequisites that actually need installation
    local total=${#unique[@]}
    local go_prereq_needed=0 rust_prereq_needed=0 docker_prereq_needed=0
    if (( need_go )) && ! cmd_exists go; then
        go_prereq_needed=1; (( total++ ))
    fi
    if (( need_rust )) && ! cmd_exists cargo; then
        rust_prereq_needed=1; (( total++ ))
    fi
    if (( need_docker_pre )) && ! cmd_exists docker; then
        docker_prereq_needed=1; (( total++ ))
    fi

    # Show selection summary
    printf "\n  ${BOLD}Selected %d tools:${RESET} " "${#unique[@]}"
    local names=""
    for idx in "${unique[@]}"; do names+="${_REG_NAMES[$idx]}, "; done
    printf "${DIM}%s${RESET}\n" "${names%, }"

    (( go_prereq_needed ))     && printf "  ${DIM}+ go (language) — required by Go tools${RESET}\n"
    (( rust_prereq_needed ))   && printf "  ${DIM}+ rust — required by x8${RESET}\n"
    (( docker_prereq_needed )) && printf "  ${DIM}+ docker — required by jwt_tool${RESET}\n"
    printf "\n"

    confirm "Install these ${total} items?" || { log_info "Aborted."; return 0; }

    progress_init "$total"

    # Prerequisites — only install and count if not already present
    (( need_python )) && { mkdir -p "$TOOLS_DIR" "$HOME/.local/bin" 2>/dev/null || true; export PATH="$PATH:$HOME/.local/bin"; }
    if (( need_go )); then
        if (( go_prereq_needed )); then
            install_go_lang
        else
            # Ensure PATH is set up even though go is already installed
            export PATH="$PATH:/snap/bin:/usr/local/go/bin"
            local _gopath
            _gopath=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
            export PATH="$PATH:${_gopath}/bin"
            export GOPATH="$_gopath"
        fi
    fi
    (( need_apt_update )) && { sudo apt-get update -qq >> "$LOG_FILE" 2>&1 || true; }

    # Install each selected tool
    for idx in "${unique[@]}"; do
        _install_single_tool "$idx"
    done
}

# ══════════════════════════════════════════════════════════════════════════════
#  UNINSTALL
# ══════════════════════════════════════════════════════════════════════════════

uninstall_all() {
    printf "\n  ${RED}${BOLD}⚠  This will remove ALL tools installed by this toolkit.${RESET}\n\n"
    confirm "Are you sure?" || { log_info "Aborted."; return 0; }

    local total
    total=$(count_all)
    progress_init "$total"

    section_header "Uninstalling Python Tools" "$(count_python)"

    # Python venv tools
    local tool
    for tool in "${PYTHON_PIP_TOOLS[@]}"; do
        if [[ -d "$TOOLS_DIR/$tool" ]] || [[ -L "$HOME/.local/bin/$tool" ]]; then
            run_action "$tool" removed "rm -rf '${TOOLS_DIR}/${tool}'; rm -f '$HOME/.local/bin/$tool'" || true
        else
            print_result "$tool" skip
        fi
    done
    # pipx tools
    for tool in "${PYTHON_PIPX_TOOLS[@]}"; do
        if cmd_exists "$tool"; then
            run_action "$tool" removed "pipx uninstall $tool" || true
        else
            print_result "$tool" skip
        fi
    done
    # git python tools
    for tool in "${!PYTHON_GIT_TOOLS[@]}"; do
        if [[ -d "$TOOLS_DIR/$tool" ]] || [[ -L "$HOME/.local/bin/$tool" ]]; then
            run_action "$tool" removed "rm -rf '${TOOLS_DIR}/${tool}'; rm -f '$HOME/.local/bin/$tool'" || true
        else
            print_result "$tool" skip
        fi
    done
    section_footer "Python Tools"

    section_header "Uninstalling Go + Rust Tools" "$(count_go)"

    # Go tools (binaries in GOPATH/bin)
    local gopath
    gopath=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
    for tool in "${GO_TOOLS_ORDER[@]}"; do
        if [[ -f "$gopath/bin/$tool" ]]; then
            run_action "$tool" removed "rm -f '${gopath}/bin/${tool}'" || true
        else
            print_result "$tool" skip
        fi
    done
    # x8
    if cmd_exists x8; then
        run_action "x8" removed "cargo uninstall x8" || true
    else
        print_result "x8" skip
    fi
    # Go itself
    if is_snap_installed go; then
        run_action "go (language)" removed "sudo snap remove go" || true
        remove_from_rc "# Go environment (toolkit)"
        remove_from_rc '/usr/local/go/bin'
        remove_from_rc 'go env GOPATH'
    else
        print_result "go (language)" skip
    fi
    section_footer "Go + Rust Tools"

    section_header "Uninstalling Docker" "$(count_docker)"
    # JWT tool alias
    local rc_file
    rc_file=$(get_rc_file)
    if grep -qF "jwt_tool" "$rc_file" 2>/dev/null; then
        run_action "jwt_tool (alias)" removed "
            sed -i '/jwt_tool/d' '${rc_file}' && \
            docker rmi ticarpi/jwt_tool 2>/dev/null || true && \
            rm -rf '$HOME/.jwt_tool'
        " || true
    else
        print_result "jwt_tool (alias)" skip
    fi
    # Docker
    if cmd_exists docker; then
        run_action "docker" removed "
            sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true && \
            sudo rm -rf /var/lib/docker /var/lib/containerd && \
            sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.sources /etc/apt/keyrings/docker.gpg /etc/apt/keyrings/docker.asc
        " || true
    else
        print_result "docker" skip
    fi
    section_footer "Docker"

    section_header "Uninstalling APT / Snap Tools" "$(count_apt)"
    for tool in "${APT_TOOLS[@]}"; do
        if is_apt_installed "$tool"; then
            run_action "$tool" removed "sudo apt-get purge -y -qq $tool" || true
        else
            print_result "$tool" skip
        fi
    done
    for tool in "${SNAP_TOOLS[@]}"; do
        if is_snap_installed "$tool"; then
            run_action "$tool" removed "sudo snap remove $tool" || true
        else
            print_result "$tool" skip
        fi
    done
    section_footer "APT / Snap Tools"

    section_header "Removing Wordlists & Payloads" "$(count_wordlists)"
    if [[ -d "$WORDLISTS_DIR" ]]; then
        run_action "~/wordlists" removed "rm -rf '$WORDLISTS_DIR'" || true
        # Count all wordlist items as done since we removed the whole dir
        local wl_remain=$(( $(count_wordlists) - 1 ))
        (( PROGRESS_DONE += wl_remain )) || true
    else
        print_result "~/wordlists" skip
        local wl_remain=$(( $(count_wordlists) - 1 ))
        (( PROGRESS_SKIP += wl_remain )) || true
    fi
    section_footer "Wordlists & Payloads"

    section_header "Uninstalling Zsh + Oh My Zsh" "$(count_zsh)"
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    # powerlevel10k
    if [[ -d "${zsh_custom}/themes/powerlevel10k" ]]; then
        run_action "powerlevel10k" removed "rm -rf '${zsh_custom}/themes/powerlevel10k'; rm -f '$HOME/.p10k.zsh'" || true
    else
        print_result "powerlevel10k" skip
    fi
    # zsh-syntax-highlighting
    if [[ -d "${zsh_custom}/plugins/zsh-syntax-highlighting" ]]; then
        run_action "zsh-syntax-highlighting" removed "rm -rf '${zsh_custom}/plugins/zsh-syntax-highlighting'" || true
    else
        print_result "zsh-syntax-highlighting" skip
    fi
    # zsh-autosuggestions
    if [[ -d "${zsh_custom}/plugins/zsh-autosuggestions" ]]; then
        run_action "zsh-autosuggestions" removed "rm -rf '${zsh_custom}/plugins/zsh-autosuggestions'" || true
    else
        print_result "zsh-autosuggestions" skip
    fi
    # oh-my-zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        run_action "oh-my-zsh" removed "rm -rf '$HOME/.oh-my-zsh'; rm -f '$HOME/.zshrc'" || true
    else
        print_result "oh-my-zsh" skip
    fi
    # zsh itself
    if cmd_exists zsh && is_apt_installed zsh; then
        run_action "zsh" removed "sudo chsh -s /bin/bash \$(whoami) 2>/dev/null; sudo apt-get purge -y -qq zsh fonts-font-awesome" || true
    else
        print_result "zsh" skip
    fi
    section_footer "Zsh + Oh My Zsh"

    sudo apt-get autoremove -y -qq >> "$LOG_FILE" 2>&1 || true
}

_uninstall_single_tool() {
    local idx="$1"
    local name="${_REG_NAMES[$idx]}"
    local cat="${_REG_CAT[$idx]}"

    case "$cat" in
        py-pip)
            if [[ -d "$TOOLS_DIR/$name" ]] || [[ -L "$HOME/.local/bin/$name" ]]; then
                run_action "$name" removed "rm -rf '${TOOLS_DIR}/${name}'; rm -f '$HOME/.local/bin/$name'" || true
            else print_result "$name" skip; fi
            ;;
        py-pipx)
            if cmd_exists "$name"; then
                run_action "$name" removed "pipx uninstall $name" || true
            else print_result "$name" skip; fi
            ;;
        py-git)
            if [[ -d "$TOOLS_DIR/$name" ]]; then
                run_action "$name" removed "rm -rf '${TOOLS_DIR}/${name}'; rm -f '$HOME/.local/bin/$name'" || true
            else print_result "$name" skip; fi
            ;;
        go)
            local gopath
            gopath=$(go env GOPATH 2>/dev/null || echo "$HOME/go")
            if [[ -f "$gopath/bin/$name" ]]; then
                run_action "$name" removed "rm -f '${gopath}/bin/${name}'" || true
            else print_result "$name" skip; fi
            ;;
        rust)
            if cmd_exists x8; then
                run_action "x8" removed "cargo uninstall x8" || true
            else print_result "x8" skip; fi
            ;;
        docker)
            if cmd_exists docker; then
                run_action "docker" removed "
                    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true && \
                    sudo rm -rf /var/lib/docker /var/lib/containerd && \
                    sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.sources /etc/apt/keyrings/docker.gpg /etc/apt/keyrings/docker.asc
                " || true
            else print_result "docker" skip; fi
            ;;
        docker-tool)
            local rc_file
            rc_file=$(get_rc_file)
            if grep -qF "jwt_tool" "$rc_file" 2>/dev/null; then
                run_action "jwt_tool (alias)" removed "
                    sed -i '/jwt_tool/d' '${rc_file}' && \
                    docker rmi ticarpi/jwt_tool 2>/dev/null || true && \
                    rm -rf '$HOME/.jwt_tool'
                " || true
            else print_result "jwt_tool" skip; fi
            ;;
        apt)
            if is_apt_installed "$name"; then
                run_action "$name" removed "sudo apt-get purge -y -qq $name" || true
            else print_result "$name" skip; fi
            ;;
        snap)
            if is_snap_installed "$name"; then
                run_action "$name" removed "sudo snap remove $name" || true
            else print_result "$name" skip; fi
            ;;
        wl-seclists)
            if [[ -d "$WORDLISTS_DIR/SecLists-master" ]]; then
                run_action "SecLists" removed "rm -rf '$WORDLISTS_DIR/SecLists-master'" || true
            else print_result "SecLists" skip; fi
            ;;
        wl-assetnote)
            if [[ -d "$WORDLISTS_DIR/data" ]]; then
                run_action "assetnote" removed "rm -rf '$WORDLISTS_DIR/data'" || true
            else print_result "assetnote" skip; fi
            ;;
        wl-git)
            if [[ -d "$WORDLISTS_DIR/$name" ]]; then
                run_action "$name" removed "rm -rf '$WORDLISTS_DIR/$name'" || true
            else print_result "$name" skip; fi
            ;;
        payload)
            if [[ -d "$WORDLISTS_DIR/$name" ]]; then
                run_action "$name" removed "rm -rf '$WORDLISTS_DIR/$name'" || true
            else print_result "$name" skip; fi
            ;;
        zsh-apt)
            if cmd_exists zsh && is_apt_installed zsh; then
                run_action "zsh" removed "sudo chsh -s /bin/bash \$(whoami) 2>/dev/null; sudo apt-get purge -y -qq zsh fonts-font-awesome" || true
            else print_result "zsh" skip; fi
            ;;
        zsh-omz)
            if [[ -d "$HOME/.oh-my-zsh" ]]; then
                run_action "oh-my-zsh" removed "rm -rf '$HOME/.oh-my-zsh'; rm -f '$HOME/.zshrc'" || true
            else print_result "oh-my-zsh" skip; fi
            ;;
        zsh-plugin)
            local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
            if [[ -d "${zsh_custom}/plugins/${name}" ]]; then
                run_action "$name" removed "rm -rf '${zsh_custom}/plugins/${name}'" || true
            else print_result "$name" skip; fi
            ;;
        zsh-theme)
            local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
            if [[ -d "${zsh_custom}/themes/powerlevel10k" ]]; then
                run_action "powerlevel10k" removed "rm -rf '${zsh_custom}/themes/powerlevel10k'; rm -f '$HOME/.p10k.zsh'" || true
            else print_result "powerlevel10k" skip; fi
            ;;
    esac
}

uninstall_selected_tools() {
    local indices=("${SELECTED_TOOL_INDICES[@]}")

    # Deduplicate
    local -A seen=()
    local unique=()
    local idx
    for idx in "${indices[@]}"; do
        if [[ -z "${seen[$idx]:-}" ]]; then
            seen[$idx]=1
            unique+=("$idx")
        fi
    done

    if (( ${#unique[@]} == 0 )); then
        log_warn "Nothing selected."
        return 0
    fi

    local total=${#unique[@]}

    printf "\n  ${RED}${BOLD}Selected %d tools to remove:${RESET} " "$total"
    local names=""
    for idx in "${unique[@]}"; do names+="${_REG_NAMES[$idx]}, "; done
    printf "${DIM}%s${RESET}\n\n" "${names%, }"

    confirm "Remove these ${total} items?" || { log_info "Aborted."; return 0; }

    progress_init "$total"

    for idx in "${unique[@]}"; do
        _uninstall_single_tool "$idx"
    done

    sudo apt-get autoremove -y -qq >> "$LOG_FILE" 2>&1 || true
}

_uninstall_by_category() {
    printf "\n  ${BOLD}Select categories to uninstall:${RESET}\n\n"
    local total=0

    local do_py=0 do_go=0 do_docker=0 do_apt=0 do_wl=0 do_zsh=0
    if confirm "  Python tools? ($(count_python) tools)";   then do_py=1;     (( total += _CNT_PYTHON ));    fi
    if confirm "  Go + Rust tools? ($(count_go) tools)";    then do_go=1;     (( total += _CNT_GO ));        fi
    if confirm "  Docker + tools? ($(count_docker) tools)"; then do_docker=1; (( total += _CNT_DOCKER ));    fi
    if confirm "  APT/Snap tools? ($(count_apt) tools)";    then do_apt=1;    (( total += _CNT_APT ));       fi
    if confirm "  Wordlists & Payloads? ($(count_wordlists) items)"; then do_wl=1; (( total += _CNT_WORDLISTS )); fi
    if confirm "  Zsh + Oh My Zsh? ($(count_zsh) items)"; then do_zsh=1; (( total += _CNT_ZSH )); fi

    if (( total == 0 )); then log_warn "Nothing selected."; return 0; fi
    progress_init "$total"

    # Build list of matching registry indices and uninstall
    local i
    for (( i = 0; i < _REG_COUNT; i++ )); do
        case "${_REG_CAT[$i]}" in
            py-pip|py-pipx|py-git) (( do_py ))     && _uninstall_single_tool "$i" ;;
            go|rust)               (( do_go ))      && _uninstall_single_tool "$i" ;;
            docker|docker-tool)    (( do_docker ))  && _uninstall_single_tool "$i" ;;
            apt|snap)              (( do_apt ))     && _uninstall_single_tool "$i" ;;
            wl-seclists|wl-assetnote|wl-git|payload) (( do_wl )) && _uninstall_single_tool "$i" ;;
            zsh-apt|zsh-omz|zsh-plugin|zsh-theme) (( do_zsh )) && _uninstall_single_tool "$i" ;;
        esac
    done

    # Handle Go language itself if Go category selected
    if (( do_go )); then
        if is_snap_installed go; then
            run_action "go (language)" removed "sudo snap remove go" || true
            remove_from_rc "# Go environment (toolkit)"
            remove_from_rc '/usr/local/go/bin'
            remove_from_rc 'go env GOPATH'
        else
            print_result "go (language)" skip
        fi
    fi

    sudo apt-get autoremove -y -qq >> "$LOG_FILE" 2>&1 || true
}

uninstall_custom() {
    show_uninstall_mode

    case "$UNINSTALL_MODE" in
        1) _uninstall_by_category ;;
        2)
            if show_tool_picker; then
                uninstall_selected_tools
            else
                log_info "No tools selected."
            fi
            ;;
        0|"") return 0 ;;
        *)  log_error "Invalid choice."; return 1 ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
#  UPDATE TOOLS
# ══════════════════════════════════════════════════════════════════════════════

update_script() {
    progress_init 1
    section_header "Updating Toolkit Script" 1

    if [[ -d "$SCRIPT_DIR/.git" ]]; then
        run_action "bbtk script" updated "cd '$SCRIPT_DIR' && git pull --ff-only" || true
    else
        run_action "bbtk script" updated "rm -rf '$CLONE_DIR' && git clone --depth 1 '$REPO_URL' '$CLONE_DIR'" || true
    fi

    section_footer "Toolkit Script"
}

update_tools() {
    printf "\n  ${BOLD}Updating installed tools…${RESET}\n"

    # Count what's installed
    local count=0 tool

    for tool in "${PYTHON_PIP_TOOLS[@]}"; do
        if _python_venv_has_pkg "$TOOLS_DIR/$tool" "$tool"; then
            (( count++ ))
        fi
    done
    for tool in "${PYTHON_PIPX_TOOLS[@]}"; do
        cmd_exists "$tool" && (( count++ ))
    done
    for tool in "${!PYTHON_GIT_TOOLS[@]}"; do
        if _python_venv_marker_ok "$TOOLS_DIR/$tool"; then
            (( count++ ))
        fi
    done
    for tool in "${GO_TOOLS_ORDER[@]}"; do
        cmd_exists "$tool" && (( count++ ))
    done
    cmd_exists x8 && (( count++ ))
    for tool in "${APT_TOOLS[@]}"; do
        is_apt_installed "$tool" && (( count++ ))
    done
    for tool in "${SNAP_TOOLS[@]}"; do
        is_snap_installed "$tool" && (( count++ ))
    done

    if (( count == 0 )); then
        log_warn "No tools found to update."
        return 0
    fi
    progress_init "$count"

    # Python pip venv tools
    for tool in "${PYTHON_PIP_TOOLS[@]}"; do
        if _python_venv_has_pkg "$TOOLS_DIR/$tool" "$tool"; then
            run_action "$tool" updated "'${TOOLS_DIR}/${tool}/venv/bin/pip' install --upgrade $tool -q" || true
        fi
    done
    # pipx tools
    for tool in "${PYTHON_PIPX_TOOLS[@]}"; do
        if cmd_exists "$tool"; then
            run_action "$tool" updated "pipx upgrade $tool" || true
        fi
    done
    # Python git tools
    for tool in "${!PYTHON_GIT_TOOLS[@]}"; do
        if _python_venv_marker_ok "$TOOLS_DIR/$tool"; then
            run_action "$tool" updated "cd '${TOOLS_DIR}/${tool}' && git pull" || true
        fi
    done
    # Go tools
    for tool in "${GO_TOOLS_ORDER[@]}"; do
        if cmd_exists "$tool"; then
            local cmd="${GO_TOOLS[$tool]}"
            run_action "$tool" updated "$cmd" || true
        fi
    done
    # x8
    if cmd_exists x8; then
        [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
        run_action "x8" updated "cargo install x8" || true
    fi
    # APT upgrade
    sudo apt-get update -qq >> "$LOG_FILE" 2>&1 || true
    for tool in "${APT_TOOLS[@]}"; do
        if is_apt_installed "$tool"; then
            run_action "$tool" updated "sudo apt-get install -y -qq --only-upgrade $tool" || true
        fi
    done
    # Snap refresh
    for tool in "${SNAP_TOOLS[@]}"; do
        if is_snap_installed "$tool"; then
            run_action "$tool" updated "sudo snap refresh $tool" || true
        fi
    done
}

# ══════════════════════════════════════════════════════════════════════════════
#  UPDATE WORDLISTS
# ══════════════════════════════════════════════════════════════════════════════

update_wordlists() {
    printf "\n  ${BOLD}Updating wordlists…${RESET}\n"

    local count=0 name

    # SecLists — re-download only if missing
    [[ -d "$WORDLISTS_DIR/SecLists-master" ]] && (( count++ ))
    # assetnote
    [[ -d "$WORDLISTS_DIR/data" ]] && (( count++ ))
    # Git repos
    for name in "${WORDLIST_GIT_ORDER[@]}"; do
        [[ -d "$WORDLISTS_DIR/$name/.git" ]] && (( count++ ))
    done
    for name in "${!PAYLOAD_GIT[@]}"; do
        [[ -d "$WORDLISTS_DIR/$name/.git" ]] && (( count++ ))
    done

    if (( count == 0 )); then
        log_warn "No wordlists found to update. Run install first."
        return 0
    fi
    progress_init "$count"

    section_header "Updating Wordlists" "$count"

    if [[ -d "$WORDLISTS_DIR/SecLists-master" ]]; then
        cmd_exists unzip || sudo apt-get install -y -qq unzip
        run_action "SecLists" updated "
            cd '$WORDLISTS_DIR' && rm -rf SecLists-master && \
            wget -c https://github.com/danielmiessler/SecLists/archive/master.zip -O SecList.zip && \
            unzip -qo SecList.zip && rm -f SecList.zip
        " || true
    fi
    if [[ -d "$WORDLISTS_DIR/data" ]]; then
        run_action "assetnote" updated "
            cd '$WORDLISTS_DIR' && \
            wget -r --no-parent -R 'index.html*' https://wordlists-cdn.assetnote.io/data/ -nH -e robots=off
        " || true
    fi
    for name in "${WORDLIST_GIT_ORDER[@]}"; do
        if [[ -d "$WORDLISTS_DIR/$name/.git" ]]; then
            run_action "$name" updated "cd '$WORDLISTS_DIR/$name' && git pull" || true
        fi
    done
    for name in "${!PAYLOAD_GIT[@]}"; do
        if [[ -d "$WORDLISTS_DIR/$name/.git" ]]; then
            run_action "$name" updated "cd '$WORDLISTS_DIR/$name' && git pull" || true
        fi
    done

    section_footer "Wordlists"
}
