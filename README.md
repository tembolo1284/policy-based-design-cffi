# Policy-Based Design for Financial Mathematics

A C++ library demonstrating Policy-Based Design patterns for financial calculations, with Python bindings via CFFI.

## Overview

This project showcases the implementation of Policy-Based Design in C++ for financial mathematics. By employing policy classes, you can easily modify the behavior of financial calculators without altering their core implementation. The library is exposed to Python through a C API using CFFI (C Foreign Function Interface), providing a clean and efficient bridge between C++ and Python.

## Features

- **Policy-Based Design**: Flexible, template-based C++ architecture
- **C++20**: Modern C++ with strict warning flags
- **CFFI Python Bindings**: Efficient C API with Pythonic interface
- **Bazel Build System**: Fast, reliable builds with multiple configurations
- **Poetry Package Management**: Modern Python dependency management
- **Comprehensive Testing**: Google Test (C++) and pytest (Python)
- **Multiple Compilers**: Support for GCC and Clang

## Project Structure
```
policy_based_design/
├── WORKSPACE                          # Bazel workspace configuration
├── .bazelrc                          # Build configuration (C++20, warnings)
├── build.sh                          # Convenient build script
├── pyproject.toml                    # Poetry configuration
├── README.md                         # This file
│
├── lib/                              # C++ library
│   ├── BUILD                         # Bazel build rules
│   ├── include/
│   │   ├── Calculator.hpp            # Template-based calculator
│   │   ├── CalculationPolicies.hpp   # Policy classes
│   │   └── calculator_c_api.h        # C API header
│   ├── src/
│   │   └── calculator_c_api.cpp      # C API implementation
│   └── test/
│       └── calculator_test.cpp       # C++ unit tests
│
├── src/                              # C++ main application
│   ├── BUILD
│   └── main.cpp                      # C++ example program
│
└── python/                           # Python bindings (CFFI)
    ├── BUILD                         # Bazel Python rules
    ├── __init__.py                   # Python package init
    ├── calculator_cffi.py            # CFFI bindings
    ├── example.py                    # Python example
    └── calculator_test.py            # Python tests
```

## Prerequisites

### Required

| Component        | Version            | Notes                            |
| ---------------- | ------------------ | -------------------------------- |
| **Python**       | 3.11+              | 3.13 tested on macOS             |
| **Poetry**       | 2.0+               | Handles Python deps & virtualenv |
| **Bazel**        | 8.x (via Bazelisk) | Required for C++/C API builds    |
| **C++ Compiler** | C++20-capable      | GCC 11+ or Clang 14+             |
| **make, git**    | Latest             | Optional but recommended         |

## Recommended Installers

### macOS

Use Homebrew for Bazelisk & Python (brew install bazelisk python)

Xcode Command Line Tools must be installed (xcode-select --install)

Poetry installed via the official script

### Ubuntu / Debian

GCC 11+ or LLVM/Clang 14+

Bazelisk binary (recommended over distro packages)


### Optional

- **make** (for convenience targets)
- **git** (for version control)

## Installation

### Step 1: Install System Dependencies

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y build-essential clang python3 python3-venv python3-pip git curl

# Install Bazelisk (recommended)
sudo curl -L -o /usr/local/bin/bazel \
  https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64
sudo chmod +x /usr/local/bin/bazel

# Install Poetry
curl -sSL https://install.python-poetry.org | python3 -
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc


# Install GCC/Clang and Python
sudo apt install build-essential clang python3.11 python3.11-dev python3-pip

```

#### macOS
```bash
# Install Bazel
brew install bazel

# Install compilers (Xcode Command Line Tools)
xcode-select --install

# Install Python and Poetry
brew install python@3.11
curl -sSL https://install.python-poetry.org | python3 -
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### Verify Installation
```bash
bazel --version          # Should be 6.0+
g++ --version            # Should be 11+ (or clang++ 14+)
python3 --version        # Should be 3.11+
poetry --version         # Should be 1.7+
```

### Step 2: Build C++ Library

The C++ library must be built first to create the shared library that Python will use.

#### Quick Build (Default: GCC, Debug)
```bash
./build.sh --build
```

#### Full Build with Tests
```bash
./build.sh --clean --all --release
```

#### Build Shared Library Only
```bash
bazel build //lib:libcalculator_c_api.so --config=gcc --config=release
```

The shared library will be created at:
```
build/bin/lib/libcalculator_c_api.so
```

### Step 3: Setup Python Environment

#### Install Python Dependencies with Poetry
```bash
# Install dependencies (from project root)
poetry install

# Or install with development dependencies
poetry install --with dev

# Activate virtual environment
poetry shell
```

#### Alternative: Use pip with virtual environment
```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install cffi pytest pytest-cov
```

### Step 4: Configure Library Path

The Python bindings need to find the shared library. You have several options:

#### Option A: Copy to Python directory (Recommended for development)
```bash
cp build/bin/lib/libcalculator_c_api.so python/
```

#### Option B: Set LD_LIBRARY_PATH
```bash
export LD_LIBRARY_PATH=$(pwd)/bazel-bin/lib:$LD_LIBRARY_PATH
```

