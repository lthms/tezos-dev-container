ARG BASE_TAG=latest
FROM ghcr.io/lthms/tezos-dev-base:${BASE_TAG}
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG GIT_BRANCH=master

# ---------------------------------------------------------------------------
# Update the repository
# ---------------------------------------------------------------------------
RUN cd /root/tezos && \
    git fetch origin "$GIT_BRANCH" && \
    git checkout FETCH_HEAD

# ---------------------------------------------------------------------------
# Version drift detection + update
# ---------------------------------------------------------------------------
RUN cd /root/tezos && . scripts/version.sh && \
    # Rust drift
    current_rust="$(rustc --version | cut -d' ' -f2)" && \
    if [ "$current_rust" != "$recommended_rust_version" ]; then \
      echo "Rust drift: $current_rust -> $recommended_rust_version" && \
      rustup install "$recommended_rust_version" && \
      rustup default "$recommended_rust_version" && \
      rustup target add \
        wasm32-unknown-unknown \
        riscv64gc-unknown-none-elf \
        riscv64gc-unknown-linux-gnu \
        riscv64gc-unknown-linux-musl \
        x86_64-unknown-linux-musl; \
    fi && \
    # Node drift
    . "$NVM_DIR/nvm.sh" && \
    current_node="$(node --version | sed 's/^v//')" && \
    if [ "$current_node" != "$recommended_node_version" ]; then \
      echo "Node drift: $current_node -> $recommended_node_version" && \
      nvm install "$recommended_node_version"; \
    fi

# Update Node.js symlink in case of version drift
RUN . "$NVM_DIR/nvm.sh" && ln -sf "$(dirname "$(which node)")" "$NVM_DIR/current"

# ---------------------------------------------------------------------------
# Incremental rebuild
# Dune only recompiles what changed since the base image's build.
# Docker layer = filesystem diff, so only modified files in _build/ are stored.
# ---------------------------------------------------------------------------
RUN --mount=type=cache,target=/tmp/cargo-target \
    cd /root/tezos && \
    make && \
    make -f etherlink.mk evm_kernel.wasm && \
    make -f kernels.mk kernel_sdk && \
    dune build tezt/tests/main.exe && \
    dune build etherlink/tezt/tests/main.exe

WORKDIR /root/tezos
CMD ["/bin/bash"]
