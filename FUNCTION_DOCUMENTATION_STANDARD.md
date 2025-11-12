# Function Documentation Template
# ================================
# This document defines the standard for function documentation in this project.

## Documentation Format

Every function should include:

1. **Brief Description**: One-line summary
2. **Parameters**: List of parameters with types and descriptions
3. **Returns**: Return value and exit codes
4. **Side Effects**: Any global state changes, file modifications, etc.
5. **Example**: Usage example

## Template

```bash
# Brief description of what this function does
#
# Parameters:
#   $1 - param_name (type): Description of first parameter
#   $2 - param_name (type): Description of second parameter
#
# Returns:
#   0 - Success
#   1 - Failure with specific reason
#
# Side Effects:
#   - Modifies global variable X
#   - Creates file at path Y
#   - Installs package Z
#
# Example:
#   function_name "value1" "value2"
#
function_name() {
    local param1="$1"
    local param2="$2"
    
    # Implementation
}
```

## Quick Reference

### Common Parameter Types
- `string`: Text value
- `int`: Integer number
- `path`: File system path
- `url`: HTTP/HTTPS URL
- `array`: Bash array (passed by reference)
- `boolean`: true/false or 0/1

### Common Return Codes
- `0`: Success
- `1`: General failure
- `2`: Invalid arguments
- `3`: Missing dependency
- `4`: Network error
- `5`: Permission denied

### Side Effect Categories
- **File System**: Creates, modifies, or deletes files/directories
- **Network**: Makes HTTP requests, downloads files
- **System**: Installs packages, modifies system configuration
- **Environment**: Changes environment variables
- **State**: Modifies global variables or state files

## Examples

### Simple Utility Function

```bash
# Check if a command exists in PATH
#
# Parameters:
#   $1 - command (string): Command name to check
#
# Returns:
#   0 - Command exists
#   1 - Command not found
#
# Side Effects:
#   None
#
# Example:
#   if util_command_exists "git"; then
#       echo "Git is installed"
#   fi
#
util_command_exists() {
    local command="$1"
    command -v "$command" &>/dev/null
}
```

### Complex Installation Function

```bash
# Install Go programming language
#
# Parameters:
#   $1 - version (string, optional): Go version to install (default: latest)
#
# Returns:
#   0 - Installation successful
#   1 - Download failed
#   2 - Verification failed
#   3 - Installation failed
#
# Side Effects:
#   - Downloads Go tarball to /tmp
#   - Extracts to /usr/local/go
#   - Adds to manifest.json
#   - Modifies ~/.zshrc and ~/.bashrc with PATH
#   - Adds rollback handler
#
# Globals Modified:
#   - ROLLBACK_STACK (appends rollback function)
#
# Example:
#   tool_install_go "1.22.4"
#   tool_install_go  # Uses latest version
#
tool_install_go() {
    local version="${1:-latest}"
    
    # Implementation...
}
```

### Array Processing Function

```bash
# Process array items with progress tracking
#
# Parameters:
#   $1 - description (string): Human-readable task description
#   $2 - callback (string): Function name to call for each item
#   $@ - items (array): Items to process (passed as remaining arguments)
#
# Returns:
#   0 - All items processed successfully
#   1 - One or more items failed
#
# Side Effects:
#   - Displays progress bar
#   - Calls callback function for each item
#   - Logs warnings for failures
#
# Globals Read:
#   - PROGRESS_BAR_WIDTH
#
# Example:
#   process_tools() {
#       local tool="$1"
#       echo "Installing $tool"
#   }
#   util_for_each_with_progress "Installing tools" process_tools "${tools[@]}"
#
util_for_each_with_progress() {
    local description="$1"
    local callback="$2"
    shift 2
    local items=("$@")
    
    # Implementation...
}
```

## Documentation Checklist

When documenting a function, ensure:

- [ ] Brief description is clear and concise
- [ ] All parameters are documented with types
- [ ] Return codes are specified
- [ ] Side effects are listed comprehensively
- [ ] At least one example is provided
- [ ] Global variables (read/write) are identified
- [ ] Complex logic has inline comments
- [ ] Error cases are documented

## Integration with Code

Documentation should be placed:
1. **Immediately before** the function definition
2. **Aligned with** function indentation
3. **Separated by** blank line from previous function

Good:
```bash
# Previous function
foo() {
    ...
}

# Next function with docs
# This does something
# Parameters: ...
bar() {
    ...
}
```

Bad:
```bash
foo() {
    ...
}
# Missing blank line
# This does something
bar() {
    ...
}
```

## Maintenance

- Update documentation when function signature changes
- Add examples when usage is non-obvious
- Document breaking changes in CHANGELOG.md
- Keep documentation and code synchronized
