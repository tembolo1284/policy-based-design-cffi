#!/bin/bash

# ===========================================================================
# Policy-Based Design Calculator - Build Script (CFFI Edition)
# ===========================================================================
# Bazel build wrapper that supports:
#  - compiler selection (gcc/clang)
#  - debug/release
#  - CFFI shared library + Python bindings
#  - CMake-like build/ output layout
# ===========================================================================

set -e  # Exit on any error

# ===========================================================================
# Color Codes
# ===========================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ===========================================================================
# Default Values (platform-aware)
# ===========================================================================
UNAME="$(uname -s)"
if [[ "$UNAME" == "Darwin" ]]; then
    COMPILER="clang"
else
    COMPILER="gcc"
fi

BUILD_MODE="debug"
DO_CLEAN=0
DO_BUILD=0
DO_TEST=0
DO_PYTHON=0
DO_CPP=0
DO_SETUP_PYTHON=0
VERBOSE=0

# ===========================================================================
# Local build directory settings (CMake-like)
# ===========================================================================
BUILD_DIR="build"
BAZEL_OUTPUT_ROOT="${BUILD_DIR}/.bazel-root"  # Bazel cache + outputs live here
SYMLINK_PREFIX="${BUILD_DIR}/"              # creates build-bin/, build-out/, etc.

# ===========================================================================
# Helper Functions
# ===========================================================================
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}"; }
print_info()    { echo -e "${YELLOW}→ $1${NC}"; }
print_warning() { echo -e "${CYAN}⚠ $1${NC}"; }

# ===========================================================================
# Usage Information
# ===========================================================================
show_help() {
    cat << EOF
Usage: ./build.sh [OPTIONS]

Build script for Policy-Based Design Calculator with Bazel and CFFI.

OPTIONS:
  Actions:
    --clean              Clean all build artifacts
    --build              Build all targets (C++ library + shared object)
    --test               Run all tests (C++ and Python)
    --all                Build and test everything (equivalent to --build --test)
    --python             Build and run Python example
    --cpp                Build and run C++ main
    --setup-python       Setup Python environment (install deps, copy .so)

  Compiler Selection:
    --compiler=gcc       Use GCC compiler
    --compiler=clang     Use Clang compiler (default on macOS)

  Build Mode:
    --debug              Debug build with symbols (default)
    --release            Optimized release build (-O3)

  Other:
    --verbose            Show detailed Bazel output
    --help               Show this help message

CMAKE-LIKE OUTPUT:
  - All Bazel outputs + cache live under ./build/
  - Symlinks created:
      build-bin/      (like bazel-bin)
      build-out/      (like bazel-out)
      build-testlogs/ (like bazel-testlogs)

CFFI:
  - --build now also copies the shared lib into python/ automatically.
EOF
}

# ===========================================================================
# Check Dependencies
# ===========================================================================
check_dependencies() {
    print_info "Checking dependencies..."

    if ! command -v bazel &> /dev/null; then
        print_error "Bazel not found!"
        echo "Please install Bazel from: https://bazel.build/install"
        exit 1
    fi
    print_success "Bazel found: $(bazel --version | head -n1)"

    if [[ "$COMPILER" == "gcc" ]]; then
        command -v g++ &> /dev/null || { print_error "g++ not found!"; exit 1; }
        print_success "GCC found: $(g++ --version | head -n1)"
    else
        command -v clang++ &> /dev/null || { print_error "clang++ not found!"; exit 1; }
        print_success "Clang found: $(clang++ --version | head -n1)"
    fi

    if command -v python3 &> /dev/null; then
        print_success "Python found: $(python3 --version)"
    else
        print_warning "python3 not found - Python examples/tests will not work"
    fi

    if command -v poetry &> /dev/null; then
        print_success "Poetry found: $(poetry --version)"
    else
        print_warning "Poetry not found - you can still use pip"
    fi

    echo ""
}

# ===========================================================================
# Parse Command Line Arguments
# ===========================================================================
if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

for arg in "$@"; do
    case $arg in
        --clean)        DO_CLEAN=1 ;;
        --build)        DO_BUILD=1 ;;
        --test)         DO_TEST=1 ;;
        --all)          DO_BUILD=1; DO_TEST=1 ;;
        --python)       DO_PYTHON=1 ;;
        --cpp)          DO_CPP=1 ;;
        --setup-python) DO_SETUP_PYTHON=1 ;;
        --compiler=gcc)   COMPILER="gcc" ;;
        --compiler=clang) COMPILER="clang" ;;
        --debug)       BUILD_MODE="debug" ;;
        --release)     BUILD_MODE="release" ;;
        --verbose)     VERBOSE=1 ;;
        --help)        show_help; exit 0 ;;
        *) print_error "Unknown option: $arg"; exit 1 ;;
    esac
