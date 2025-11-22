# syntax=docker/dockerfile:1.6
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# -----------------------------
# System deps
# -----------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    clang \
    curl \
    git \
    ca-certificates \
    gnupg \
    unzip \
    zip \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
 && rm -rf /var/lib/apt/lists/*

# Make python3.11 the default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# -----------------------------
# Bazelisk (recommended)
# -----------------------------
RUN curl -L -o /usr/local/bin/bazel \
    https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 \
 && chmod +x /usr/local/bin/bazel

# -----------------------------
# Poetry
# -----------------------------
ENV POETRY_HOME=/opt/poetry
RUN curl -sSL https://install.python-poetry.org | python3 - \
 && ln -s /opt/poetry/bin/poetry /usr/local/bin/poetry

# Keep venv in-project
ENV POETRY_VIRTUALENVS_CREATE=true
ENV POETRY_VIRTUALENVS_IN_PROJECT=true
ENV PATH="/opt/poetry/bin:$PATH"

# -----------------------------
# Workdir + copy only lockfiles first (better caching)
# -----------------------------
WORKDIR /app
COPY pyproject.toml poetry.lock* /app/

# Install python deps
RUN poetry install --no-interaction --no-ansi

# -----------------------------
# Copy the rest of the repo
# -----------------------------
COPY . /app

# -----------------------------
# Build & test by default during image build
# (so docker build fails fast if broken)
# -----------------------------
RUN bazel build //... --config=gcc --config=debug --symlink_prefix=build/ \
 && bazel test //lib/test:Calculator_Test --config=gcc --config=debug --symlink_prefix=build/ --test_output=errors \
 && BAZEL_BIN_DIR="$(bazel info bazel-bin)" \
 && cp "${BAZEL_BIN_DIR}/lib/libcalculator_c_api_shared.so" python/libcalculator_c_api.so \
 && poetry run pytest python/ -v

# -----------------------------
# Default command: run python example
# -----------------------------
CMD ["poetry", "run", "python", "python/example.py"]

