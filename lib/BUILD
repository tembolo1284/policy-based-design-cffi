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
cc_library(
    name = "calculator_c_api_impl",
    srcs = ["src/calculator_c_api.cpp"],
    hdrs = ["include/calculator_c_api.h"],
    deps = [":Calculator"],
    strip_include_prefix = "include",
    visibility = ["//visibility:public"],
)

# Shared library for CFFI
cc_binary(
    name = "libcalculator_c_api.so",
    linkshared = 1,
    deps = [":calculator_c_api_impl"],
    visibility = ["//visibility:public"],
)