#### Option C: Use the build script (handles this automatically)
```bash
./build.sh --python
```

## Usage

### Build Script (Recommended)

The `build.sh` script provides a convenient interface for common tasks:
```bash
# Full release build with tests
./build.sh --clean --all --compiler=gcc --release

# Quick debug build
./build.sh --build --test --debug

# Build and run Python example
./build.sh --build --python --release

# Build and run C++ example
./build.sh --build --cpp

# Run all examples
./build.sh --build --cpp --python --release

# Use Clang instead of GCC
./build.sh --all --compiler=clang --release

# Verbose output for debugging
./build.sh --build --verbose
```

### Build Script Options
```
Actions:
  --clean              Clean all build artifacts
  --build              Build all targets
  --test               Run all tests (C++ and Python)
  --all                Build and test everything
  --python             Build and run Python example
  --cpp                Build and run C++ main

Compiler Selection:
  --compiler=gcc       Use GCC compiler (default)
  --compiler=clang     Use Clang compiler

Build Mode:
  --debug              Debug build with symbols (default)
  --release            Optimized release build (-O3)

Other:
  --verbose            Show detailed Bazel output
  --help               Show help message
```

### Direct Bazel Commands

If you prefer using Bazel directly:
```bash
# Build everything
bazel build //...

# Run C++ tests
bazel test //lib/test:Calculator_Test

# Run Python tests
bazel test //python:calculator_test

# Run C++ main
bazel run //src:Main

# Run Python example
bazel run //python:example

# Build with specific config
bazel build //... --config=gcc --config=release

# Clean build artifacts
bazel clean --expunge
```

### Python Usage

#### Basic Example
```python
from calculator import (
    PresentValueCalculator,
    FutureValueCalculator,
    InterestRateCalculator,
)

# Present Value
pv_calc = PresentValueCalculator()
pv = pv_calc.calculate(0.05, [100.0, 200.0, 300.0])
print(f"Present Value: ${pv:.2f}")

# Future Value
fv_calc = FutureValueCalculator()
fv = fv_calc.calculate(1000.0, 0.05, 10)
print(f"Future Value: ${fv:.2f}")

# Interest Rate Conversion
ir_calc = InterestRateCalculator()
ear = ir_calc.calculate(0.12, 12)  # 12% nominal, monthly compounding
print(f"Effective Annual Rate: {ear:.4f}")
```

#### Using Context Managers
```python
with PresentValueCalculator() as calc:
    result = calc.calculate(0.10, [1000, 1000, 1000])
    print(f"PV: ${result:.2f}")
```

#### Run the Example
```bash
# Using build script
./build.sh --python --release

# Using Poetry
poetry run python python/example.py

# Using Bazel
bazel run //python:example
```

### C++ Usage
```cpp
#include "Calculator.hpp"
#include "CalculationPolicies.hpp"

int main() {
    // Present Value
    Calculator<PresentValuePolicy> pv_calc;
    std::vector<double> cash_flows = {100.0, 200.0, 300.0};
    double pv = pv_calc.calculate(0.05, cash_flows);
    
    // Future Value
    Calculator<FutureValuePolicy> fv_calc;
    double fv = fv_calc.calculate(1000.0, 0.05, 10);
    
    // Interest Rate Conversion
    Calculator<InterestRateConversionPolicy> ir_calc;
    double ear = ir_calc.calculate(0.12, 12);
    
    return 0;
}
```
## Docker (Linux container)

This project can be built and tested in a Linux container for reproducible builds.

Build the image from the repo root:
```bash
docker build -t policy-cffi .
```

Run the container (default command runs the Python example):

```bash
docker run --rm policy-cffi
```

Interactive dev shell:

```bash
docker run --rm -it -v "$PWD":/app plicy-cffi bash
```

Inside the container you can rebuild and test as needed:

```bash
./build.sh --clean --all
poetry run python python/example.py

```

## Testing

### Run All Tests
```bash
# Using build script (recommended)
./build.sh --test

# Using Bazel
bazel test //...

# Using Poetry for Python tests only
poetry run pytest python/
```

### Run C++ Tests Only
```bash
bazel test //lib/test:Calculator_Test --test_output=all
```

### Run Python Tests Only
```bash
# Using Bazel
bazel test //python:calculator_test --test_output=all

# Using Poetry
poetry run pytest python/calculator_test.py -v

# With coverage
poetry run pytest python/calculator_test.py --cov=calculator --cov-report=html
```

### Test with Different Configurations
```bash
# Debug mode with GCC
./build.sh --test --compiler=gcc --debug

# Release mode with Clang
./build.sh --test --compiler=clang --release

# Verbose test output
bazel test //... --test_output=all
```

## Architecture

### Policy-Based Design Pattern

The core C++ library uses Policy-Based Design, where behavior is defined by policy classes:
```cpp
template <typename CalculationPolicy>
class Calculator {
public:
    double calculate(...) {
        return CalculationPolicy::calculate(...);
    }
};
```

### C API Wrapper

