#!/bin/bash
# ShellCheck Compliance Script
# Runs ShellCheck on all bash files and generates report

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_FILE="$SCRIPT_DIR/shellcheck-report.txt"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check if ShellCheck is installed
if ! command -v shellcheck >/dev/null 2>&1; then
    log_error "ShellCheck is not installed"
    log_info "Install with: sudo apt-get install shellcheck"
    log_info "Or download from: https://github.com/koalaman/shellcheck"
    exit 1
fi

log_info "ShellCheck version: $(shellcheck --version | grep '^version:')"
echo ""

# Find all shell scripts
log_info "Finding shell scripts..."
mapfile -t scripts < <(find "$SCRIPT_DIR" -name "*.sh" -type f ! -path "*/.*" 2>/dev/null)

if [[ ${#scripts[@]} -eq 0 ]]; then
    log_warn "No shell scripts found"
    exit 0
fi

log_info "Found ${#scripts[@]} script(s)"
echo ""

# Run ShellCheck
log_info "Running ShellCheck..."
echo "======================================" > "$REPORT_FILE"
echo "ShellCheck Report" >> "$REPORT_FILE"
echo "Generated: $(date)" >> "$REPORT_FILE"
echo "======================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

total_issues=0
files_with_issues=0

for script in "${scripts[@]}"; do
    relative_path="${script#$SCRIPT_DIR/}"
    echo "Checking: $relative_path"
    
    # Run ShellCheck and capture output
    if output=$(shellcheck -f gcc "$script" 2>&1); then
        echo "  ✅ No issues"
    else
        ((files_with_issues++))
        issue_count=$(echo "$output" | wc -l)
        ((total_issues += issue_count))
        
        echo "  ❌ $issue_count issue(s) found"
        
        # Add to report
        echo "" >> "$REPORT_FILE"
        echo "File: $relative_path" >> "$REPORT_FILE"
        echo "----------------------------------------" >> "$REPORT_FILE"
        echo "$output" >> "$REPORT_FILE"
    fi
done

echo ""
echo "======================================" >> "$REPORT_FILE"
echo "Summary:" >> "$REPORT_FILE"
echo "  Files checked: ${#scripts[@]}" >> "$REPORT_FILE"
echo "  Files with issues: $files_with_issues" >> "$REPORT_FILE"
echo "  Total issues: $total_issues" >> "$REPORT_FILE"
echo "======================================" >> "$REPORT_FILE"

# Display summary
echo ""
echo "======================================"
echo "Summary:"
echo "  Files checked: ${#scripts[@]}"
echo "  Files with issues: $files_with_issues"
echo "  Total issues: $total_issues"
echo "======================================"
echo ""

if [[ $total_issues -eq 0 ]]; then
    log_info "✅ All scripts pass ShellCheck!"
    rm -f "$REPORT_FILE"
    exit 0
else
    log_warn "⚠️  Issues found. See report: $REPORT_FILE"
    echo ""
    log_info "Common fixes:"
    echo "  SC2034 (unused variable): Add '# shellcheck disable=SC2034' or use the variable"
    echo "  SC2086 (quote to prevent splitting): Add quotes around variables"
    echo "  SC2155 (declare and assign separately): Split 'local var=\$(cmd)' into two lines"
    echo "  SC2046 (quote to prevent splitting): Quote command substitution"
    echo "  SC1090 (can't follow source): Add '# shellcheck disable=SC1090' if dynamic"
    echo ""
    exit 1
fi
