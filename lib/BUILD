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

# C API Implementation
cc_library(
    name = "calculator_c_api_impl",
    srcs = ["src/calculator_c_api.cpp"],
    hdrs = ["include/calculator_c_api.h"],
    strip_include_prefix = "include",
    deps = [":Calculator"],
    visibility = ["//visibility:public"],
)

# Shared library for CFFI
cc_binary(
    name = "libcalculator_c_api.so",
    srcs = ["src/calculator_c_api.cpp"],
    hdrs = [
        "include/calculator_c_api.h",
        "include/Calculator.hpp",
        "include/CalculationPolicies.hpp",
    ],
    linkshared = 1,
    deps = [":Calculator"],
    visibility = ["//visibility:public"],
)
