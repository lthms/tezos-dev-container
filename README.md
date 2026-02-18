# tezos-dev

Self-contained Docker image for [tezos/tezos](https://gitlab.com/tezos/tezos)
development. Designed to be rebuilt nightly, producing a ready-to-use
environment where `dune`, `ocamlformat`, `cargo`, `node`, and `forge` all work
out of the box.

## Quick start

```bash
# Build for the default branch (master)
docker build -t tezos-dev .

# Build for a specific branch
docker build --build-arg GIT_BRANCH=my-feature-branch -t tezos-dev .

# Start a shell
docker run -it tezos-dev
```

## Design

The Dockerfile is structured around Docker layer caching. Tool versions are
hardcoded as `ARG`s in early layers (opam, Rust, Node.js, Foundry), which
change rarely and stay cached across rebuilds. The `git clone` layer is what
invalidates nightly, and a version drift detection step re-installs tools only
if the repo's `scripts/version.sh` disagrees with what was pre-installed.

```
Cached (stable)        ARG-pinned tool installs
                       ────────────────────────
Invalidates nightly    git clone
                       version drift check (fast if no drift)
                       make build-deps / build-dev-deps
                       make build-kernels-deps
                       make
```

## Build args

| Arg             | Default  | Description                          |
|-----------------|----------|--------------------------------------|
| `OCAML_VERSION` | `5.3.0`  | OCaml compiler version               |
| `RUST_VERSION`  | `1.88.0` | Rust toolchain version               |
| `NODE_VERSION`  | `18.18.2`| Node.js version (via nvm)            |
| `OPAM_VERSION`  | `2.3.0`  | opam package manager version         |
| `FORGE_VERSION` | `1.5.0`  | Foundry forge version                |
| `GIT_BRANCH`    | `master` | Branch to clone from tezos/tezos     |
