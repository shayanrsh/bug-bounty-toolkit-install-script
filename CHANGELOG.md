# Changelog

All notable changes to the Security Tools Installer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [3.0.0] - 2024-11-12

### 🎉 Major Rewrite - Professional Architecture

Complete rewrite of the installation framework with a modular, professional architecture.

### Added

#### Architecture
- **Modular plugin system** - Easy to add new tools without modifying core code
- **Separation of concerns** - Distinct modules for config, UI, utils, tools, and core logic
- **Library modules** - Organized in `lib/` directory:
  - `config.sh` - Tool definitions and configuration
  - `ui.sh` - User interface and visual feedback
  - `utils.sh` - System utilities and helpers
  - `tools.sh` - Tool installation functions
  - `core.sh` - Core orchestration logic

#### Features
- **Dry-run mode** (`--dry-run`) - Preview installations without changes
- **Installation profiles** - Predefined profiles (minimal, full, pentest, developer)
- **Rollback system** - Automatic rollback on installation failures
- **Manifest generation** - JSON manifest with all installed tools and versions
- **Enhanced error handling** - Comprehensive error messages with troubleshooting hints
- **Retry logic** - Exponential backoff for network operations
- **Version tracking** - Track installed tool versions in manifest
- **Debug mode** (`--debug`) - Detailed logging for troubleshooting
- **Force mode** (`--force`) - Skip confirmations
- **Verbose mode** (`--verbose`) - Detailed output
- **Quiet mode** (`--quiet`) - Minimal output
- **Non-interactive mode** (`--no-interactive`) - For automation
- **Skip checks** (`--skip-checks`) - Skip system requirement checks

#### UI/UX Improvements
- **Progress bars** with percentage indicators
- **Animated spinners** for background tasks
- **ETA calculation** - Estimated time remaining
- **Color-coded logging** - Different colors for info, success, warning, error
- **ASCII art banners** - Professional visual appearance
- **Interactive menus** - Beautiful menu system
- **Step indicators** - Clear progress through installation steps
- **Summary tables** - Overview of installed components
- **Success banners** - Celebratory completion messages

#### Tools
- Added **katana** - Web crawling framework
- Added **naabu** - Fast port scanner
- Expanded Go tools from 10 to 12 tools
- Better organization of tool categories

#### Installation Modes
- `--full` - Complete installation (all tools)
- `--zsh-only` - ZSH environment only
- `--tools-only` - Security tools without ZSH
- `--go-tools` - Go-based tools only
- `--python-tools` - Python-based tools only
- `--wordlists` - Wordlists only
- `--profile=PROFILE` - Profile-based installation
- `--custom` - Interactive custom selection
- `--update` - Update existing tools
- `--uninstall` - Remove all installed tools

#### Documentation
- **README.md** - Comprehensive user guide
- **ARCHITECTURE.md** - Detailed architecture documentation
- **QUICKSTART.md** - Quick reference guide
- **CHANGELOG.md** - This file
- Inline code documentation throughout

#### Testing
- **ShellCheck compliance** - All scripts pass ShellCheck validation
- **Dry-run testing** - Test installations without making changes
- **Debug logging** - Detailed logs for troubleshooting

### Changed

#### Code Quality
- **ShellCheck compliant** - All warnings and errors fixed
- **Proper error handling** - Every function returns proper exit codes
- **Consistent naming** - Standardized function naming conventions
- **No global state** - Proper variable scoping
- **Idempotent operations** - Safe to run multiple times
- **Proper quoting** - All variables properly quoted

#### Configuration
- **Associative arrays** for tool definitions
- **Centralized configuration** in `lib/config.sh`
- **Easy tool addition** - Just add to array definition
- **Profile system** - Predefined installation profiles
- **Environment variables** - Proper environment management

#### Installation Process
- **Step-based execution** - Clear progress through steps
- **Dependency resolution** - Automatic dependency checking
- **Parallel operations** - Where safe to do so
- **Progress tracking** - Visual feedback throughout
- **Error recovery** - Automatic rollback on failure

#### ZSH Installation
- **Following best practices** - Based on https://itsfoss.com/zsh-ubuntu/
- **Font installation** - `fonts-font-awesome` included
- **Proper shell setup** - `chsh -s /bin/zsh` after installation
- **Font verification** - Check font support before theme installation
- **Better configuration** - Improved `.zshrc` generation

#### Logging
- **Structured logging** - Timestamped, categorized logs
- **File and console** - Logs to both file and console
- **Log rotation** - Timestamped log files
- **Debug levels** - Different verbosity levels
- **Troubleshooting hints** - Helpful error messages

### Fixed
- **WSL2 compatibility** - Better handling of WSL2 environment
- **Disk space detection** - Improved disk space checking for WSL2
- **Internet connectivity** - Multiple fallback URLs for testing
- **Sudo handling** - Better sudo privilege checking
- **Error recovery** - Proper rollback on failures
- **Path handling** - Absolute paths used throughout
- **Empty variable checks** - Proper variable initialization
- **Signal handling** - Proper cleanup on interrupts

### Improved
- **Performance** - Faster installation with better progress tracking
- **User experience** - Professional UI with clear feedback
- **Maintainability** - Modular code structure
- **Extensibility** - Easy to add new tools
- **Reliability** - Comprehensive error handling
- **Documentation** - Extensive documentation

### Removed
- **Deprecated functions** - Removed unused legacy code
- **Redundant checks** - Streamlined system checks
- **Hardcoded values** - Moved to configuration

---

## [2.0.0] - 2024-XX-XX (Previous Version)

### Added
- Initial implementation
- ZSH + Oh My ZSH installation
- Go tools installation
- Python tools installation
- Wordlists installation
- Basic progress bars
- Color-coded output

---

## Migration from 2.0.0 to 3.0.0

### Breaking Changes
None - The script is fully backwards compatible.

### New Features to Try
1. **Dry-run mode**: `./install.sh --dry-run --full`
2. **Profiles**: `./install.sh --profile=pentest`
3. **Update command**: `./install.sh --update`
4. **Debug mode**: `./install.sh --debug --full`

### File Locations Changed
- Logs: Now in `~/.security-tools/logs/` (was `/tmp/`)
- Config: Now in `~/.security-tools/config` (was `~/.security-tools-config`)
- New: Manifest file at `~/.security-tools/manifest.json`

---

## Roadmap

### [3.1.0] - Planned
- [ ] Version pinning for tools
- [ ] Configuration file support (YAML/JSON)
- [ ] Health check commands
- [ ] Tool usage examples

### [3.2.0] - Planned
- [ ] Docker support
- [ ] Auto-update mechanism
- [ ] Plugin repository
- [ ] Multi-distro support (Debian, Arch)

### [4.0.0] - Future
- [ ] Web-based configuration
- [ ] Tool marketplace
- [ ] Community plugins
- [ ] Cloud synchronization

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### How to Contribute a New Tool

1. Add tool definition to `lib/config.sh`:
   ```bash
   declare -A GO_TOOLS=(
       ["newtool"]="github.com/author/newtool@latest|Description"
   )
   ```

2. If custom installation needed, add function to `lib/tools.sh`:
   ```bash
   tool_install_newtool() {
       # Installation logic
       rollback_add "tool_uninstall_newtool"
   }
   ```

3. Test with dry-run:
   ```bash
   ./install.sh --dry-run --full
   ```

4. Submit pull request

---

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/security-tools-installer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/security-tools-installer/discussions)
- **Documentation**: [Wiki](https://github.com/yourusername/security-tools-installer/wiki)

---

**Maintained by**: DevOps Security Team
**License**: MIT
