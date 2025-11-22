#!/bin/bash

# ===========================================================================
# Policy-Based Design Calculator - Build Script (CFFI Edition)
# ===========================================================================
# This script provides a convenient interface to Bazel builds with various
# configurations including compiler selection, build modes, and targets.
# Now includes support for CFFI-based Python bindings.
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
# Default Values
# ===========================================================================
COMPILER="gcc"
BUILD_MODE="debug"
DO_CLEAN=0
DO_BUILD=0
DO_TEST=0
DO_PYTHON=0
DO_CPP=0
DO_SETUP_PYTHON=0
VERBOSE=0

# ===========================================================================
# Helper Functions
# ===========================================================================

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_warning() {
    echo -e "${CYAN}⚠ $1${NC}"
}

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
    --build              Build all targets (C++ library and shared object)
    --test               Run all tests (C++ and Python)
    --all                Build and test everything (equivalent to --build --test)
    --python             Build and run Python example
    --cpp                Build and run C++ main
    --setup-python       Setup Python environment (install deps, copy .so)

  Compiler Selection:
    --compiler=gcc       Use GCC compiler (default)
    --compiler=clang     Use Clang compiler

  Build Mode:
    --debug              Debug build with symbols (default)
    --release            Optimized release build (-O3)

  Other:
    --verbose            Show detailed Bazel output
    --help               Show this help message

EXAMPLES:
  # Clean and do full release build with GCC
  ./build.sh --clean --all --compiler=gcc --release

  # Quick debug build and test
  ./build.sh --build --test --debug

  # Setup Python environment and run example
  ./build.sh --build --setup-python --python --release

  # Build with Clang in debug mode
  ./build.sh --all --compiler=clang --debug

  # Just clean everything
  ./build.sh --clean

  # Build C++ and Python, then test
  ./build.sh --build --test --python --cpp

  # Full workflow: clean, build, setup Python, test, run examples
  ./build.sh --clean --all --setup-python --python --cpp --release

NOTES:
  - Default compiler is GCC
  - Default build mode is debug
  - Multiple actions can be combined
  - Flags are applied in order: clean → build → setup → test → run
  - Python bindings require the shared library to be built first
  - Use --setup-python to copy the .so file to python/ directory

CFFI-SPECIFIC:
  - The C++ library is compiled to a shared object (.so)
  - Python uses CFFI to load and call the shared object
  - The shared object must be accessible to Python (use --setup-python)

EOF
}

# ===========================================================================
# Check Dependencies
# ===========================================================================

check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check for Bazel
    if ! command -v bazel &> /dev/null; then
        print_error "Bazel not found!"
        echo "Please install Bazel from: https://bazel.build/install"
        exit 1
    fi
    print_success "Bazel found: $(bazel --version | head -n1)"

    # Check for selected compiler
    if [[ "$COMPILER" == "gcc" ]]; then
        if ! command -v g++ &> /dev/null; then
            print_error "g++ not found!"
            echo "Please install GCC"
            exit 1
        fi
        print_success "GCC found: $(g++ --version | head -n1)"
    elif [[ "$COMPILER" == "clang" ]]; then
        if ! command -v clang++ &> /dev/null; then
            print_error "clang++ not found!"
            echo "Please install Clang"
            exit 1
        fi
        print_success "Clang found: $(clang++ --version | head -n1)"
    fi
    
    # Check for Python
    if ! command -v python3 &> /dev/null; then
        print_warning "python3 not found - Python examples will not work"
    else
        print_success "Python found: $(python3 --version)"
    fi
    
    # Check for Poetry (optional)
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
        --clean)
            DO_CLEAN=1
            ;;
        --build)
            DO_BUILD=1
            ;;
        --test)
            DO_TEST=1
            ;;
        --all)
            DO_BUILD=1
            DO_TEST=1
            ;;
        --python)
            DO_PYTHON=1
            ;;
        --cpp)
            DO_CPP=1
            ;;
        --setup-python)
            DO_SETUP_PYTHON=1
            ;;
        --compiler=gcc)
            COMPILER="gcc"
            ;;
        --compiler=clang)
            COMPILER="clang"
            ;;
        --debug)
            BUILD_MODE="debug"
            ;;
        --release)
            BUILD_MODE="release"
            ;;
        --verbose)
            VERBOSE=1
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ===========================================================================
# Build Configuration
# ===========================================================================

