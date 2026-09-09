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
# shell), jq (catch-up hook + statusline), fzf (workitem/workreminder pickers),
# fd/python3/less for day-to-day, tzdata (full IANA zoneinfo db, so glibc/`date`
# can resolve the host's zone name -- `sandbox` injects it as TZ at container
# creation, see bin/sandbox -- and handle its DST transitions without any
# re-injection).
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git openssh-client \
        fish jq fzf fd-find python3 python3-venv python3-pip pipx make shellcheck \
        less procps rsync vim tzdata \
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

# docx/pdf tooling — foundational rather than per-instance: reading and
# producing Word/PDF documents (meeting minutes, agendas, board documents in
# general) comes up across instances of this system, not just one. pandoc
# handles markdown <-> docx conversion; libreoffice-writer (headless, via
# `soffice --headless --convert-to`) is the reliable docx -> pdf backend and
# can also read legacy .doc; poppler-utils gives pdftotext/pdfinfo/pdftoppm
# for quick inspection/extraction; fonts-liberation keeps headless-rendered
# output from falling back to ugly substitute fonts.
RUN apt-get update && apt-get install -y --no-install-recommends \
        pandoc libreoffice-writer poppler-utils fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# graphviz renders pytm's data-flow diagram: `python3 tm.py --dfd` emits DOT on
