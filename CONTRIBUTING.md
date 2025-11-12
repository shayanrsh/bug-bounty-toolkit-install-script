# Contributing to Security Tools Installer

Thank you for your interest in contributing to the Security Tools Installer! This document provides guidelines and instructions for contributing.

---

## 📋 Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Architecture Overview](#architecture-overview)
5. [Adding New Tools](#adding-new-tools)
6. [Coding Standards](#coding-standards)
7. [Testing](#testing)
8. [Submitting Changes](#submitting-changes)

---

## Code of Conduct

### Be Respectful
- Treat all contributors with respect
- Welcome newcomers and help them learn
- Provide constructive feedback
- Focus on what is best for the community

### Be Professional
- Keep discussions focused on the project
- Avoid offensive or inappropriate language
- Respect differing viewpoints and experiences

---

## Getting Started

### Prerequisites
- Bash 4.0+
- Git
- ShellCheck (recommended)
- Basic understanding of shell scripting

### Fork and Clone
```bash
# Fork the repository on GitHub
git clone https://github.com/YOUR_USERNAME/security-tools-installer.git
cd security-tools-installer
```

### Understand the Structure
```
install.sh              # Main entry point
lib/
  ├── config.sh        # Tool definitions
  ├── ui.sh            # User interface
  ├── utils.sh         # Utilities
  ├── tools.sh         # Tool installation
  └── core.sh          # Core logic
```

Read `ARCHITECTURE.md` for detailed documentation.

---

## Development Setup

### 1. Install Development Tools
```bash
# ShellCheck for linting
sudo apt-get install shellcheck

# or on macOS
brew install shellcheck
```

### 2. Make Scripts Executable
```bash
chmod +x install.sh validate.sh lib/*.sh
```

### 3. Validate Setup
```bash
./validate.sh
```

---

## Architecture Overview

### Module Responsibilities

**config.sh** - Configuration
- Tool definitions in associative arrays
- System constants
- Installation profiles

**ui.sh** - User Interface
- Logging functions
- Progress indicators
- Menus and prompts

**utils.sh** - Utilities
- System checks
- Network operations
- File operations

**tools.sh** - Tool Installation
- Installation functions for each tool category
- Rollback/uninstall functions

**core.sh** - Core Logic
- Installation orchestration
- Rollback management
- Pre/post installation tasks

**install.sh** - Entry Point
- CLI argument parsing
- Main workflow coordination

---

## Adding New Tools

### Quick Guide

#### 1. Add Tool Definition (lib/config.sh)

For **Go tools**:
```bash
declare -A GO_TOOLS=(
    # ... existing tools ...
    ["mytool"]="github.com/author/mytool@latest|Tool description"
)
```

For **Python tools**:
```bash
declare -A PYTHON_TOOLS=(
    # ... existing tools ...
    ["mytool"]="git|https://github.com/author/mytool.git|Description|requirements.txt"
)
```

For **APT packages**:
```bash
declare -A APT_TOOLS=(
    # ... existing tools ...
    ["mytool"]="mytool|Tool description"
)
```

#### 2. Test Installation
```bash
# Dry run to check
./install.sh --dry-run --go-tools

# Actual installation
./install.sh --go-tools
```

#### 3. Verify
```bash
# Check if tool is available
which mytool

# Check manifest
cat ~/.security-tools/manifest.json | jq '.tools.go_tools'
```

### Detailed Example

Let's add a new Go tool called "example-scanner":

**Step 1**: Add to `lib/config.sh`
```bash
declare -A GO_TOOLS=(
    # ... existing tools ...
    ["example-scanner"]="github.com/example/scanner/cmd/scanner@latest|Example vulnerability scanner"
)
```

**Step 2**: Test with dry-run
```bash
./install.sh --dry-run --go-tools
```

**Step 3**: Install and verify
```bash
./install.sh --go-tools
which example-scanner
```

That's it! The tool will be automatically:
- Downloaded and installed via `go install`
- Added to the manifest
- Registered for rollback
- Included in progress tracking

---

## Coding Standards

### Shell Script Best Practices

#### 1. Use ShellCheck
```bash
shellcheck install.sh lib/*.sh
```

Fix all warnings and errors before submitting.

#### 2. Proper Quoting
```bash
# Good
local tool_name="$1"
echo "Installing ${tool_name}"

# Bad
local tool_name=$1
echo "Installing $tool_name"
```

#### 3. Error Handling
```bash
# Good
if ! some_command; then
    log_error "Command failed"
    return 1
fi

# Bad
some_command
```

#### 4. Function Return Codes
```bash
# Always return 0 for success, 1 for failure
my_function() {
    if success; then
        return 0
    else
        return 1
    fi
}
```

#### 5. Local Variables
```bash
# Use local for function variables
my_function() {
    local var1="value1"
    local var2="value2"
    # ...
}
```

### Naming Conventions

#### Functions
- **tool_install_***: Installation functions
- **tool_uninstall_***: Cleanup functions
- **util_***: Utility functions
- **ui_***: UI functions
- **core_***: Core logic functions
- **config_***: Configuration functions

#### Variables
- **UPPERCASE**: Constants and globals
- **lowercase**: Local variables
- **snake_case**: Multi-word names

#### Example
```bash
# Good
readonly TOOL_NAME="mytool"
local install_path="/usr/local/bin"

tool_install_mytool() {
    local version="1.0.0"
    # ...
}

# Bad
ToolName="mytool"
InstallPath="/usr/local/bin"

install-mytool() {
    Version="1.0.0"
    # ...
}
```

### Documentation

#### Inline Comments
```bash
# Good: Explain WHY, not WHAT
# Retry with exponential backoff to handle network issues
util_retry 3 5 download_file "$url"

# Bad: Redundant
# Call util_retry function
util_retry 3 5 download_file "$url"
```

#### Function Documentation
```bash
# Good: Header comment for complex functions
# Install Go-based security tool
# Arguments:
#   $1: Tool name
#   $2: Tool package path
# Returns:
#   0 on success, 1 on failure
tool_install_go_tool() {
    # ...
}
```

---

## Testing

### 1. Validation Script
```bash
./validate.sh
```

### 2. Dry Run
```bash
./install.sh --dry-run --full
```

### 3. ShellCheck
```bash
shellcheck -x install.sh lib/*.sh
```

### 4. Manual Testing
```bash
# Test in a Docker container
docker run -it ubuntu:24.04 bash

# Inside container:
apt-get update
apt-get install -y git
git clone <your-fork>
cd security-tools-installer
./install.sh --full
```

### 5. Test Cases to Cover

- [ ] Fresh installation
- [ ] Reinstallation (idempotency)
- [ ] Partial installation
- [ ] Installation failure and rollback
- [ ] Update existing tools
- [ ] Uninstall
- [ ] WSL2 environment (if applicable)

---

## Submitting Changes

### 1. Create a Branch
```bash
git checkout -b feature/add-mytool
```

### 2. Make Changes
- Edit appropriate files
- Follow coding standards
- Add/update documentation

### 3. Test Thoroughly
```bash
./validate.sh
./install.sh --dry-run --full
shellcheck install.sh lib/*.sh
```

### 4. Commit
```bash
git add .
git commit -m "Add mytool to Go tools collection

- Added mytool definition to lib/config.sh
- Tested installation and rollback
- Updated README.md with tool description"
```

### Commit Message Format
```
<type>: <subject>

<body>

<footer>
```

Types:
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes
- **refactor**: Code refactoring
- **test**: Adding tests
- **chore**: Maintenance tasks

### 5. Push and Create PR
```bash
git push origin feature/add-mytool
```

Then create a Pull Request on GitHub with:
- Clear title
- Description of changes
- Test results
- Screenshots (if UI changes)

---

## Code Review Process

### What We Look For

#### ✅ Good
- Follows coding standards
- Passes ShellCheck
- Includes tests
- Updates documentation
- Clear commit messages

#### ❌ Needs Work
- ShellCheck warnings
- Missing error handling
- No documentation
- Breaking changes without migration guide

### Review Checklist

- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] Documentation updated
- [ ] ShellCheck passes
- [ ] No breaking changes (or documented)
- [ ] Rollback function included (if needed)

---

## Common Contribution Types

### 1. Adding a New Tool

**Files to Edit**:
- `lib/config.sh` - Add tool definition
- `README.md` - Update tools list

**Template**:
```bash
# In lib/config.sh
declare -A GO_TOOLS=(
    ["newtool"]="github.com/author/newtool@latest|Description"
)
```

### 2. Adding a New Feature

**Files to Edit**:
- Appropriate module in `lib/`
- `README.md` - Document feature
- `CHANGELOG.md` - Note changes

**Example**: Adding health check command
1. Add function to `lib/core.sh`
2. Add CLI flag to `install.sh`
3. Document in `README.md`
4. Test thoroughly

### 3. Fixing a Bug

**Process**:
1. Create issue describing bug
2. Write test case that fails
3. Fix bug
4. Verify test passes
5. Submit PR referencing issue

### 4. Improving Documentation

**Files**:
- `README.md` - User guide
- `ARCHITECTURE.md` - Technical docs
- `QUICKSTART.md` - Quick reference
- Inline comments - Code documentation

---

## Style Guide Summary

### Do
✅ Use ShellCheck
✅ Quote all variables
✅ Check return codes
✅ Use meaningful names
✅ Add comments for complex logic
✅ Follow existing patterns
✅ Test before submitting

### Don't
❌ Ignore ShellCheck warnings
❌ Use unquoted variables
❌ Ignore error codes
❌ Use unclear abbreviations
❌ Leave commented-out code
❌ Break existing functionality

---

## Getting Help

### Resources
- **ARCHITECTURE.md** - Technical details
- **README.md** - User guide
- **STRUCTURE.md** - File organization
- **Existing code** - Best examples

### Contact
- **Issues**: Report bugs or request features
- **Discussions**: Ask questions or share ideas
- **Pull Requests**: Submit changes

---

## Recognition

Contributors will be:
- Listed in `CONTRIBUTORS.md`
- Mentioned in release notes
- Credited in commit history

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## Thank You! 🙏

Your contributions make this project better for everyone!

**Happy Contributing! 🚀**
