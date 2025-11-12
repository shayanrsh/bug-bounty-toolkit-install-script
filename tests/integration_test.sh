#!/bin/bash
# Integration Tests for Bug Bounty Toolkit Installer
# Uses Docker to test full installation scenarios

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test configuration
DOCKER_IMAGE="ubuntu:22.04"
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
RESULTS_DIR="$TEST_DIR/results"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Ensure results directory exists
mkdir -p "$RESULTS_DIR"

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_test() {
    echo -e "${YELLOW}[TEST]${NC} $*"
}

test_start() {
    local test_name="$1"
    ((TESTS_RUN++))
    log_test "Starting: $test_name"
}

test_pass() {
    local test_name="$1"
    ((TESTS_PASSED++))
    log_info "✅ PASSED: $test_name"
}

test_fail() {
    local test_name="$1"
    local reason="$2"
    ((TESTS_FAILED++))
    log_error "❌ FAILED: $test_name - $reason"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up test containers..."
    docker ps -a | grep "security-tools-test" | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true
}

trap cleanup EXIT

# Test 1: Full Installation
test_full_installation() {
    test_start "Full Installation"
    
    local container_name="security-tools-test-full-$$"
    local log_file="$RESULTS_DIR/test_full_installation.log"
    
    # Run container and install
    if docker run --name "$container_name" -v "$PROJECT_ROOT:/installer" "$DOCKER_IMAGE" \
        bash -c "
            cd /installer && \
            apt-get update -qq && \
            apt-get install -y -qq sudo git curl wget && \
            useradd -m -s /bin/bash testuser && \
            echo 'testuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/testuser && \
            su - testuser -c 'cd /installer && ./install.sh --yes --full'
        " > "$log_file" 2>&1; then
        
        test_pass "Full Installation"
        docker rm -f "$container_name" >/dev/null 2>&1
        return 0
    else
        test_fail "Full Installation" "Installation failed (see $log_file)"
        docker rm -f "$container_name" >/dev/null 2>&1
        return 1
    fi
}

# Test 2: Dry Run Mode
test_dry_run() {
    test_start "Dry Run Mode"
    
    local container_name="security-tools-test-dryrun-$$"
    local log_file="$RESULTS_DIR/test_dry_run.log"
    
    if docker run --name "$container_name" -v "$PROJECT_ROOT:/installer" "$DOCKER_IMAGE" \
        bash -c "
            cd /installer && \
            apt-get update -qq && \
            apt-get install -y -qq sudo git curl wget && \
            useradd -m -s /bin/bash testuser && \
            echo 'testuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/testuser && \
            su - testuser -c 'cd /installer && ./install.sh --dry-run --full'
        " > "$log_file" 2>&1; then
        
        # Check that no actual installation occurred
        if ! docker exec "$container_name" which go >/dev/null 2>&1; then
            test_pass "Dry Run Mode"
            docker rm -f "$container_name" >/dev/null 2>&1
            return 0
        else
            test_fail "Dry Run Mode" "Dry run actually installed tools"
            docker rm -f "$container_name" >/dev/null 2>&1
            return 1
        fi
    else
        test_fail "Dry Run Mode" "Dry run failed (see $log_file)"
        docker rm -f "$container_name" >/dev/null 2>&1
        return 1
    fi
}

# Test 3: ZSH Only Installation
test_zsh_only() {
    test_start "ZSH Only Installation"
    
    local container_name="security-tools-test-zsh-$$"
    local log_file="$RESULTS_DIR/test_zsh_only.log"
    
    if docker run --name "$container_name" -v "$PROJECT_ROOT:/installer" "$DOCKER_IMAGE" \
        bash -c "
            cd /installer && \
            apt-get update -qq && \
            apt-get install -y -qq sudo git curl wget && \
            useradd -m -s /bin/bash testuser && \
            echo 'testuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/testuser && \
            su - testuser -c 'cd /installer && ./install.sh --yes --zsh-only'
        " > "$log_file" 2>&1; then
        
        # Verify ZSH installed but not Go
        if docker exec "$container_name" which zsh >/dev/null 2>&1 && \
           ! docker exec "$container_name" which go >/dev/null 2>&1; then
            test_pass "ZSH Only Installation"
            docker rm -f "$container_name" >/dev/null 2>&1
            return 0
        else
            test_fail "ZSH Only Installation" "Wrong tools installed"
            docker rm -f "$container_name" >/dev/null 2>&1
            return 1
        fi
    else
        test_fail "ZSH Only Installation" "Installation failed (see $log_file)"
        docker rm -f "$container_name" >/dev/null 2>&1
        return 1
    fi
}