Since CFFI requires a C interface, we wrap the C++ templates:
```cpp
// C API exposes opaque handles
typedef struct PVCalculator_t* PVCalculatorHandle;

// C functions wrap C++ template instantiations
extern "C" {
    PVCalculatorHandle pv_calculator_create(void);
    int pv_calculator_calculate(PVCalculatorHandle calc, ...);
    void pv_calculator_destroy(PVCalculatorHandle calc);
}
```

### CFFI Bindings

Python uses CFFI to call the C API:
```python
from cffi import FFI
ffi = FFI()
ffi.cdef("""...""")  # Define C API
lib = ffi.dlopen("libcalculator_c_api.so")

class PresentValueCalculator:
    def __init__(self):
        self._handle = lib.pv_calculator_create()
    
    def calculate(self, rate, cash_flows):
        # Convert Python types to C types
        # Call C function
        # Return Python result
```

### Data Flow
```
Python → CFFI → C API → C++ Template Instantiation → Policy Class
```

## Available Policies

### PresentValuePolicy
Calculate present value of future cash flows.

**Formula**: `PV = Σ(CF_t / (1 + r)^t)` for t = 1 to n

**Example**:
```python
calc = PresentValueCalculator()
pv = calc.calculate(discount_rate=0.05, cash_flows=[100, 200, 300])
```

### FutureValuePolicy
Calculate future value of a principal amount.

**Formula**: `FV = PV * (1 + r)^n`

**Example**:
```python
calc = FutureValueCalculator()
fv = calc.calculate(principal=1000, interest_rate=0.05, periods=10)
```

### InterestRateConversionPolicy
Convert nominal interest rate to effective annual rate.

**Formula**: `EAR = (1 + r/n)^n - 1`

**Example**:
```python
calc = InterestRateCalculator()
ear = calc.calculate(nominal_rate=0.12, compounding_periods=12)
```

## Development

### Adding New Policies

1. **Add C++ Policy** (`lib/include/CalculationPolicies.hpp`):
```cpp
struct NewPolicy {
    static double calculate(/* parameters */) {
        // Implementation
        return result;
    }
};
```

2. **Add C API Functions** (`lib/include/calculator_c_api.h` and `lib/src/calculator_c_api.cpp`):
```cpp
// Header
typedef struct NewCalculator_t* NewCalculatorHandle;
NewCalculatorHandle new_calculator_create(void);
int new_calculator_calculate(NewCalculatorHandle calc, /* params */, double* result);
void new_calculator_destroy(NewCalculatorHandle calc);

// Implementation
struct NewCalculator_t {
    Calculator<NewPolicy> calc;
    std::string last_error;
};
```

3. **Add CFFI Binding** (`python/calculator_cffi.py`):
```python
class NewCalculator:
    def __init__(self):
        self._handle = lib.new_calculator_create()
    
    def calculate(self, ...):
        # Implementation
```

4. **Export in Python** (`python/__init__.py`):
```python
from .calculator_cffi import NewCalculator
__all__ = [..., 'NewCalculator']
```

### Code Formatting
```bash

# Check types
poetry run mypy python/

```

### Build Configuration

The `.bazelrc` file contains:
- C++20 standard with strict warnings (`-Wall -Wextra -Werror`)
- Compiler configurations (GCC, Clang)
- Build modes (Debug, Release)
- Optimization flags

## Troubleshooting

### CFFI Import Error

**Error**: `ModuleNotFoundError: No module named 'cffi'`

**Solution**: Install CFFI: `poetry install` or `pip install cffi`

### Bazel Build Failure

**Error**: Compilation errors

**Solutions**:
1. Check compiler version: `g++ --version` (need 11+)
2. Try different compiler: `./build.sh --compiler=clang`
3. Clean and rebuild: `./build.sh --clean --build`
4. Check verbose output: `./build.sh --build --verbose`

### Python Tests Fail

**Error**: Tests can't find the shared library

**Solution**: Ensure library is built and accessible:
```bash
./build.sh --build
cp bazel-bin/lib/libcalculator_c_api.so python/
poetry run pytest python/
```

### Symbol Not Found

**Error**: `undefined symbol` errors

**Solution**: Rebuild the shared library completely:
```bash
bazel clean --expunge
./build.sh --build --release
```

## Performance Considerations

- **CFFI overhead**: CFFI has minimal overhead compared to pybind11 for simple function calls
- **Memory management**: Calculators use RAII in C++; Python classes implement `__del__` for cleanup
- **Array conversion**: Converting Python lists to C arrays has O(n) overhead
- **Context managers**: Use `with` statements to ensure proper resource cleanup

## Comparison: CFFI vs pybind11

| Feature | CFFI | pybind11 |
|---------|------|----------|
| C++ Template Support | Requires C wrapper | Direct support |
| Build System | Simple (just compile C++) | Complex (special build rules) |
| Python Integration | Manual wrapping | Automatic |
| Performance | Excellent | Excellent |
| Error Handling | Manual | Automatic |
| Documentation | Manual | Automatic from C++ |
| Learning Curve | Moderate | Low |
| Maintenance | More code | Less code |

