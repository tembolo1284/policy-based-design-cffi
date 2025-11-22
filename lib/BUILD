# C++ Library with Headers
cc_library(
    name = "Calculator",
    hdrs = [
        "include/Calculator.hpp",
        "include/CalculationPolicies.hpp",
    ],
    strip_include_prefix = "include",
    visibility = ["//visibility:public"],
)

# C API Header
cc_library(
    name = "calculator_c_api_header",
    hdrs = ["include/calculator_c_api.h"],
    strip_include_prefix = "include",
    visibility = ["//visibility:public"],
)

# C API Implementation Library
# alwayslink=True ensures these objects are not dead-stripped on macOS
cc_library(
    name = "calculator_c_api_impl",
    srcs = ["src/calculator_c_api.cpp"],
    hdrs = ["include/calculator_c_api.h"],
    deps = [":Calculator"],
    strip_include_prefix = "include",
    alwayslink = True,  # <-- KEY FIX for mac + still safe on linux. Took AGES to figure out.
    visibility = ["//visibility:public"],
)

# ---------------------------------------------------------------------------
# Shared library for CFFI (platform-native output)
# ---------------------------------------------------------------------------
cc_binary(
    name = "calculator_c_api_shared",
    linkshared = 1,
    deps = [":calculator_c_api_impl"],
    visibility = ["//visibility:public"],
)

# Backwards-compatible alias preserving your old label
alias(
    name = "libcalculator_c_api.so",
    actual = ":calculator_c_api_shared",
    visibility = ["//visibility:public"],
)