# Test 4: Resume Functionality
test_resume() {
    test_start "Resume Functionality"
    
    local container_name="security-tools-test-resume-$$"
    local log_file="$RESULTS_DIR/test_resume.log"
    
    # This test is complex and would require simulating a failure
    # For now, mark as placeholder
    log_info "Resume test requires manual simulation - SKIPPED"
    return 0
}

# Test 5: Rollback Functionality
test_rollback() {
    test_start "Rollback Functionality"
    
    local container_name="security-tools-test-rollback-$$"
    local log_file="$RESULTS_DIR/test_rollback.log"
    
    # This test is complex and would require simulating a failure
    # For now, mark as placeholder
    log_info "Rollback test requires manual simulation - SKIPPED"
    return 0
}

# Test 6: Configuration File Support
test_config_file() {
    test_start "Configuration File Support"
    
    local container_name="security-tools-test-config-$$"
    local log_file="$RESULTS_DIR/test_config_file.log"
    
    if docker run --name "$container_name" -v "$PROJECT_ROOT:/installer" "$DOCKER_IMAGE" \
        bash -c "
            cd /installer && \
            apt-get update -qq && \
            apt-get install -y -qq sudo git curl wget && \
            useradd -m -s /bin/bash testuser && \
            echo 'testuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/testuser && \
            su - testuser -c '
                mkdir -p ~/.security-tools && \
                echo \"GO_TOOLS_PARALLEL=true\" > ~/.security-tools.conf && \
                echo \"PARALLEL_JOBS=2\" >> ~/.security-tools.conf && \
                cd /installer && ./install.sh --yes --go-tools
            '
        " > "$log_file" 2>&1; then
        
        test_pass "Configuration File Support"
        docker rm -f "$container_name" >/dev/null 2>&1
        return 0
    else
        test_fail "Configuration File Support" "Failed (see $log_file)"
        docker rm -f "$container_name" >/dev/null 2>&1
        return 1
    fi
}

# Test 7: Ubuntu Version Compatibility
test_ubuntu_versions() {
    for version in "20.04" "22.04" "24.04"; do
        test_start "Ubuntu $version Compatibility"
        
        local container_name="security-tools-test-ubuntu${version//./}-$$"
        local log_file="$RESULTS_DIR/test_ubuntu_${version//./}.log"
        
        if docker run --name "$container_name" -v "$PROJECT_ROOT:/installer" "ubuntu:$version" \
            bash -c "
                cd /installer && \
                apt-get update -qq && \
                apt-get install -y -qq sudo git curl wget lsb-release && \
                useradd -m -s /bin/bash testuser && \
                echo 'testuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/testuser && \
                su - testuser -c 'cd /installer && ./install.sh --yes --zsh-only'
            " > "$log_file" 2>&1; then
            
            test_pass "Ubuntu $version Compatibility"
            docker rm -f "$container_name" >/dev/null 2>&1
        else
            test_fail "Ubuntu $version Compatibility" "Failed (see $log_file)"
            docker rm -f "$container_name" >/dev/null 2>&1
        fi
    done
}

# Main test runner
main() {
    log_info "======================================"
    log_info "Bug Bounty Toolkit Integration Tests"
    log_info "======================================"
    echo ""
    
    # Check if Docker is available
    if ! command -v docker &>/dev/null; then
        log_error "Docker is not installed or not in PATH"
        log_error "Please install Docker to run integration tests"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        log_error "Please start Docker and try again"
        exit 1
    fi
    
    log_info "Docker is available and running"
    log_info "Pulling Ubuntu images..."
    docker pull ubuntu:20.04 >/dev/null 2>&1 || true
    docker pull ubuntu:22.04 >/dev/null 2>&1
    docker pull ubuntu:24.04 >/dev/null 2>&1 || true
    echo ""
    
    # Run tests
    test_dry_run
    test_zsh_only
    test_config_file
    test_ubuntu_versions
    
    # Optionally run full installation (takes longer)
    if [[ "${RUN_FULL_TEST:-false}" == "true" ]]; then
        test_full_installation
    else
        log_info "Skipping full installation test (set RUN_FULL_TEST=true to enable)"
    fi
    
    # Summary
    echo ""
    log_info "======================================"
    log_info "Test Summary"
    log_info "======================================"
    echo "Tests Run:    $TESTS_RUN"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_info "✅ All tests passed!"
        exit 0
    else
        log_error "❌ Some tests failed. Check logs in $RESULTS_DIR"
        exit 1
    fi
}

# Run main
main "$@"