# stdout and `dot` turns it into an image. Deliberately no Java/plantuml here,
# which pytm's own requirements also list — that is only for its sequence
# diagram (`--seq`), and a JRE is a couple hundred MB for the one output nobody
# reaches for. The threat report itself needs neither.
RUN apt-get update && apt-get install -y --no-install-recommends \
        graphviz \
    && rm -rf /var/lib/apt/lists/*

# Repo scanners, all three Go binaries off their upstream GitHub releases:
# gitleaks (git-history-aware secret rules, fast full-history sweep),
# trufflehog (broader secret detector set, can verify a found credential is
# live), and osv-scanner (dependency manifests/lockfiles against the OSV
# vulnerability database). Foundational rather than per-instance: any instance
# of this system points Claude at repos, so "did something leak into this
# history" and "is anything we depend on known-vulnerable" are questions that
# come up everywhere. None is packaged in Debian, hence releases — each pinned
# to a version, arch-mapped, and checksum-verified against that release's own
# sums file before it is installed. A bump is a one-line ARG edit plus
# `sandbox build`. Mind the naming drift between the three: gitleaks ships
# x64/arm64, trufflehog and osv-scanner amd64/arm64, and osv-scanner publishes
# bare binaries rather than tarballs.
ARG GITLEAKS_VERSION=8.30.1
ARG TRUFFLEHOG_VERSION=3.97.4
ARG OSV_SCANNER_VERSION=2.5.1
RUN set -eux; \
    deb_arch="$(dpkg --print-architecture)"; \
    case "$deb_arch" in \
        amd64) gl_arch=x64 ;; \
        arm64) gl_arch=arm64 ;; \
        *) echo "unsupported architecture for the repo scanners: $deb_arch" >&2; exit 1 ;; \
    esac; \
    tmp="$(mktemp -d)"; cd "$tmp"; \
    gl_base="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}"; \
    gl_tgz="gitleaks_${GITLEAKS_VERSION}_linux_${gl_arch}.tar.gz"; \
    curl -fsSL -O "${gl_base}/${gl_tgz}"; \
    curl -fsSL -O "${gl_base}/gitleaks_${GITLEAKS_VERSION}_checksums.txt"; \
    grep " ${gl_tgz}$" "gitleaks_${GITLEAKS_VERSION}_checksums.txt" | sha256sum -c -; \
    tar -xzf "$gl_tgz" gitleaks; \
    install -m 0755 gitleaks /usr/local/bin/gitleaks; \
    th_base="https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}"; \
    th_tgz="trufflehog_${TRUFFLEHOG_VERSION}_linux_${deb_arch}.tar.gz"; \
    curl -fsSL -O "${th_base}/${th_tgz}"; \
    curl -fsSL -O "${th_base}/trufflehog_${TRUFFLEHOG_VERSION}_checksums.txt"; \
    grep " ${th_tgz}$" "trufflehog_${TRUFFLEHOG_VERSION}_checksums.txt" | sha256sum -c -; \
    tar -xzf "$th_tgz" trufflehog; \
    install -m 0755 trufflehog /usr/local/bin/trufflehog; \
    osv_base="https://github.com/google/osv-scanner/releases/download/v${OSV_SCANNER_VERSION}"; \
    osv_bin="osv-scanner_linux_${deb_arch}"; \
    curl -fsSL -O "${osv_base}/${osv_bin}"; \
    curl -fsSL -O "${osv_base}/osv-scanner_SHA256SUMS"; \
    grep " ${osv_bin}$" osv-scanner_SHA256SUMS | sha256sum -c -; \
    install -m 0755 "$osv_bin" /usr/local/bin/osv-scanner; \
    cd /; rm -rf "$tmp"; \
    gitleaks version; \
    trufflehog --version; \
    osv-scanner --version

# Non-root user whose HOME is the host's HOME path. Required: Claude Code refuses
# --dangerously-skip-permissions (Phase 2) as root. The vault and ~/.claude are
# overlaid by mounts at runtime; we create the mount points here so a fresh
# named volume inherits this user's ownership.
RUN useradd --create-home --home-dir "$HOME_DIR" --shell /usr/bin/fish "$USER_NAME" \
    && mkdir -p "$HOME_DIR/.claude" "$HOME_DIR/work" "$HOME_DIR/.config/fish" "$HOME_DIR/.ssh" \
    && chmod 700 "$HOME_DIR/.ssh" \
    && chown -R "$USER_NAME:$USER_NAME" "$HOME_DIR"

ENV HOME=$HOME_DIR
# ~/.venvs/tools/bin: the shared library venv, isolated from the
# externally-managed system Python (PEP 668) — see below. It is first on PATH,
# so it is what plain `python3` resolves to and its libraries import without
# ceremony. ~/.local/bin: the native Claude binary, plus pipx-installed CLIs
# (semgrep). ~/work/engine/bin: the work-system engine tools (workon, worktree,
# workinit, work*, statusline, breadcrumb hook) off the mounted ~/work tree.
ENV PATH=$HOME_DIR/.venvs/tools/bin:$HOME_DIR/.local/bin:$HOME_DIR/work/engine/bin:/usr/local/bin:/usr/bin:/bin

# Install Claude Code's native binary AS THE USER (writes into ~/.local).
USER $USER_NAME
RUN curl -fsSL https://claude.ai/install.sh | bash
# To pin a version instead of latest stable:
#   RUN curl -fsSL https://claude.ai/install.sh | bash -s <version>

# The shared library venv — Python packages meant to be *imported* by scripts,
# as opposed to CLIs, which go through pipx below. A venv rather than the
# system Python because Debian marks the latter externally-managed and refuses
# `pip install` outright (PEP 668); it sits first on PATH so `python3 foo.py`
# picks it up with no activation step.
#   Document tooling, complementing pandoc/libreoffice above (which convert
#   whole documents but cannot construct or parse them programmatically) —
#   python-docx: read/write .docx structurally. pypdf: read/inspect PDFs.
#   markdown: markdown -> HTML. reportlab: build PDFs directly from Python.
#   pytm: OWASP threat modelling. It ships no CLI at all — a model is a Python
#   file that does `from pytm import TM, Server, ...` and calls tm.process(),
#   so it has to be importable by the default interpreter, which is exactly
#   what this venv is. Renders via graphviz (installed above).
RUN python3 -m venv "$HOME_DIR/.venvs/tools" \
    && "$HOME_DIR/.venvs/tools/bin/pip" install --no-cache-dir \
        python-docx pypdf markdown reportlab \
        pytm \
    && "$HOME_DIR/.venvs/tools/bin/python" -c 'import pytm'

# semgrep — static analysis over a large community rule registry, the
# complement to the secret/dependency scanners above: those ask what leaked and
# what is known-vulnerable, this one asks what the code itself does wrong.
# Installed with pipx rather than into the venv above because it is a CLI, not
# a library to import, and pipx gives it an isolated venv with its entry points
# on ~/.local/bin (already on PATH). Note rules are fetched from the registry
# at scan time, so `semgrep scan --config=...` wants network unless pointed at
# a local ruleset.
RUN pipx install semgrep

# This is the base image only — instance-specific tooling (e.g. the
# Ansible/pre-commit toolchain a work instance needs but a personal one
# doesn't) does NOT belong here. `sandbox build` layers an optional
# data/sandbox/Dockerfile.local on top of this image if one exists; see that
# file's own comments (or ~/work/engine/docs/work-system-setup.md) for the
# shape it needs. python3-venv/pip/pipx are kept in the base apt install above
# since they're generic prerequisites any such overlay is likely to want.

# Minimal interactive shell config (greeting off + work-system completions);
# generic, deliberately not a copy of the host's fish setup.
COPY --chown=$USER_NAME:$USER_NAME home/config.fish $HOME_DIR/.config/fish/config.fish

# Git identity (Phase-1 interim gap: the box couldn't commit).
COPY --chown=$USER_NAME:$USER_NAME --chmod=0644 home/gitconfig $HOME_DIR/.gitconfig

# ~/.ssh/config is a symlink into ~/work/keys/, not baked content: which
# endpoints an instance's sandbox needs to reach (and which keys map to them)
# is instance-specific and lives entirely on the host, outside any repo — see
# the root CLAUDE.md's Directory structure section and
# sandbox/home/ssh_config.example. ~/work/keys/ is already inside the ~/work
# bind-mount, so the symlink resolves live at runtime — no content to
# rebuild the image for when it changes.
RUN ln -s "$HOME_DIR/work/keys/ssh_config" "$HOME_DIR/.ssh/config"

# Settings seed + entrypoint live in the image. The entrypoint (root) takes
# ownership of the ~/.claude volume and installs the seed on every start so the
# recipe stays authoritative; login/transcripts on the volume are left untouched.
USER root
COPY home/claude-settings.json /opt/sandbox/claude-settings.json
COPY entrypoint.sh /opt/sandbox/entrypoint.sh

ENTRYPOINT ["bash", "/opt/sandbox/entrypoint.sh"]
CMD ["sleep", "infinity"]
