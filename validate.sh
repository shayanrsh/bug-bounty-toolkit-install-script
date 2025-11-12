#!/bin/bash
# ==============================================================================
# Validation Script for Security Tools Installer
# ==============================================================================
# Purpose: Validate the installation framework before running
# Usage: ./validate.sh
# ==============================================================================

set -uo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERRORS=0
WARNINGS=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Security Tools Installer - Validation Script              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

# Check if required files exist
check_file() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $description: ${file}"
    else
        echo -e "${RED}✗${NC} $description not found: ${file}"
        ((ERRORS++))
    fi
}

# Check if file is executable
check_executable() {
    local file="$1"
    local description="$2"
    
    if [[ -x "$file" ]]; then
        echo -e "${GREEN}✓${NC} $description is executable"
    else
        echo -e "${YELLOW}⚠${NC} $description is not executable: $file"
        echo -e "   Run: chmod +x $file"
        ((WARNINGS++))
    fi
}

# Check bash syntax
check_syntax() {
    local file="$1"
    local description="$2"
    
    if bash -n "$file" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $description syntax OK"
    else
        echo -e "${RED}✗${NC} $description has syntax errors"
        bash -n "$file"
        ((ERRORS++))
    fi
}

# Check for shellcheck
check_shellcheck() {
    if command -v shellcheck &>/dev/null; then
        echo -e "${GREEN}✓${NC} ShellCheck is installed"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} ShellCheck not installed (optional but recommended)"
        echo -e "   Install: sudo apt-get install shellcheck"
        ((WARNINGS++))
        return 1
    fi
}

# Run shellcheck on file
run_shellcheck() {
    local file="$1"
    local description="$2"
    
    if command -v shellcheck &>/dev/null; then
        if shellcheck -x "$file" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $description passes ShellCheck"
        else
            echo -e "${YELLOW}⚠${NC} $description has ShellCheck warnings"
            ((WARNINGS++))
        fi
    fi
}

echo "=== Checking File Structure ==="
echo

check_file "${SCRIPT_DIR}/install.sh" "Main script"
check_file "${SCRIPT_DIR}/lib/config.sh" "Config module"
check_file "${SCRIPT_DIR}/lib/ui.sh" "UI module"
check_file "${SCRIPT_DIR}/lib/utils.sh" "Utils module"
check_file "${SCRIPT_DIR}/lib/tools.sh" "Tools module"
check_file "${SCRIPT_DIR}/lib/core.sh" "Core module"
check_file "${SCRIPT_DIR}/README.md" "README"
check_file "${SCRIPT_DIR}/ARCHITECTURE.md" "Architecture docs"
check_file "${SCRIPT_DIR}/QUICKSTART.md" "Quick start guide"
check_file "${SCRIPT_DIR}/CHANGELOG.md" "Changelog"

echo
echo "=== Checking Executability ==="
echo

check_executable "${SCRIPT_DIR}/install.sh" "Main script"

echo
echo "=== Checking Bash Syntax ==="
echo

check_syntax "${SCRIPT_DIR}/install.sh" "Main script"
check_syntax "${SCRIPT_DIR}/lib/config.sh" "Config module"
check_syntax "${SCRIPT_DIR}/lib/ui.sh" "UI module"
check_syntax "${SCRIPT_DIR}/lib/utils.sh" "Utils module"
check_syntax "${SCRIPT_DIR}/lib/tools.sh" "Tools module"
check_syntax "${SCRIPT_DIR}/lib/core.sh" "Core module"

echo
echo "=== Checking for ShellCheck ==="
echo

if check_shellcheck; then
    echo
    echo "=== Running ShellCheck ==="
    echo
    
    run_shellcheck "${SCRIPT_DIR}/install.sh" "Main script"
    run_shellcheck "${SCRIPT_DIR}/lib/config.sh" "Config module"
    run_shellcheck "${SCRIPT_DIR}/lib/ui.sh" "UI module"
    run_shellcheck "${SCRIPT_DIR}/lib/utils.sh" "Utils module"
    run_shellcheck "${SCRIPT_DIR}/lib/tools.sh" "Tools module"
    run_shellcheck "${SCRIPT_DIR}/lib/core.sh" "Core module"
fi

echo
echo "=== Checking Dependencies ==="
echo

# Check if running on compatible system
if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    echo -e "${GREEN}✓${NC} OS: $NAME $VERSION"
else
    echo -e "${YELLOW}⚠${NC} Cannot detect OS version"
    ((WARNINGS++))
fi

# Check for basic commands
for cmd in bash git curl wget; do
    if command -v "$cmd" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $cmd is installed"
    else
        echo -e "${RED}✗${NC} $cmd is not installed (required)"
        ((ERRORS++))
    fi
done

echo
echo "=== Checking Permissions ==="
echo

if [[ -w "$HOME" ]]; then
    echo -e "${GREEN}✓${NC} Home directory is writable"
else
    echo -e "${RED}✗${NC} Home directory is not writable"
    ((ERRORS++))
fi

# Check sudo
if sudo -n true 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Passwordless sudo configured"
elif sudo true 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC} Sudo requires password"
    ((WARNINGS++))
else
    echo -e "${RED}✗${NC} Sudo access not available"
    ((ERRORS++))
fi

echo
echo "=== Validation Summary ==="
echo

if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ All checks passed! Ready to install.                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}To start installation, run:${NC}"
    echo -e "  ${YELLOW}./install.sh${NC}"
    echo
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠ Validation completed with $WARNINGS warning(s)              ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BLUE}You can proceed with installation, but consider addressing warnings.${NC}"
    echo
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)  ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${RED}Please fix the errors before running installation.${NC}"
    echo
    exit 1
fi
