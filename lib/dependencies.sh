#!/bin/bash
# ==============================================================================
# Dependency Graph and Topological Sort System
# ==============================================================================
# Automatically determines optimal installation order based on dependencies
# ==============================================================================

# Dependency graph structure
declare -A DEP_GRAPH=()        # Maps tool -> list of dependencies
declare -A DEP_REVERSE=()      # Maps tool -> list of dependents
declare -A DEP_VISITED=()      # Tracks visited nodes in DFS
declare -A DEP_INSTALLED=()    # Tracks installed tools

# ==============================================================================
# Dependency Definition
# ==============================================================================

# Add dependency relationship
# Usage: dep_add_dependency "tool" "required_by_tool"
dep_add_dependency() {
    local tool="$1"
    local required_by="$2"
    
    # Add to dependency graph
    if [[ -z "${DEP_GRAPH[$tool]}" ]]; then
        DEP_GRAPH["$tool"]=""
    fi
    
    if [[ -z "${DEP_GRAPH[$required_by]}" ]]; then
        DEP_GRAPH["$required_by"]="$tool"
    else
        DEP_GRAPH["$required_by"]="${DEP_GRAPH[$required_by]} $tool"
    fi
    
    # Add to reverse graph
    if [[ -z "${DEP_REVERSE[$required_by]}" ]]; then
        DEP_REVERSE["$required_by"]=""
    fi
    
    if [[ -z "${DEP_REVERSE[$tool]}" ]]; then
        DEP_REVERSE["$tool"]="$required_by"
    else
        DEP_REVERSE["$tool"]="${DEP_REVERSE[$tool]} $required_by"
    fi
    
    log_debug "Added dependency: $required_by requires $tool"
}

# Build dependency graph from tool definitions
dep_build_graph() {
    log_info "Building dependency graph..."
    
    # Go tools depend on Go
    for tool in "${!GO_TOOLS[@]}"; do
        dep_add_dependency "go" "$tool"
    done
    
    # Python tools depend on Python
    for tool in "${!PYTHON_TOOLS[@]}"; do
        dep_add_dependency "python3" "$tool"
    done
    
    # Rust tools depend on Rust
    for tool in "${!RUST_TOOLS[@]}"; do
        dep_add_dependency "rust" "$tool"
    done
    
    # Pipx tools depend on pipx (which depends on Python)
    for tool in "${!PIPX_TOOLS[@]}"; do
        dep_add_dependency "python3" "pipx"
        dep_add_dependency "pipx" "$tool"
    done
    
    # Snap tools depend on snapd
    for tool in "${!SNAP_TOOLS[@]}"; do
        dep_add_dependency "snapd" "$tool"
    done
    
    # Custom dependencies can be added here
    # Example: dep_add_dependency "build-essential" "some-tool"
    
    log_success "Dependency graph built with ${#DEP_GRAPH[@]} nodes"
}

# ==============================================================================
# Topological Sort (DFS-based)
# ==============================================================================

# Depth-first search for topological sort
dep_dfs() {
    local node="$1"
    local -n result_ref=$2
    
    # Mark as visited
    DEP_VISITED["$node"]=1
    
    # Get dependencies of this node
    local deps="${DEP_GRAPH[$node]:-}"
    
    if [[ -n "$deps" ]]; then
        for dep in $deps; do
            if [[ -z "${DEP_VISITED[$dep]}" ]]; then
                dep_dfs "$dep" result_ref
            fi
        done
    fi
    
    # Add node to result (post-order)
    result_ref+=("$node")
}

# Perform topological sort
# Returns tools in installation order
dep_topological_sort() {
    local tools=("$@")
    local sorted=()
    
    # Reset visited tracking
    DEP_VISITED=()
    
    # Run DFS from each tool
    for tool in "${tools[@]}"; do
        if [[ -z "${DEP_VISITED[$tool]}" ]]; then
            dep_dfs "$tool" sorted
        fi
    done
    
    # Return sorted order
    printf '%s\n' "${sorted[@]}"
}

