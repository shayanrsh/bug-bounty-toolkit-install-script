# bbtk — Bug Bounty Toolkit Installer

> Idempotent, single-command security tool installer for Ubuntu servers.
> 45+ tools with real-time progress UI, individual tool picker, selective uninstall, update, and full management capabilities.

## Quick Start

**One-liner (curl pipe):**

```bash
bash <(curl -Ls https://raw.githubusercontent.com/shayanrsh/bug-bounty-toolkit-install-script/main/install.sh)
```

**Manual clone:**

```bash
git clone https://github.com/shayanrsh/bug-bounty-toolkit-install-script.git
cd bug-bounty-toolkit-install-script
chmod +x install.sh
./install.sh
```

After the first run, the `bbtk` alias is installed in your shell. Use it to access the toolkit from anywhere:

```bash
bbtk                # Interactive menu
bbtk --help         # Show all options
bbtk --version      # v2.2
```

## Prerequisites

- Ubuntu 20.04+ (or WSL2)
- `sudo` access
- Internet connectivity
- ~5 GB free disk space

## Tools Installed

### Python Tools (`~/tools/`, each in its own venv)

| Tool    | Method           |
| ------- | ---------------- |
| shodan  | pip (venv)       |
| waymore | pip (venv)       |
| uro     | pipx             |
| commix  | git clone + venv |
| sqlmap  | git clone + venv |
| ghauri  | git clone + venv |
| SSTImap | git clone + venv |

### Go Tools (installed via `go install`)

| Tool              | Description            |
| ----------------- | ---------------------- |
| subfinder         | Subdomain discovery    |
| amass             | Attack surface mapping |
| ffuf              | Web fuzzer             |
| waybackurls       | Wayback Machine URLs   |
| gau               | Get All URLs           |
| katana            | Web crawler            |
| dnsx              | DNS toolkit            |
| httpx             | HTTP prober            |
| unfurl            | URL parser             |
| fallparams        | Parameter discovery    |
| nuclei            | Vulnerability scanner  |
| cookiemonster     | Cookie analysis        |
| sourcemapper      | Source map extraction  |
| TInjA             | Template injection     |
| interactsh-client | OOB interaction        |

### Rust Tool

| Tool | Method                                   |
| ---- | ---------------------------------------- |
| x8   | `cargo install x8` (Rust auto-installed) |

### Docker

| Tool      | Method                            |
| --------- | --------------------------------- |
| Docker CE | Official Docker repository        |
| jwt_tool  | Docker alias (`ticarpi/jwt_tool`) |

### APT / Snap

| Tool           | Method |
| -------------- | ------ |
| whois          | apt    |
| dnsutils       | apt    |
| hydra          | apt    |
| netcat-openbsd | apt    |
| dalfox         | snap   |

### Wordlists & Payloads (`~/wordlists/`)

| Wordlist             | Source                                   |
| -------------------- | ---------------------------------------- |
| SecLists             | danielmiessler/SecLists (zip)            |
| assetnote            | wordlists-cdn.assetnote.io (wget mirror) |
| Bo0oM                | Bo0oM/fuzz.txt                           |
| RobotsDisallowed     | danielmiessler/RobotsDisallowed          |
| my-wordlists         | shayanrsh/wordlist                       |
| Auto_Wordlists       | carlospolop/Auto_Wordlists               |
| FuzzDB               | fuzzdb-project/fuzzdb                    |
| nmap_vulners         | vulnersCom/nmap-vulners                  |
| Commonspeak2         | assetnote/commonspeak2-wordlists         |
| api_wordlist         | chrislockard/api_wordlist                |
| PayloadsAllTheThings | swisskyrepo/PayloadsAllTheThings         |

### Zsh + Oh My Zsh

| Component               | Method                    |
| ----------------------- | ------------------------- |
| zsh                     | apt                       |
| Oh My Zsh               | Official installer        |
| zsh-autosuggestions     | git clone (custom plugin) |
| zsh-syntax-highlighting | git clone (custom plugin) |
| powerlevel10k           | git clone (custom theme)  |
| p10k config             | Bundled `.p10k.zsh`       |

## Usage

### Interactive Menu

```bash
bbtk
```

