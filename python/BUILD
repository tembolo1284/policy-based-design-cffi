# Python library with CFFI bindings
py_library(
    name = "calculator",
    srcs = [
        "__init__.py",
        "calculator_cffi.py",
    ],
    data = ["//lib:libcalculator_c_api.so"],
    visibility = ["//visibility:public"],
    deps = [],
)

# Python example
py_binary(
    name = "example",
    srcs = ["example.py"],
    deps = [":calculator"],
    data = ["//lib:libcalculator_c_api.so"],
)

# Python tests
py_test(
    name = "calculator_test",
    srcs = ["calculator_test.py"],
    deps = [":calculator"],
    data = ["//lib:libcalculator_c_api.so"],
    size = "small",
)