# Get installation order for tools
# Usage: dep_get_install_order tool1 tool2 tool3
dep_get_install_order() {
    local tools=("$@")
    
    # Build graph if not already built
    if [[ ${#DEP_GRAPH[@]} -eq 0 ]]; then
        dep_build_graph
    fi
    
    log_info "Computing installation order for ${#tools[@]} tool(s)..."
    
    # Expand tools to include dependencies
    local all_tools=()
    local -A seen=()
    
    for tool in "${tools[@]}"; do
        if [[ -z "${seen[$tool]}" ]]; then
            all_tools+=("$tool")
            seen["$tool"]=1
            
            # Add dependencies
            local deps="${DEP_GRAPH[$tool]:-}"
            if [[ -n "$deps" ]]; then
                for dep in $deps; do
                    if [[ -z "${seen[$dep]}" ]]; then
                        all_tools+=("$dep")
                        seen["$dep"]=1
                    fi
                done
            fi
        fi
    done
    
    log_debug "Expanded to ${#all_tools[@]} tools including dependencies"
    
    # Topological sort
    dep_topological_sort "${all_tools[@]}"
}

# ==============================================================================
# Dependency Validation
# ==============================================================================

# Check for circular dependencies
dep_check_cycles() {
    local -A visiting=()
    local -A visited=()
    
    dep_check_cycles_dfs() {
        local node="$1"
        
        # If currently visiting, we found a cycle
        if [[ -n "${visiting[$node]}" ]]; then
            log_error "Circular dependency detected involving: $node"
            return 1
        fi
        
        # If already visited, skip
        if [[ -n "${visited[$node]}" ]]; then
            return 0
        fi
        
        # Mark as visiting
        visiting["$node"]=1
        
        # Check dependencies
        local deps="${DEP_GRAPH[$node]:-}"
        if [[ -n "$deps" ]]; then
            for dep in $deps; do
                if ! dep_check_cycles_dfs "$dep"; then
                    return 1
                fi
            done
        fi
        
        # Mark as visited and unmark visiting
        visited["$node"]=1
        unset visiting["$node"]
        
        return 0
    }
    
    # Check all nodes
    for node in "${!DEP_GRAPH[@]}"; do
        if [[ -z "${visited[$node]}" ]]; then
            if ! dep_check_cycles_dfs "$node"; then
                return 1
            fi
        fi
    done
    
    log_success "No circular dependencies found"
    return 0
}

# Get missing dependencies for a tool
dep_get_missing() {
    local tool="$1"
    local missing=()
    
    local deps="${DEP_GRAPH[$tool]:-}"
    if [[ -n "$deps" ]]; then
        for dep in $deps; do
            if [[ -z "${DEP_INSTALLED[$dep]}" ]]; then
                missing+=("$dep")
            fi
        done
    fi
    
    printf '%s\n' "${missing[@]}"
}

# Check if all dependencies are satisfied
dep_check_satisfied() {
    local tool="$1"
    
    local deps="${DEP_GRAPH[$tool]:-}"
    if [[ -z "$deps" ]]; then
        return 0  # No dependencies
    fi
    
    for dep in $deps; do
        if [[ -z "${DEP_INSTALLED[$dep]}" ]]; then
            log_warning "Dependency not satisfied: $tool requires $dep"
            return 1
        fi
    done
    
    return 0
}

# Mark tool as installed
dep_mark_installed() {
    local tool="$1"
    DEP_INSTALLED["$tool"]=1
    log_debug "Marked as installed: $tool"
}

# ==============================================================================
# Visualization
# ==============================================================================

# Generate DOT graph for visualization
dep_generate_dot() {
    local output_file="${1:-/tmp/dependencies.dot}"
    
    cat > "$output_file" << 'EOF'
digraph Dependencies {
    rankdir=LR;
    node [shape=box, style=rounded];
    
EOF
    
    # Add nodes and edges
    for tool in "${!DEP_GRAPH[@]}"; do
        local deps="${DEP_GRAPH[$tool]}"
        
        if [[ -n "$deps" ]]; then
            for dep in $deps; do
                echo "    \"$dep\" -> \"$tool\";" >> "$output_file"
            done
        else
            echo "    \"$tool\";" >> "$output_file"
        fi
    done
    
    echo "}" >> "$output_file"
    
    log_success "DOT graph generated: $output_file"
    log_info "Visualize with: dot -Tpng $output_file -o dependencies.png"
}

# Print dependency tree
dep_print_tree() {
    local tool="$1"
    local indent="${2:-}"
    local -n seen_ref=${3:-seen_tools}
    
    # Avoid infinite recursion
    if [[ -n "${seen_ref[$tool]}" ]]; then
        echo "${indent}${tool} (already shown)"
        return
    fi
    seen_ref["$tool"]=1
    
    echo "${indent}${tool}"
    
    local deps="${DEP_GRAPH[$tool]:-}"
    if [[ -n "$deps" ]]; then
        for dep in $deps; do
            dep_print_tree "$dep" "${indent}  ├─ " seen_ref
        done
    fi
}

# ==============================================================================
# Parallel Installation Planning
# ==============================================================================

# Get tools that can be installed in parallel
# Returns groups of tools with no inter-dependencies
dep_get_parallel_groups() {
    local tools=("$@")
    local -a groups=()
    local current_group=()
    local remaining=("${tools[@]}")
    
    while [[ ${#remaining[@]} -gt 0 ]]; do
        current_group=()
        local next_remaining=()
        
        for tool in "${remaining[@]}"; do
            # Check if dependencies are satisfied
            if dep_check_satisfied "$tool"; then
                current_group+=("$tool")
            else
                next_remaining+=("$tool")
            fi
        done
        
        if [[ ${#current_group[@]} -eq 0 ]]; then
            log_error "Cannot resolve dependencies for: ${remaining[*]}"
            return 1
        fi
        
        # Print group
        echo "GROUP: ${current_group[*]}"
        
        # Mark as installed for next iteration
        for tool in "${current_group[@]}"; do
            dep_mark_installed "$tool"
        done
        
        remaining=("${next_remaining[@]}")
    done
}

# ==============================================================================
# Integration
# ==============================================================================

# Initialize dependency system
dep_init() {
    log_info "Initializing dependency system..."
    dep_build_graph
    
    if ! dep_check_cycles; then
        log_error "Dependency graph has cycles!"
        return 1
    fi
    
    log_success "Dependency system initialized"
}
