# bbtk — Bug Bounty Toolkit Installer

Idempotent, single-command security tool installer for Ubuntu servers.

- Interactive menu + custom tool picker (categories or individual tools)
- Real-time progress UI + per-tool success/fail reporting
- Update + selective uninstall workflows
- Installs tools into predictable locations and makes them runnable from your `$PATH`

Current version: **v2.3**

## Quick Start

### One-liner (curl pipe)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/shayanrsh/bug-bounty-toolkit-install-script/main/install.sh)
```

### Manual clone

```bash
git clone https://github.com/shayanrsh/bug-bounty-toolkit-install-script.git
cd bug-bounty-toolkit-install-script
chmod +x install.sh
./install.sh
```

After running once, `bbtk` is added as a shell alias so you can run the toolkit from anywhere:

```bash
bbtk            # Interactive menu
bbtk --help     # Show all options
bbtk --version  # v2.3
```

## Prerequisites

- Ubuntu 20.04+ (Ubuntu 24.04 supported)
- `sudo` access
- Internet connectivity
- ~5 GB free disk space

## What gets installed (and where)

### Python tools (each in its own venv)

- Install location: `~/tools/<tool>/venv/`
- Launchers: `~/.local/bin/<tool>` (added to `PATH` by your shell)

Tools:

| Tool    | Method           |
| ------- | ---------------- |
| shodan  | pip (venv)       |
| waymore | pip (venv)       |
| uro     | pipx             |
| commix  | git clone + venv |
| sqlmap  | git clone + venv |
| ghauri  | git clone + venv |
| SSTImap | git clone + venv |

### Go tools

- Go is installed via `snap` if missing.
- `GOPATH/bin` is added to your shell `PATH` so installed binaries are runnable.

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

### Rust tool

| Tool | Method                                   |
| ---- | ---------------------------------------- |
| x8   | `cargo install x8` (Rust auto-installed) |

### Docker

- Docker CE is installed via the official Docker APT repository.
- The installer removes stale Docker repo entries (common cause of failed installs) and verifies the install.

| Tool      | Method                            |
| --------- | --------------------------------- |
| Docker CE | Official Docker repository        |
| jwt_tool  | Docker alias (`ticarpi/jwt_tool`) |

Note: the installer adds your user to the `docker` group. You may need to **log out and back in** for group membership to apply.

### APT / Snap

| Tool           | Method |
| -------------- | ------ |
| whois          | apt    |
| dnsutils       | apt    |
| hydra          | apt    |
| netcat-openbsd | apt    |
| dalfox         | snap   |

### Wordlists & payloads

- Install location: `~/wordlists/`

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

| Component               | Method              |
| ----------------------- | ------------------- |
| zsh                     | apt                 |
| Oh My Zsh               | official installer  |
| zsh-autosuggestions     | git clone           |
| zsh-syntax-highlighting | git clone           |
| powerlevel10k           | git clone           |
| p10k config             | bundled `.p10k.zsh` |

When you install Zsh via **option 7** (or via Custom Select), `bbtk` is also added to `~/.zshrc` automatically.

## Usage

### Interactive menu

```bash
bbtk
```

### CLI flags

| Flag              | Description                          |
| ----------------- | ------------------------------------ |
| `--full`          | Install everything (non-interactive) |
| `--python`        | Install Python tools only            |
| `--go`            | Install Go + Rust tools only         |
| `--docker`        | Install Docker + Docker tools only   |
| `--apt`           | Install APT/Snap tools only          |
| `--wordlists`     | Install wordlists & payloads only    |
| `--zsh`           | Install Zsh + Oh My Zsh only         |
| `--update`        | Update installed tools               |
| `--update-wl`     | Update installed wordlists           |
| `--update-script` | Update this toolkit repo             |
| `--uninstall`     | Uninstall everything                 |
| `--uninstall-sel` | Selective uninstall (interactive)    |
| `--debug`         | Enable debug logging                 |
| `-v`, `--version` | Show version                         |
| `-h`, `--help`    | Show help                            |

Examples:

```bash
bbtk --full
bbtk --docker
bbtk --uninstall-sel
bbtk --debug
```

### Custom Select (Option 8)

You can install by:

- **Category** (Y/n prompts)
- **Individual tool** (multi-select with comma/range support: `1,3,8-15` or `all`)

## Adding/removing tools

Edit `lib/tools.sh` and update the relevant registry arrays:

- Python (pip/venv): `PYTHON_PIP_TOOLS`
- Python (pipx): `PYTHON_PIPX_TOOLS`
- Python (git): `PYTHON_GIT_TOOLS` + `_PYTHON_GIT_ORDER`
- Go: `GO_TOOLS` + `GO_TOOLS_ORDER`
- APT: `APT_TOOLS`
- Snap: `SNAP_TOOLS`
- Wordlists: `WORDLIST_GIT` + `WORDLIST_GIT_ORDER`
- Payloads: `PAYLOAD_GIT`

## License

MIT
