# Bug Bounty Toolkit Installer v3.0.0

**Professional, modular security tools installation framework for Ubuntu/WSL2**

[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](https://github.com/shayanrsh/bug-bounty-toolkit-install-script)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![ShellCheck](https://img.shields.io/badge/shellcheck-passing-success.svg)](https://www.shellcheck.net/)

---

## ⚡ Quick Install

Install everything with a single command:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/shayanrsh/bug-bounty-toolkit-install-script/main/install.sh)
```

Or download and run manually:

```bash
git clone https://github.com/shayanrsh/bug-bounty-toolkit-install-script.git
cd bug-bounty-toolkit-install-script
chmod +x install.sh
./install.sh
```

---

## 🚀 Features

### Core Capabilities
- **Modular Architecture**: Plugin-based system for easy tool additions
- **Robust Error Handling**: Comprehensive error handling with automatic rollback
- **Professional UI/UX**: Beautiful progress bars, spinners, and colorful output
- **Multiple Installation Modes**: Full, partial, profile-based, and custom installations
- **Dry-Run Mode**: Preview installations without making changes
- **Update Management**: Update existing tools with a single command
- **Manifest Generation**: JSON manifest of all installed tools with versions
- **WSL2 Compatible**: Full support for Windows Subsystem for Linux

### Installation Profiles
- **Minimal**: Essential tools only (ZSH + Go + nuclei, subfinder, httpx)
- **Full**: All available tools and wordlists
- **Pentest**: Pentesting-focused configuration
- **Developer**: Development environment setup

### Installed Components

#### Shell Environment
- **ZSH**: Advanced shell with Oh My ZSH
- **Oh My ZSH**: Plugin framework and configuration manager
- **Powerlevel10k**: Beautiful and fast ZSH theme
- **Plugins**: zsh-autosuggestions, zsh-syntax-highlighting

#### Programming Languages
- **Go** 1.22.4: Modern programming language
- **Rust**: Systems programming language
- **Python 3**: With pip and venv support

#### Go-based Security Tools (12 tools)
- **dnsx**: DNS toolkit and resolver
- **httpx**: Fast HTTP probe
- **unfurl**: URL parsing tool
- **waybackurls**: Wayback machine URL fetcher
- **gau**: Get All URLs
- **ffuf**: Fast web fuzzer
- **gobuster**: Directory/DNS brute forcer
- **cookiemonster**: Cookie analysis
- **nuclei**: Vulnerability scanner
- **subfinder**: Subdomain discovery
- **katana**: Web crawler
- **naabu**: Fast port scanner

#### Python-based Security Tools (6 tools)
- **SQLMap**: SQL injection tool
- **Ghauri**: Advanced SQL injection
- **Recollapse**: Regex attack pattern generator
- **Commix**: Command injection tool
- **SSTImap**: SSTI detection/exploitation
- **XSStrike**: XSS detection suite

#### Other Tools
- **APT Tools**: crunch, jq, tree, htop, neofetch, and more
- **Snap Tools**: dalfox (XSS parameter analyzer)
- **Pipx Tools**: uro, arjun
- **Rust Tools**: x8 (parameter discovery)

#### Wordlists (5 collections)
- **SecLists**: Comprehensive security wordlists
- **Bo0oM/fuzz.txt**: Fuzzing wordlists
- **shayanrsh/wordlist**: Additional wordlists
- **jwt-secrets**: JWT secret wordlists
- **yassineaboukir**: Custom wordlists

---

## 📁 Architecture

### Directory Structure
```
security-tools-installer/
├── install.sh              # Main entry point
├── lib/                    # Library modules
│   ├── config.sh          # Configuration and tool definitions
│   ├── ui.sh              # UI/UX functions (progress bars, menus)
│   ├── utils.sh           # Utility functions (system checks, network)
│   ├── tools.sh           # Tool installation functions
│   └── core.sh            # Core orchestration logic
├── README.md              # This file
└── ARCHITECTURE.md        # Detailed architecture documentation
```

### Module Overview

#### **config.sh** - Configuration Management
- Tool definitions (Go, Python, Rust tools)
- Installation profiles
- System configuration
- Path management
- Associative arrays for modular tool definitions

#### **ui.sh** - User Interface
- Progress bars with percentage indicators
- Animated spinners for background processes
- ASCII art banners
- Interactive menus
- Color-coded logging
- Error display with troubleshooting hints

#### **utils.sh** - Utility Functions
- System information gathering
- Disk space and memory checks
- Internet connectivity testing
- Download functions with progress
- Git operations
- Retry logic with exponential backoff
- Manifest management (JSON)

#### **tools.sh** - Tool Installation
- Modular installation functions for each tool category
- ZSH environment setup
- Programming language installations
- Security tool installations
- Wordlist management
- Helper script generation

#### **core.sh** - Core Logic
- Installation orchestration
- Rollback management
- Pre-installation checks
- Installation modes
- Update operations
- Uninstall operations

---

## 🎯 Quick Start

### Basic Usage

```bash
# Make executable
chmod +x install.sh

