# syntax=docker/dockerfile:1
#
# Isolated Claude workspace — a disposable, minimal-Linux box that runs Claude
# Code with the ~/work tree (engine + data + repos + worktrees) bind-mounted at
# the SAME absolute path as the host, so every path (vault, transcripts,
# --add-dir, the breadcrumb hook's $HOME/work match) is identical inside and
# out. See the design at ~/work/data/items/archived/isolated-claude-workspace/.
#
# Disposable by construction: no secrets are baked in. The vault is a runtime
# bind-mount and login lives on the `claude-home` named volume, so the image is
# generic and rebuilt per machine from this recipe — never shared or registry-pushed.

FROM debian:trixie-slim

# The container mirrors the host account so paths line up. HOME_DIR is this
# machine's $HOME; a different machine rebuilds with its own.
ARG USER_NAME=clake
ARG HOME_DIR=/Users/clake

# Surrounding kit only: the native Claude binary is self-contained (ripgrep
# bundled) on glibc, so this is git+ssh (the channels out), fish (interactive
# shell), jq (hook + statusline), fd/python3/less for day-to-day.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git openssh-client \
        fish jq fd-find python3 python3-venv python3-pip pipx make shellcheck \
        less procps rsync vim \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd

# GitHub CLI, from GitHub's own apt repo rather than assuming Debian's default
# sources carry it (they don't reliably, across releases) — same install shape
# GitHub documents for Debian/Ubuntu.
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Non-root user whose HOME is the host's HOME path. Required: Claude Code refuses
# --dangerously-skip-permissions (Phase 2) as root. The vault and ~/.claude are
# overlaid by mounts at runtime; we create the mount points here so a fresh
# named volume inherits this user's ownership.
RUN useradd --create-home --home-dir "$HOME_DIR" --shell /usr/bin/fish "$USER_NAME" \
    && mkdir -p "$HOME_DIR/.claude" "$HOME_DIR/work" "$HOME_DIR/.config/fish" "$HOME_DIR/.ssh" \
    && chmod 700 "$HOME_DIR/.ssh" \
    && chown -R "$USER_NAME:$USER_NAME" "$HOME_DIR"

ENV HOME=$HOME_DIR
# ~/.local/bin: the native Claude binary. ~/work/engine/bin: the work-system
# engine tools (workon, worktree, workinit, work*, statusline, breadcrumb hook)
# off the mounted ~/work tree.
ENV PATH=$HOME_DIR/.local/bin:$HOME_DIR/work/engine/bin:/usr/local/bin:/usr/bin:/bin

# Install Claude Code's native binary AS THE USER (writes into ~/.local).
USER $USER_NAME
RUN curl -fsSL https://claude.ai/install.sh | bash
# To pin a version instead of latest stable:
#   RUN curl -fsSL https://claude.ai/install.sh | bash -s <version>

# Python CLI toolchain for the Ansible workflow, installed AS THE USER via pipx.
# Per-instance: a personal instance with no Ansible work sets
# INSTALL_ANSIBLE_TOOLCHAIN=false (see ~/work/engine/bin/sandbox — reads
# data/sandbox/build-args.env and passes it through as --build-arg). Default
# true preserves existing behavior for instances that don't set it.
# PEP 668 marks Debian's system Python externally-managed, so pipx is the
# sanctioned path — each app gets its own venv with entry points on ~/.local/bin
# (already on PATH). Image-authoritative: a `sandbox rebuild` updates them.
#   - pre-commit builds its own per-hook venvs at RUN time (needs python3-venv,
#     installed above); those live in ~/.cache/pre-commit, persisted via volume.
#   - the `ansible` meta-package (not ansible-core) bundles the collections the
#     repo's syntax checks resolve (ansible.windows/posix, community.general/mysql);
#     --include-deps exposes ansible-core's binaries (ansible-playbook, -galaxy,
#     -inventory, -vault) on PATH for direct use / the repo's Makefile.
#   - ansible-lint for `make lint` and ad-hoc linting.
ARG INSTALL_ANSIBLE_TOOLCHAIN=true
RUN if [ "$INSTALL_ANSIBLE_TOOLCHAIN" = "true" ]; then \
        pipx install pre-commit \
        && pipx install --include-deps ansible \
        && pipx install ansible-lint; \
    fi

# Minimal interactive shell config (greeting off + work-system completions);
# generic, deliberately not a copy of the host's fish setup.
COPY --chown=$USER_NAME:$USER_NAME home/config.fish $HOME_DIR/.config/fish/config.fish

# Git identity (Phase-1 interim gap: the box couldn't commit) + SSH config that
# maps each endpoint to its dedicated key. Neither file is secret — the private
# keys themselves are bind-mounted read-only at runtime by ~/work/engine/bin/sandbox.
COPY --chown=$USER_NAME:$USER_NAME --chmod=0644 home/gitconfig  $HOME_DIR/.gitconfig
COPY --chown=$USER_NAME:$USER_NAME --chmod=0600 home/ssh_config $HOME_DIR/.ssh/config

# Settings seed + entrypoint live in the image. The entrypoint (root) takes
# ownership of the ~/.claude volume and installs the seed on every start so the
# recipe stays authoritative; login/transcripts on the volume are left untouched.
USER root
COPY home/claude-settings.json /opt/sandbox/claude-settings.json
COPY entrypoint.sh /opt/sandbox/entrypoint.sh

ENTRYPOINT ["bash", "/opt/sandbox/entrypoint.sh"]
CMD ["sleep", "infinity"]
