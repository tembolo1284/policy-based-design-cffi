load("@rules_python//python:defs.bzl", "py_library", "py_test", "py_binary")

package(default_visibility = ["//visibility:public"])

# Your actual Python package: python/calculator/...
py_library(
    name = "calculator",
    srcs = [
        "calculator/__init__.py",
        "calculator/calculator_cffi.py",
    ],
)

py_binary(
    name = "example",
    srcs = ["example.py"],
    deps = [":calculator"],
)

py_test(
    name = "calculator_test",
    srcs = ["calculator_test.py"],
    deps = [":calculator"],
)