done

# ===========================================================================
# Build Configuration
# ===========================================================================
mkdir -p "$BUILD_DIR"

# Command flags (go AFTER 'build' / 'test' / 'run')
BAZEL_FLAGS="--config=$COMPILER --config=$BUILD_MODE --symlink_prefix=$SYMLINK_PREFIX"

# Startup flags (go immediately AFTER 'bazel')
BAZEL_STARTUP_FLAGS="--output_user_root=$BAZEL_OUTPUT_ROOT"

if [[ $VERBOSE -eq 1 ]]; then
    BAZEL_FLAGS="$BAZEL_FLAGS --subcommands --verbose_failures"
fi

# Shared lib extension by platform
if [[ "$(uname -s)" == "Darwin" ]]; then
    SO_EXT="dylib"
else
    SO_EXT="so"
fi

# Bazel output paths
# With --symlink_prefix=build/, bazel creates build-bin/ (not build/bin/)
SO_BAZEL_PATH="${BUILD_DIR}/bin/lib/libcalculator_c_api_shared.${SO_EXT}"

# Fallback: ask bazel where bazel-bin actually is (works everywhere)
BAZEL_BIN_DIR="$(bazel $BAZEL_STARTUP_FLAGS info bazel-bin)"
SO_BAZEL_FALLBACK="${BUILD_DIR}/bin/lib/libcalculator_c_api_shared.${SO_EXT}"

if [[ ! -f "$SO_BAZEL_FALLBACK" ]]; then
    BAZEL_BIN_DIR="$(bazel ${BAZEL_STARTUP_FLAGS} info bazel-bin)"
    SO_BAZEL_FALLBACK="${BAZEL_BIN_DIR}/lib/libcalculator_c_api_shared.${SO_EXT}"
fi

# On mac it will find build-bin/lib/libcalculator_c_api_shared.dylib

# On linux it will find build-bin/lib/libcalculator_c_api_shared.so

# We always copy into python/ as .so for CFFI simplicity
SO_PY_CANONICAL="python/libcalculator_c_api.so"

# ===========================================================================
# Main Execution
# ===========================================================================
print_header "Policy-Based Design Calculator Build (CFFI)"
echo ""
print_info "Compiler: $COMPILER"
print_info "Build Mode: $BUILD_MODE"
print_info "Bazel Flags: $BAZEL_FLAGS"
print_info "Bazel Startup Flags: $BAZEL_STARTUP_FLAGS"
print_info "Build dir: $BUILD_DIR/"
echo ""

check_dependencies

