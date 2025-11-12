# Architecture Documentation

## Security Tools Installer v3.0.0

### Professional Modular Installation Framework

---

## Table of Contents

1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Module Architecture](#module-architecture)
4. [Data Flow](#data-flow)
5. [Plugin System](#plugin-system)
6. [Error Handling](#error-handling)
7. [State Management](#state-management)
8. [Testing Strategy](#testing-strategy)

---

## Overview

The Security Tools Installer is built on a modular, plugin-based architecture that separates concerns into distinct, maintainable modules. This design allows for easy extension, robust error handling, and a professional user experience.

### Key Architectural Goals

1. **Modularity**: Each component is self-contained and independently testable
2. **Extensibility**: New tools can be added without modifying core logic
3. **Reliability**: Comprehensive error handling with rollback capabilities
4. **User Experience**: Professional UI with clear feedback
5. **Maintainability**: Clean code structure following Shell Script Best Practices

---

## Design Principles

### 1. Separation of Concerns

Each module has a single, well-defined responsibility:

```
config.sh   → Tool definitions and configuration
ui.sh       → User interface and presentation
utils.sh    → System utilities and helpers
tools.sh    → Tool installation logic
core.sh     → Orchestration and workflow
install.sh  → Entry point and argument parsing
```

### 2. Plugin-Based Tool Definitions

Tools are defined as associative arrays in `config.sh`:

```bash
declare -A GO_TOOLS=(
    ["nuclei"]="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest|Vulnerability scanner"
)
```

Adding a new tool requires only adding an entry to the appropriate array.

### 3. Consistent Function Naming

All functions follow a consistent naming convention:

- `tool_install_*`: Tool installation functions
- `tool_uninstall_*`: Rollback/cleanup functions
- `util_*`: Utility functions
- `ui_*`: User interface functions
- `core_*`: Core orchestration functions
- `config_*`: Configuration management
- `rollback_*`: Rollback management

### 4. Error Handling First

Every function:
- Returns proper exit codes (0 for success, 1 for failure)
- Logs errors with context
- Registers rollback actions when modifying system state
- Provides troubleshooting hints

### 5. DRY (Don't Repeat Yourself)

Common patterns are abstracted:
- `util_retry`: Retry logic with exponential backoff
- `util_git_clone`: Git operations with error handling
- `util_download`: Download with progress tracking
- `ui_spinner`: Background task indication

---

## Module Architecture

### config.sh - Configuration Module

**Purpose**: Central configuration and tool definitions

**Key Components**:

```bash
# Tool Categories
TOOL_CATEGORIES=("zsh" "languages" "go_tools" "python_tools" ...)

# Tool Definitions (Associative Arrays)
declare -A GO_TOOLS=(...)
declare -A PYTHON_TOOLS=(...)
declare -A APT_TOOLS=(...)

# Installation Profiles
declare -A PROFILES=(
    ["minimal"]="zsh|go|nuclei|subfinder"
    ["full"]="all"
)

# System Configuration
readonly MIN_DISK_SPACE_GB=5
readonly RETRY_MAX_ATTEMPTS=3
```

**Design Patterns**:
- Associative arrays for tool definitions
- Read-only constants for system values
- Export functions for module integration

**Adding a New Tool**:

```bash
# 1. Add to tool array
declare -A GO_TOOLS=(
    ["mytool"]="github.com/author/mytool@latest|Description"
)

# 2. That's it! Auto-installed via tool_install_go_tools()
```

---

### ui.sh - User Interface Module

**Purpose**: All user-facing interactions and visual feedback

**Key Features**:

1. **Logging System**
```bash
log_info "Message"     # Blue info
log_success "Message"  # Green success
log_warning "Message"  # Yellow warning
log_error "Message"    # Red error
log_debug "Message"    # Purple debug (only if DEBUG=true)
```

2. **Progress Indicators**
```bash
ui_progress_bar 50 100 "Installing tools"
ui_spinner $PID "Background task"
ui_eta $START_TIME $CURRENT $TOTAL
```

3. **Interactive Menus**
```bash
ui_menu_main          # Main installation menu
ui_menu_custom        # Custom component selection
ui_confirm "Prompt"   # Yes/no confirmation
```

4. **Visual Elements**
```bash
ui_show_banner          # ASCII art banner
ui_section_header       # Section dividers
ui_step_header          # Step indicators
ui_draw_box            # Text boxes
```

**Design Patterns**:
- Consistent color scheme
- Progress percentage calculation
- Spinner animation loops
- Box-drawing characters for visual appeal

---

### utils.sh - Utility Module

**Purpose**: System operations and helper functions

**Categories**:

1. **System Checks**
```bash
util_check_disk_space [required_gb] [path]
util_check_memory [required_gb]
util_check_internet
util_check_ubuntu_version
util_check_sudo
```

2. **Command Operations**
```bash
util_command_exists "command"
util_package_installed "package"
util_get_tool_version "tool"
```

3. **Network Operations**
```bash
util_download URL OUTPUT "Description"
util_download_verify URL OUTPUT CHECKSUM_URL
util_retry MAX_ATTEMPTS DELAY command [args...]
```

4. **Git Operations**
```bash
util_git_clone REPO_URL DEST_DIR "Description"
util_git_update REPO_DIR "Description"
```

5. **Manifest Management**
```bash
util_manifest_init
util_manifest_add_tool CATEGORY NAME VERSION PATH
```

**Design Patterns**:
- Return 0 for success, 1 for failure
- Use local variables for function scope
- Log operations with context
- Implement retry with exponential backoff

---

### tools.sh - Tool Installation Module

**Purpose**: Tool-specific installation logic

**Structure**:

Each tool category has:
1. Installation function: `tool_install_*`
2. Uninstall function: `tool_uninstall_*`
3. Rollback registration

**Example - ZSH Installation**:

```bash
tool_install_zsh() {
    # 1. Install packages
    # 2. Verify installation
    # 3. Install Oh My ZSH
    # 4. Install plugins
    # 5. Configure
    # 6. Register rollback
    rollback_add "tool_uninstall_zsh"
    return 0
}

tool_uninstall_zsh() {
    # Cleanup logic
    rm -rf "$HOME/.oh-my-zsh"
}
```

**Tool Categories**:

| Category     | Function                    | Tools                   |
| ------------ | --------------------------- | ----------------------- |
| ZSH          | `tool_install_zsh`          | ZSH, Oh My ZSH, plugins |
| Go           | `tool_install_go`           | Go language             |
| Rust         | `tool_install_rust`         | Rust language           |
| Go Tools     | `tool_install_go_tools`     | nuclei, subfinder, etc. |
| Python Tools | `tool_install_python_tools` | sqlmap, ghauri, etc.    |
| APT Tools    | `tool_install_apt_tools`    | System packages         |
| Wordlists    | `tool_install_wordlists`    | SecLists, etc.          |

**Design Patterns**:
- Idempotent operations (safe to run multiple times)
- Progress reporting via UI functions
- Dependency checking before installation
- Virtual environment creation for Python tools

---

### core.sh - Core Orchestration Module

**Purpose**: Main business logic and workflow orchestration

**Key Components**:

1. **Rollback System**
```bash
rollback_add "function_name"     # Register rollback action
rollback_execute()               # Execute all rollback actions
rollback_clear()                 # Clear rollback stack
```

2. **Pre-Installation Checks**
```bash
core_pre_install_checks()
    ├─ System compatibility
    ├─ Disk space
    ├─ Memory
    ├─ Internet connectivity
    ├─ Sudo privileges
    └─ Display system info
```

3. **Installation Modes**
```bash
core_install_full()              # All components
core_install_zsh_only()          # ZSH only
core_install_tools_only()        # Security tools
core_install_go_tools_only()     # Go tools
core_install_python_tools_only() # Python tools
core_install_wordlists_only()    # Wordlists
core_install_profile PROFILE     # Profile-based
core_install_custom()            # Custom selection
```

4. **Installation Execution**
```bash
core_execute_installation_steps steps_array
    ├─ Track progress
    ├─ Execute each step
    ├─ Handle failures
    ├─ Show summary
    └─ Clear rollback on success
```

5. **Maintenance Operations**
```bash
core_update_tools()              # Update installed tools
core_uninstall_all()             # Remove everything
```

**Design Patterns**:
- Step-based execution with progress tracking
- Automatic rollback on failure
- Interactive error handling
- Summary generation

---

### install.sh - Main Entry Point

**Purpose**: Command-line interface and script initialization

**Workflow**:

```
1. Parse Arguments
   ├─ --help, --version
   ├─ --dry-run, --force
   ├─ --verbose, --debug
   └─ Installation mode flags

2. Initialize
   ├─ Source modules
   ├─ Set up traps
   ├─ Initialize directories
   └─ Start logging

3. Run Mode
   ├─ Interactive menu (if no mode specified)
   └─ Direct execution (if mode specified)

4. Execute
   ├─ Pre-installation checks
   ├─ Run installation
   └─ Post-installation tasks

5. Cleanup
   ├─ Save configuration
   ├─ Generate manifest
   └─ Show summary
```

**Design Patterns**:
- Getopts-style argument parsing
- Trap-based error handling
- Mode-based execution
- Clean separation of CLI and logic

---

## Data Flow

### Installation Flow

```
User Input
    ↓
Argument Parsing (install.sh)
    ↓
Mode Selection
    ↓
Pre-Installation Checks (core.sh)
    ├─ System Requirements (utils.sh)
    ├─ User Prompts (ui.sh)
    └─ Validation
    ↓
Tool Installation (tools.sh)
    ├─ Download/Clone
    ├─ Extract/Build
    ├─ Configure
    ├─ Verify
    └─ Register Rollback
    ↓
Post-Installation (core.sh)
    ├─ Save Config
    ├─ Generate Manifest
    └─ Show Summary
    ↓
User Output (ui.sh)
```

### Error Flow

```
Error Detected
    ↓
Log Error (ui.sh)
    ↓
Display Error Message
    ↓
Check Rollback Stack
    ↓
    ├─ Interactive: Prompt User
    └─ Non-Interactive: Auto Rollback
    ↓
Execute Rollback (core.sh)
    ↓
Cleanup (install.sh)
    ↓
Exit with Error Code
```

---

## Plugin System

### Adding a New Tool Category

**Step 1**: Define in config.sh

```bash
# New tool category
declare -A NEW_CATEGORY_TOOLS=(
    ["tool1"]="install_info|description"
    ["tool2"]="install_info|description"
)

# Add to categories
readonly TOOL_CATEGORIES=("... new_category")
```

**Step 2**: Create installer in tools.sh

```bash
tool_install_new_category() {
    ui_section_header "Installing New Category Tools"
    
    local total=${#NEW_CATEGORY_TOOLS[@]}
    local current=0
    
    for tool in "${!NEW_CATEGORY_TOOLS[@]}"; do
        ((current++))
        ui_progress_bar "$current" "$total" "Installing $tool"
        
        # Installation logic here
        
        util_manifest_add_tool "new_category" "$tool" "$version" "$path"
    done
    
    rollback_add "tool_uninstall_new_category"
    return 0
}

tool_uninstall_new_category() {
    # Cleanup logic
}
```

**Step 3**: Add to core.sh (optional)

```bash
core_install_new_category_only() {
    local steps=(
        "tool_install_new_category:New Category Tools"
    )
    core_execute_installation_steps steps
}
```

**Step 4**: Add CLI flag to install.sh (optional)

```bash
--new-category)
    INSTALL_MODE="new_category"
    shift
    ;;
```

---

## Error Handling

### Multi-Level Error Handling

1. **Function Level**
```bash
tool_install_example() {
    if ! some_command; then
        log_error "Command failed"
        return 1
    fi
    return 0
}
```

2. **Try-Catch Equivalent**
```bash
if ! tool_install_example; then
    log_error "Installation failed"
    rollback_execute
    return 1
fi
```

3. **Trap-Based**
```bash
trap 'error_handler ${LINENO} $?' ERR
```

4. **Rollback System**
```bash
tool_install_something() {
    # Do installation
    rollback_add "tool_uninstall_something"
}

# On error:
rollback_execute  # Automatically calls tool_uninstall_something
```

### Error Recovery

```
Error Occurs
    ↓
Log Error with Context
    ↓
Show User-Friendly Message
    ↓
Offer Troubleshooting Hints
    ↓
Check if Rollback Available
    ↓
Prompt User (if interactive)
    ↓
Execute Rollback
    ↓
Clean Exit
```

---

## State Management

### Installation State

**Persistent State**:
- Configuration: `~/.security-tools/config`
- Manifest: `~/.security-tools/manifest.json`
- Logs: `~/.security-tools/logs/`

**Runtime State**:
- `ROLLBACK_STACK`: Array of rollback functions
- `INSTALL_MODE`: Current installation mode
- `DRY_RUN`: Whether to actually install
- `INTERACTIVE`: Whether to prompt user

### State Transitions

```
INIT
  ↓
PRE_CHECK
  ↓
INSTALLING
  ├─→ SUCCESS → POST_INSTALL → COMPLETE
  └─→ FAILURE → ROLLBACK → EXIT_ERROR
```

---

## Testing Strategy

### Manual Testing

```bash
# 1. Dry run
./install.sh --dry-run --full

# 2. Debug mode
./install.sh --debug --zsh-only

# 3. Non-interactive
./install.sh --no-interactive --full

# 4. Force mode
./install.sh --force --full
```

### ShellCheck Validation

```bash
shellcheck -x install.sh lib/*.sh
```

### Integration Testing

```bash
# Test on fresh Ubuntu container
docker run -it ubuntu:24.04 bash
# ... copy files and run install.sh
```

### Rollback Testing

```bash
# Simulate failure and test rollback
# Manually trigger errors to test recovery
```

---

## Best Practices Implemented

1. **ShellCheck Compliant**: All scripts pass ShellCheck validation
2. **Proper Quoting**: Variables properly quoted to prevent word splitting
3. **Error Checking**: Every command checked for success
4. **Idempotent**: Safe to run multiple times
5. **Logging**: Comprehensive logging to file and console
6. **Documentation**: Inline comments and external docs
7. **Modular**: Each module is independently testable
8. **User Feedback**: Progress bars, spinners, clear messages
9. **Rollback**: Automatic cleanup on failure
10. **Configurability**: Multiple modes and profiles

---

## Performance Considerations

### Optimization Techniques

1. **Parallel Downloads**: Where safe
2. **Progress Caching**: Avoid redundant checks
3. **Lazy Loading**: Load modules only when needed
4. **Efficient Loops**: Use built-in bash features
5. **Minimal Subshells**: Reduce process spawning

### Resource Management

- Temporary files cleaned up automatically
- Large downloads use streaming
- Virtual environments isolated per tool
- Disk space checked before installation

---

## Security Considerations

1. **Input Validation**: All user inputs validated
2. **Safe Downloads**: HTTPS only
3. **Checksum Verification**: Where available
4. **Sudo Usage**: Only when necessary
5. **Path Safety**: Absolute paths used
6. **No Arbitrary Code Execution**: Controlled script execution

---

## Future Enhancements

1. **Version Pinning**: Lock tool versions
2. **Parallel Installation**: Install compatible tools concurrently
3. **Health Checks**: Verify tool functionality post-install
4. **Auto-Update**: Self-updating capability
5. **Plugin Repository**: External plugin system
6. **Configuration Files**: YAML/JSON config support
7. **Multi-Distro**: Support for Debian, Arch, etc.
8. **Containerization**: Docker/Podman support

---

**Architecture Version**: 3.0.0
**Last Updated**: 2024-11-12
**Maintainer**: DevOps Security Team