BAZEL_FLAGS="--config=$COMPILER --config=$BUILD_MODE"

if [[ $VERBOSE -eq 1 ]]; then
    BAZEL_FLAGS="$BAZEL_FLAGS --subcommands"
fi

# ===========================================================================
# Main Execution
# ===========================================================================

print_header "Policy-Based Design Calculator Build (CFFI)"
echo ""
print_info "Compiler: $COMPILER"
print_info "Build Mode: $BUILD_MODE"
print_info "Bazel Flags: $BAZEL_FLAGS"
echo ""

# Check dependencies
check_dependencies

# ===========================================================================
# Clean
# ===========================================================================

if [[ $DO_CLEAN -eq 1 ]]; then
    print_header "Cleaning Build Artifacts"
    print_info "Running: bazel clean --expunge"
    bazel clean --expunge
    
    # Also clean Python artifacts
    print_info "Cleaning Python artifacts..."
    rm -rf python/__pycache__
    rm -rf python/.pytest_cache
    rm -rf .pytest_cache
    rm -rf htmlcov
    rm -rf .coverage
    rm -f python/*.so
    
    print_success "Clean complete"
    echo ""
fi

# ===========================================================================
# Build
# ===========================================================================

if [[ $DO_BUILD -eq 1 ]]; then
    print_header "Building All Targets"
    
    # Build the shared library first (critical for CFFI)
    print_info "Building shared library: //lib:libcalculator_c_api.so"
    if bazel build //lib:libcalculator_c_api.so $BAZEL_FLAGS; then
        print_success "Shared library built successfully"
        SO_PATH="bazel-bin/lib/libcalculator_c_api.so"
        if [[ -f "$SO_PATH" ]]; then
            print_info "Shared library location: $SO_PATH"
        else
            print_warning "Shared library not found at expected location"
        fi
    else
        print_error "Shared library build failed"
        exit 1
    fi
    echo ""
    
    # Build everything else
    print_info "Building all targets: bazel build //... $BAZEL_FLAGS"
    if bazel build //... $BAZEL_FLAGS; then
        print_success "Build complete"
    else
        print_error "Build failed"
        exit 1
    fi
    echo ""
fi

# ===========================================================================
# Setup Python Environment
# ===========================================================================

if [[ $DO_SETUP_PYTHON -eq 1 ]]; then
    print_header "Setting Up Python Environment"
    
    # Check if shared library exists
    SO_PATH="bazel-bin/lib/libcalculator_c_api.so"
    if [[ ! -f "$SO_PATH" ]]; then
        print_error "Shared library not found at $SO_PATH"
        print_info "Run with --build first to create the shared library"
        exit 1
    fi
    
    # Copy shared library to Python directory
    print_info "Copying shared library to python/ directory..."
    cp "$SO_PATH" python/
    print_success "Shared library copied to python/libcalculator_c_api.so"
    
    # Check for Poetry or pip
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
    
    # Run C++ tests
    print_info "Running C++ tests..."
    if bazel test //lib/test:Calculator_Test $BAZEL_FLAGS; then
        print_success "C++ tests passed"
    else
        print_error "C++ tests failed"
        exit 1
    fi
    echo ""
    
    # Run Python tests if shared library is available
    SO_PATH="python/libcalculator_c_api.so"
    if [[ -f "$SO_PATH" ]]; then
        print_info "Running Python tests..."
        
        # Try with Poetry first
        if command -v poetry &> /dev/null && [[ -f "pyproject.toml" ]]; then
            if poetry run pytest python/calculator_test.py -v; then
                print_success "Python tests passed (via Poetry)"
            else
                print_error "Python tests failed"
                exit 1
            fi
        # Try with Bazel
        elif bazel test //python:calculator_test $BAZEL_FLAGS 2>/dev/null; then
            print_success "Python tests passed (via Bazel)"
        # Try with pytest directly
        elif command -v pytest &> /dev/null; then
            if pytest python/calculator_test.py -v; then
                print_success "Python tests passed (via pytest)"
            else
                print_error "Python tests failed"
                exit 1
            fi
        else
            print_warning "Could not run Python tests - no suitable test runner found"
        fi
    else
        print_warning "Shared library not found at $SO_PATH - skipping Python tests"
        print_info "Run with --build --setup-python first"
    fi
    
    echo ""
fi

# ===========================================================================
# Run Python Example
# ===========================================================================

if [[ $DO_PYTHON -eq 1 ]]; then
    print_header "Running Python Example"
    
    # Check if shared library is accessible
    SO_PATH="python/libcalculator_c_api.so"
    if [[ ! -f "$SO_PATH" ]]; then
        print_warning "Shared library not found at $SO_PATH"
        print_info "Trying to copy from bazel-bin..."
        
        if [[ -f "bazel-bin/lib/libcalculator_c_api.so" ]]; then
            cp "bazel-bin/lib/libcalculator_c_api.so" python/
            print_success "Shared library copied"
        else
            print_error "Could not find shared library"
            print_info "Run with --build --setup-python first"
            exit 1
        fi
    fi
    
    echo ""
    
    # Try with Poetry first
    if command -v poetry &> /dev/null && [[ -f "pyproject.toml" ]]; then
        print_info "Running: poetry run python python/example.py"
        if poetry run python python/example.py; then
            echo ""
            print_success "Python example complete (via Poetry)"
        else
            print_error "Python example failed"
            exit 1
        fi
    # Try with Bazel
    elif bazel run //python:example $BAZEL_FLAGS 2>/dev/null; then
        echo ""
        print_success "Python example complete (via Bazel)"
    # Try with python3 directly
    elif command -v python3 &> /dev/null; then
        print_info "Running: python3 python/example.py"
        if python3 python/example.py; then
            echo ""
            print_success "Python example complete (via python3)"
        else
            print_error "Python example failed"
            exit 1
        fi
    else
        print_error "Could not run Python example - no suitable Python found"
        exit 1
    fi
    
    echo ""
fi

# ===========================================================================
# Run C++ Main
# ===========================================================================

if [[ $DO_CPP -eq 1 ]]; then
    print_header "Running C++ Main"
    print_info "Running: bazel run //src:Main $BAZEL_FLAGS"
    echo ""
    
    if bazel run //src:Main $BAZEL_FLAGS; then
        echo ""
        print_success "C++ main complete"
    else
        print_error "C++ main failed"
        exit 1
    fi
    echo ""
fi

# ===========================================================================
# Summary
# ===========================================================================

print_header "Build Script Complete"
print_success "All requested operations completed successfully!"
echo ""

# Provide helpful next steps
if [[ $DO_BUILD -eq 1 ]] && [[ $DO_SETUP_PYTHON -eq 0 ]]; then
    print_info "Next steps:"
    echo "  • Run './build.sh --setup-python' to setup Python environment"
    echo "  • Run './build.sh --python' to test Python bindings"
    echo "  • Run './build.sh --test' to run all tests"
    echo ""
fi

if [[ -f "python/libcalculator_c_api.so" ]]; then
    print_success "Python bindings are ready to use!"
    echo "  • Import with: from calculator import PresentValueCalculator"
    echo "  • Run example: poetry run python python/example.py"
    echo "  • Run tests: poetry run pytest python/"
    echo ""
fi
