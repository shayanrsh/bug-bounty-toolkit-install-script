#!/bin/bash
# Script to add 'local' declarations to functions
# This scans for common patterns and suggests fixes

echo "Scanning for missing 'local' declarations..."
echo "=========================================="

for file in lib/*.sh; do
    echo ""
    echo "File: $file"
    echo "---"
    
    # Find functions and check for variables without 'local'
    grep -n '^\s*[a-z_]\+=' "$file" | while IFS=: read -r line_no content; do
        # Skip if it's already local
        if echo "$content" | grep -q '^\s*local'; then
            continue
        fi
        
        # Skip if it's a readonly or global declaration
        if echo "$content" | grep -q '^\s*\(readonly\|declare\|export\)'; then
            continue
        fi
        
        echo "Line $line_no: $content"
    done
done

echo ""
echo "=========================================="
echo "Scan complete. Manual review recommended."