```
   1)  Full Install             — all tools, wordlists, payloads
   2)  Python Tools             — shodan, sqlmap, waymore …
   3)  Go Tools                 — subfinder, nuclei, httpx …
   4)  Docker + Docker Tools    — docker, jwt_tool
   5)  APT / Snap Tools         — dalfox, hydra, whois …
   6)  Wordlists & Payloads     — SecLists, assetnote …
   7)  Zsh + Oh My Zsh          — zsh, powerlevel10k, plugins
   8)  Custom Select            — pick categories or individual tools
   9)  Update Tools             — update all installed tools
  10)  Update Wordlists         — git pull all wordlists
  11)  Uninstall Everything     — remove all installed tools
  12)  Selective Uninstall      — choose what to remove
   0)  Exit
```

### CLI Flags

| Flag              | Description                          |
| ----------------- | ------------------------------------ |
| `--full`          | Install everything (non-interactive) |
| `--python`        | Python tools only                    |
| `--go`            | Go + Rust tools only                 |
| `--docker`        | Docker + Docker tools only           |
| `--apt`           | APT / Snap tools only                |
| `--wordlists`     | Wordlists & payloads only            |
| `--zsh`           | Zsh + Oh My Zsh only                 |
| `--update`        | Update all installed tools           |
| `--update-wl`     | Update all wordlists                 |
| `--uninstall`     | Uninstall everything                 |
| `--uninstall-sel` | Selective uninstall (interactive)    |
| `--debug`         | Enable debug-level logging           |
| `-v`, `--version` | Show version                         |
| `-h`, `--help`    | Show help message                    |

```bash
bbtk --full           # Install everything
bbtk --python         # Python tools only
bbtk --go             # Go + Rust tools
bbtk --zsh            # Zsh + Oh My Zsh
bbtk --update         # Update all tools
bbtk --uninstall-sel  # Choose what to remove
bbtk --debug          # Verbose logging
```

### Custom Select (Option 8)

Pick tools by **category** (Y/n per group) or by **individual tool** using a numbered multi-select picker:

```
  ── Python ─────────────────────────────────────────────────
    1) shodan               2) waymore             3) uro
    4) commix               5) sqlmap              6) ghauri
    7) SSTImap

  ── Go + Rust ──────────────────────────────────────────────
    8) subfinder            9) amass              10) ffuf
   ...

  Tools: 1,5,8-12,31
```

Supports comma-separated numbers, ranges (`8-15`), or `all`.

### Selective Uninstall (Option 12)

Remove tools **by category** (Y/n per group) or **by individual tool** using the same multi-select picker. Only installed tools are affected.

```bash
bbtk --uninstall-sel  # or choose option 12 from the menu
```

## Progress UI

Each tool shows a two-line live display with bouncing progress bar and live output:

```
  [░░███░░░] nuclei            │ [████████░░░░░░░░░░░░] 35% (12/40)
       └─ go: downloading github.com/projectdiscovery/nuclei…  │  18s
```

Final results per tool:

```
  [✓]  nuclei                    installed
  [⊘]  httpx                     already installed
  [✗]  feroxbuster               failed
  [✕]  sqlmap                    removed
  [✓]  subfinder                 updated
```

## Adding or Removing Tools

Edit [`lib/tools.sh`](lib/tools.sh) — add entries to the appropriate registry array:

| Category        | Array(s) to edit                         |
| --------------- | ---------------------------------------- |
| Python pip      | `PYTHON_PIP_TOOLS`                       |
| Python pipx     | `PYTHON_PIPX_TOOLS`                      |
| Python git      | `PYTHON_GIT_TOOLS` + `_PYTHON_GIT_ORDER` |
| Go tools        | `GO_TOOLS` + `GO_TOOLS_ORDER`            |
| APT tools       | `APT_TOOLS`                              |
| Snap tools      | `SNAP_TOOLS`                             |
| Wordlists (git) | `WORDLIST_GIT` + `WORDLIST_GIT_ORDER`    |
| Payloads (git)  | `PAYLOAD_GIT`                            |

New tools are automatically available in the interactive picker, installer, updater, and uninstaller.

## Project Structure

```
install.sh          Entry point — CLI parsing, preflight, menu dispatch, bbtk alias
.p10k.zsh           Bundled Powerlevel10k configuration
lib/
  utils.sh          Logging, system checks, shell detection, prerequisite bootstrap
  ui.sh             Colors, progress bars, bouncing indicator, menus, tool picker, summary
  tools.sh          Tool registry, install/uninstall/update for all categories
README.md           This file
LICENSE             MIT
```

## License

MIT
