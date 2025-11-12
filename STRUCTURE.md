# Directory Structure

```
security-tools-installer/
│
├── install.sh                      # Main entry point (CLI interface)
├── validate.sh                     # Pre-installation validation script
│
├── lib/                            # Library modules (modular architecture)
│   ├── config.sh                   # Configuration and tool definitions
│   ├── ui.sh                       # UI/UX functions (progress bars, menus, logging)
│   ├── utils.sh                    # Utility functions (system checks, network ops)
│   ├── tools.sh                    # Tool installation functions (modular plugins)
│   └── core.sh                     # Core orchestration logic (rollback, workflows)
│
├── README.md                       # User guide and documentation
├── ARCHITECTURE.md                 # Detailed architecture documentation
├── QUICKSTART.md                   # Quick reference guide
├── CHANGELOG.md                    # Version history and changes
└── STRUCTURE.md                    # This file

After Installation (on target system):
~/.security-tools/
├── logs/
│   └── install-YYYYMMDD-HHMMSS.log  # Timestamped installation logs
├── state/                           # Runtime state directory
├── config                           # User configuration file
└── manifest.json                    # Installed tools manifest

~/tools/                             # Installed security tools
├── scripts/
│   └── activate_python_tools.sh     # Python environment helper
├── sqlmap/                          # Python tool with git repo
├── ghauri/                          # Python tool with venv
│   └── ghauriEnv/                   # Virtual environment
├── recollapse/
│   └── recollapseEnv/
├── commix/
├── SSTImap/
│   └── sstimapEnv/
└── XSStrike/
    └── xsstrikeEnv/

~/wordlists/                         # Wordlist collections
├── SecLists/                        # Comprehensive security wordlists
├── Bo0oM/                           # Fuzzing wordlists
├── wordlist/                        # Additional wordlists
├── jwt-secrets/                     # JWT secret wordlists
└── yassineaboukir-gist/
    └── all.txt

$HOME/.zshrc                         # ZSH configuration
$HOME/.p10k.zsh                      # Powerlevel10k theme config
$HOME/.security_aliases              # Security tool aliases
$HOME/.oh-my-zsh/                    # Oh My ZSH installation
$HOME/.cargo/                        # Rust installation
$HOME/go/                            # Go workspace
    └── bin/                         # Go tools binaries
        ├── nuclei
        ├── subfinder
        ├── httpx
        ├── ffuf
        ├── gobuster
        ├── dnsx
        ├── gau
        ├── waybackurls
        ├── unfurl
        ├── cookiemonster
        ├── katana
        └── naabu

/usr/local/go/                       # Go language installation
```

## Module Responsibilities

### install.sh (Main Entry Point)
- Command-line argument parsing
- User input handling
- Mode selection
- Error handling setup (traps)
- Module sourcing and initialization
- Main workflow orchestration

### lib/config.sh (Configuration)
- Script metadata and version
- Path definitions
- Color codes and icons
- Tool definitions (associative arrays):
  - ZSH packages and plugins
  - Programming languages
  - Go tools
  - Python tools
  - Rust tools
  - APT/Snap/Pipx tools
  - Wordlists
- Installation profiles
- System requirements
- Configuration functions

### lib/ui.sh (User Interface)
- Logging functions (info, success, warning, error, debug)
- Progress bars and spinners
- ASCII art and banners
- Interactive menus
- Confirmation prompts
- Summary displays
- Error messages with troubleshooting

### lib/utils.sh (Utilities)
- System information gathering
- Command existence checks
- Disk space and memory checks
- Internet connectivity testing
- Download functions with retry
- Git operations
- Version management
- Manifest management (JSON)
- File operations
- Temporary file handling

### lib/tools.sh (Tool Installation)
- ZSH installation and configuration
- Programming language installations:
  - Go
  - Rust
  - Python setup
- Security tool installations:
  - Go-based tools
  - Python-based tools
  - APT packages
  - Snap packages
  - Pipx tools
- Wordlist installations
- Helper script generation
- Rollback/uninstall functions

### lib/core.sh (Core Logic)
- Rollback management
- Pre-installation checks
- Installation mode handlers:
  - Full installation
  - Partial installations
  - Profile-based installations
  - Custom installations
- Installation execution
- Update operations
- Uninstall operations
- Post-installation tasks

## Data Flow

```
User Command
    ↓
install.sh (parse arguments)
    ↓
    ├─→ --help / --version → show_help() / show_version()
    │
    ├─→ Interactive mode → interactive_menu()
    │       ↓
    │   ui_show_banner()
    │   ui_menu_main()
    │       ↓
    │   User selection → Installation mode
    │
    └─→ CLI mode (--full, --zsh-only, etc.)
        ↓
    main()
        ↓
    config_init_dirs()
    ui_log_init()
    config_load()
        ↓
    core_pre_install_checks()
        ├─→ util_check_ubuntu_version()
        ├─→ util_check_disk_space()
        ├─→ util_check_internet()
        └─→ util_check_sudo()
        ↓
    Installation Mode Handler
        ├─→ core_install_full()
        ├─→ core_install_zsh_only()
        ├─→ core_install_tools_only()
        ├─→ core_install_profile()
        └─→ core_install_custom()
        ↓
    core_execute_installation_steps()
        ↓
        ├─ For each step:
        │   ├─→ ui_step_header()
        │   ├─→ tool_install_*()
        │   │    ├─→ Installation logic
        │   │    ├─→ util_* functions
        │   │    ├─→ ui_progress_bar() / ui_spinner()
        │   │    └─→ rollback_add()
        │   └─→ util_manifest_add_tool()
        │
        ├─ On Success:
        │   ├─→ ui_show_summary()
        │   └─→ rollback_clear()
        │
        └─ On Failure:
            ├─→ log_error()
            ├─→ ui_show_error()
            └─→ rollback_execute()
        ↓
    core_post_install()
        ├─→ config_save()
        ├─→ util_manifest_init()
        ├─→ ui_show_success_banner()
        └─→ ui_show_next_steps()
```

## Key Design Patterns

### 1. Modular Plugin System
Tools are defined in config arrays. Adding a new tool requires only updating the array.

### 2. Dependency Injection
Modules are sourced and functions are called without tight coupling.

### 3. Rollback Stack
Actions are registered in a stack and can be undone in reverse order.

### 4. Separation of Concerns
Each module has a single, well-defined responsibility.

### 5. Convention over Configuration
Consistent naming and structure make the codebase predictable.

## File Size Distribution

```
install.sh       ~500 lines   (Entry point, CLI, main logic)
lib/config.sh    ~350 lines   (Configuration, tool definitions)
lib/ui.sh        ~400 lines   (UI functions, logging, menus)
lib/utils.sh     ~450 lines   (Utilities, system checks)
lib/tools.sh     ~600 lines   (Tool installations)
lib/core.sh      ~450 lines   (Core orchestration)
─────────────────────────────
Total:          ~2,750 lines  (Well-organized, maintainable)
```

## Version History

- **v1.0**: Monolithic script (~1000 lines)
- **v2.0**: Enhanced features (~1800 lines)
- **v3.0**: Modular architecture (~2750 lines across 6 files)

The increase in lines reflects better organization, documentation, and features, not complexity.

---

**Structure Version**: 3.0.0
**Last Updated**: 2024-11-12