# Interactive mode (recommended for first-time users)
./install.sh

# Full installation
./install.sh --full

# Preview installation (dry run)
./install.sh --dry-run --full

# Install with verbose output
./install.sh --full --verbose
```

### Advanced Usage

```bash
# Install specific components
./install.sh --zsh-only
./install.sh --go-tools
./install.sh --python-tools
./install.sh --wordlists

# Profile-based installation
./install.sh --profile=pentest
./install.sh --profile=minimal
./install.sh --profile=developer

# Non-interactive mode
./install.sh --no-interactive --full

# Update existing tools
./install.sh --update

# Uninstall everything
./install.sh --uninstall

# Debug mode
./install.sh --debug --full
```

---

## 🔧 Installation Modes

### 1. Interactive Mode (Default)
```bash
./install.sh
```
Presents a beautiful menu with 11 options for installation.

### 2. Command-Line Mode
Use flags to specify exactly what to install:
- `--full`: Install everything
- `--zsh-only`: ZSH + Oh My ZSH only
- `--tools-only`: All security tools (no ZSH)
- `--go-tools`: Go-based tools only
- `--python-tools`: Python-based tools only
- `--wordlists`: Wordlists only
- `--custom`: Interactive component selection

### 3. Profile Mode
```bash
./install.sh --profile=PROFILE_NAME
```

Available profiles:
- **minimal**: Fast setup with essential tools
- **full**: Everything (default)
- **pentest**: Pentesting-focused
- **developer**: Development environment

### 4. Dry-Run Mode
```bash
./install.sh --dry-run --full
```
Preview what would be installed without making changes.

---

## 📋 Requirements

### System Requirements
- **OS**: Ubuntu 20.04+ or WSL2 with Ubuntu
- **Disk Space**: 5GB minimum recommended
- **Memory**: 1GB minimum
- **Internet**: Required for downloads

### Prerequisites (auto-installed)
- curl
- wget
- git
- build-essential
- sudo privileges

---

## 🎨 UI/UX Features

### Progress Indicators
- **Progress Bars**: Visual progress with percentage
- **Spinners**: Animated indicators for background tasks
- **ETA Display**: Estimated time remaining
- **Color Coding**: Red/Yellow/Blue/Green based on progress

### Interactive Elements
- **Confirmation Prompts**: Smart defaults
- **Error Messages**: With troubleshooting hints
- **Success Banners**: Celebratory completion messages
- **Summary Tables**: Installed components overview

### Logging
- **Console Output**: Color-coded, timestamped messages
- **File Logging**: Detailed logs saved to `~/.security-tools/logs/`
- **Debug Mode**: Extra verbose output for troubleshooting
- **Log Levels**: DEBUG, INFO, SUCCESS, WARNING, ERROR

---

## 🔄 Rollback System

The installer includes automatic rollback capabilities:

```bash
# If installation fails, you'll be prompted:
# "Execute rollback? (y/n)"
```

Rollback actions are automatically tracked and executed in reverse order to cleanly undo partial installations.

---

## 📝 Manifest System

After installation, a JSON manifest is generated at:
```
~/.security-tools/manifest.json
```

Contains:
- Script version
- Installation date
- System information
- All installed tools with versions
- Installation paths

Example:
```json
{
  "version": "3.0.0",
  "generated": "2024-11-12T10:30:00Z",
  "system": {
    "os": "Ubuntu 24.04 LTS",
    "kernel": "5.15.0",
    "arch": "x86_64"
  },
  "tools": {
    "go_tools": [
      {
        "name": "nuclei",
        "version": "3.1.0",
        "path": "/home/user/go/bin/nuclei",
        "installed": "2024-11-12T10:35:00Z"
      }
    ]
  }
}
```

---

## 🛠️ Adding New Tools

The modular architecture makes adding new tools simple:

### 1. Define the Tool (lib/config.sh)

```bash
# For Go tools
declare -A GO_TOOLS=(
    ["newtool"]="github.com/author/newtool@latest|Tool description"
)