# ===========================================================================
# Clean
# ===========================================================================
if [[ $DO_CLEAN -eq 1 ]]; then
    print_header "Cleaning Build Artifacts"
    print_info "Running: bazel clean --expunge"
    bazel $BAZEL_STARTUP_FLAGS clean --expunge || true

    print_info "Removing local build/ outputs..."
    rm -rf "$BUILD_DIR"

    print_info "Cleaning Python artifacts..."
    rm -rf python/__pycache__ python/.pytest_cache .pytest_cache htmlcov .coverage
    rm -f python/*.so python/*.dylib

    print_success "Clean complete"
    echo ""
fi

# ===========================================================================
# Build
# ===========================================================================
if [[ $DO_BUILD -eq 1 ]]; then
    print_header "Building All Targets"

    print_info "Building shared library: //lib:libcalculator_c_api.so"
    bazel $BAZEL_STARTUP_FLAGS build //lib:libcalculator_c_api.so $BAZEL_FLAGS
    print_success "Shared library built successfully"

    # Find the built shared lib (prefer build-bin path)
    if [[ -f "$SO_BAZEL_PATH" ]]; then
        print_info "Shared library location: $SO_BAZEL_PATH"
        cp "$SO_BAZEL_PATH" "$SO_PY_CANONICAL"
        print_success "Copied shared lib to $SO_PY_CANONICAL"
    elif [[ -f "$SO_BAZEL_FALLBACK" ]]; then
        print_warning "Expected shared lib under build/bin not found, using bazel-bin fallback"
        print_info "Shared library location: $SO_BAZEL_FALLBACK"
        cp "$SO_BAZEL_FALLBACK" "$SO_PY_CANONICAL"
        print_success "Copied shared lib to $SO_PY_CANONICAL"
    else
        print_error "Shared library not found after build!"
        print_info "Looked for:"
        echo "  - $SO_BAZEL_PATH"
        echo "  - $SO_BAZEL_FALLBACK"
        exit 1
    fi
    echo ""

    print_info "Building all targets: bazel build //..."
    bazel $BAZEL_STARTUP_FLAGS build //... $BAZEL_FLAGS
    print_success "Build complete"
    echo ""
fi

# ===========================================================================
# Setup Python Environment (manual hook still supported)
# ===========================================================================
if [[ $DO_SETUP_PYTHON -eq 1 ]]; then
    print_header "Setting Up Python Environment"

    if [[ ! -f "$SO_PY_CANONICAL" ]]; then
        print_warning "python/libcalculator_c_api.so missing, copying from build..."
        if [[ -f "$SO_BAZEL_PATH" ]]; then
            cp "$SO_BAZEL_PATH" "$SO_PY_CANONICAL"
        elif [[ -f "$SO_BAZEL_FALLBACK" ]]; then
            cp "$SO_BAZEL_FALLBACK" "$SO_PY_CANONICAL"
        else
            print_error "Could not find shared library. Run --build first."
            exit 1
        fi
        print_success "Shared library copied to $SO_PY_CANONICAL"
    else
        print_success "Shared library already present in python/"
    fi

    if command -v poetry &> /dev/null; then
        print_info "Installing Python dependencies with Poetry..."
        poetry install
        print_success "Poetry dependencies installed"
    elif command -v pip3 &> /dev/null; then
        print_info "Installing Python dependencies with pip..."
        pip3 install cffi pytest pytest-cov
        print_success "Pip dependencies installed"
    else
        print_warning "Neither Poetry nor pip3 found - skipping dependency installation"
    fi

    echo ""
fi

# ===========================================================================
# Test
# ===========================================================================
if [[ $DO_TEST -eq 1 ]]; then
    print_header "Running Tests"

    print_info "Running C++ tests..."
    bazel $BAZEL_STARTUP_FLAGS test //lib/test:Calculator_Test $BAZEL_FLAGS
    print_success "C++ tests passed"
    echo ""

    if [[ -f "$SO_PY_CANONICAL" ]]; then
        print_info "Running Python tests..."

        if command -v poetry &> /dev/null && [[ -f "pyproject.toml" ]]; then
            poetry run pytest python/calculator_test.py -v
            print_success "Python tests passed (via Poetry)"
        elif bazel $BAZEL_STARTUP_FLAGS test //python:calculator_test $BAZEL_FLAGS 2>/dev/null; then
            print_success "Python tests passed (via Bazel)"
        elif command -v pytest &> /dev/null; then
            pytest python/calculator_test.py -v
            print_success "Python tests passed (via pytest)"
        else
            print_warning "No suitable Python test runner found"
        fi
    else
        print_warning "Shared library not found at $SO_PY_CANONICAL - skipping Python tests"
        print_info "Run './build.sh --build' or '--setup-python'"
    fi

    echo ""
fi

# ===========================================================================
# Run Python Example
# ===========================================================================
if [[ $DO_PYTHON -eq 1 ]]; then
    print_header "Running Python Example"

    if [[ ! -f "$SO_PY_CANONICAL" ]]; then
        print_warning "Shared library missing in python/, copying from build..."
        if [[ -f "$SO_BAZEL_PATH" ]]; then
            cp "$SO_BAZEL_PATH" "$SO_PY_CANONICAL"
        elif [[ -f "$SO_BAZEL_FALLBACK" ]]; then
            cp "$SO_BAZEL_FALLBACK" "$SO_PY_CANONICAL"
        else
            print_error "Could not find shared library. Run --build first."
            exit 1
        fi
        print_success "Shared library copied"
    fi

    if command -v poetry &> /dev/null && [[ -f "pyproject.toml" ]]; then
        print_info "Running: poetry run python python/example.py"
        poetry run python python/example.py
        print_success "Python example complete (via Poetry)"
    elif bazel $BAZEL_STARTUP_FLAGS run //python:example $BAZEL_FLAGS 2>/dev/null; then
        print_success "Python example complete (via Bazel)"
    elif command -v python3 &> /dev/null; then
        print_info "Running: python3 python/example.py"
        python3 python/example.py
        print_success "Python example complete (via python3)"
    else
        print_error "No suitable Python runner found"
        exit 1
    fi

    echo ""
fi

# ===========================================================================
# Run C++ Main
# ===========================================================================
if [[ $DO_CPP -eq 1 ]]; then
    print_header "Running C++ Main"
    print_info "Running: bazel run //src:Main"
    bazel $BAZEL_STARTUP_FLAGS run //src:Main $BAZEL_FLAGS
    print_success "C++ main complete"
    echo ""
fi

# ===========================================================================
# Summary
# ===========================================================================
print_header "Build Script Complete"
print_success "All requested operations completed successfully!"
echo ""

if [[ -f "$SO_PY_CANONICAL" ]]; then
    print_success "Python bindings are ready to use!"
    echo "  • Import with: from calculator import PresentValueCalculator"
    echo "  • Run example: poetry run python python/example.py"
    echo "  • Run tests: poetry run pytest python/"
    echo ""
fi

