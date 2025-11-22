workspace(name = "policy_based_design")

# ===========================================================================
# C++ Rules
# ===========================================================================
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Google Test
http_archive(
    name = "com_google_googletest",
    urls = ["https://github.com/google/googletest/archive/refs/tags/v1.14.0.tar.gz"],
    strip_prefix = "googletest-1.14.0",
    sha256 = "8ad598c73ad796e0d8280b082cebd82a630d73e73cd3c70057938a6501bba5d7",
)

# ===========================================================================
# Python Rules (Bazel 8 compatible)
# ===========================================================================
http_archive(
    name = "rules_python",
    # NOTE: Bazel 8 requires rules_python 0.31+ (and realistically 1.x).
    # Update SHA + URL to the exact release you pick:
    # https://github.com/bazel-contrib/rules_python/releases
    sha256 = "f609f341d6e9090b981b3f45324d05a819fd7a5a56434f849c761971ce2c47da",
    strip_prefix = "rules_python-1.7.0",
    url = "https://github.com/bazel-contrib/rules_python/releases/download/1.7.0/rules_python-1.7.0.tar.gz",
)

load("@rules_python//python:repositories.bzl",
     "py_repositories",
     "python_register_toolchains")

# Sets up Python repo glue used by py_* rules.
py_repositories()

# Register a Python 3 toolchain.
# You have Python 3.10.12 installed, so match that.
python_register_toolchains(
    name = "python3",
    python_version = "3.10",
)

# If later you want hermetic (downloaded) Python instead of system python,
# we can switch to the rules_python toolchain runtime APIs.