# For Python tools
declare -A PYTHON_TOOLS=(
    ["newtool"]="git|https://github.com/author/newtool.git|Description|requirements.txt"
)

# For APT packages
declare -A APT_TOOLS=(
    ["newtool"]="newtool|Description"
)
```

### 2. Installation Function (lib/tools.sh)

Most tools automatically install via their category function. For custom installation logic, add a dedicated function:

```bash
tool_install_custom_tool() {
    log_info "Installing custom tool..."
    # Custom installation logic here
    rollback_add "tool_uninstall_custom_tool"
    return 0
}

tool_uninstall_custom_tool() {
    log_warning "Uninstalling custom tool..."
    # Cleanup logic here
}
```

### 3. Add to Installation Profile (Optional)

```bash
declare -A PROFILES=(
    ["myprofile"]="zsh|go|custom_tool"
)
```

---

## 🧪 Testing

### Run Dry Run
```bash
./install.sh --dry-run --full
```

### Enable Debug Mode
```bash
./install.sh --debug --full
```

### Check Script with ShellCheck
```bash
shellcheck install.sh lib/*.sh
```

---

## 📂 File Locations

| Item       | Location                          |
| ---------- | --------------------------------- |
| Tools      | `~/tools/`                        |
| Wordlists  | `~/wordlists/`                    |
| Scripts    | `~/tools/scripts/`                |
| Logs       | `~/.security-tools/logs/`         |
| Config     | `~/.security-tools/config`        |
| Manifest   | `~/.security-tools/manifest.json` |
| ZSH Config | `~/.zshrc`                        |
| Aliases    | `~/.security_aliases`             |

---

## 🔍 Troubleshooting

### Installation Fails
1. Check the log file: `~/.security-tools/logs/install-*.log`
2. Run with debug mode: `./install.sh --debug --full`
3. Try with force mode: `./install.sh --force --full`

### WSL2 Issues
- Snap packages may not work in WSL2 (expected behavior)
- Ensure Windows interop is enabled
- Check disk space on both Linux and Windows drives

### Permission Issues
```bash
# Add user to sudo group
sudo usermod -aG sudo $USER

# Or run with sudo
sudo ./install.sh
```

### Network Issues
- Check internet connectivity
- Try alternative download mirrors
- Use retry logic (automatic)

---

## 📖 Documentation

### Help Command
```bash
./install.sh --help
```

### Version Information
```bash
./install.sh --version
```

### Detailed Architecture
See [ARCHITECTURE.md](ARCHITECTURE.md) for in-depth documentation.

---

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Add your tool to `lib/config.sh`
4. Add installation function to `lib/tools.sh`
5. Test with `--dry-run`
6. Submit a pull request

---

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 🙏 Acknowledgments

- Oh My ZSH community
- ProjectDiscovery team (nuclei, subfinder, httpx, etc.)
- All security tool authors
- Ubuntu and WSL2 teams

---

## 📧 Support

- **Issues**: [GitHub Issues](https://github.com/shayanrsh/bug-bounty-toolkit-install-script/issues)
- **Discussions**: [GitHub Discussions](https://github.com/shayanrsh/bug-bounty-toolkit-install-script/discussions)
- **Star this repo**: If you find it useful! ⭐

---

## 🗺️ Roadmap

- [ ] Tool version pinning
- [ ] Configuration file support (YAML/JSON)
- [ ] Docker container support
- [ ] Auto-update mechanism
- [ ] Health check commands
- [ ] Tool usage examples
- [ ] Integration with package managers
- [ ] Multi-distro support (Debian, Arch, etc.)

---

## ⭐ Star History

If this project helped you, please consider giving it a star!

---

**Made with ❤️ for the Bug Bounty Community**

*Happy Hunting! 🚀*
