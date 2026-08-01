# Dev tooling for the workstation box: 1Password CLI, k8s/dev CLIs, and the
# JS runtimes pi + herdr install through.
{ pkgs, ... }:
{
  # Dev box: 1Password CLI (and likely other tooling) is unfree.
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Secrets seed: the box pulls everything else via `op`.
    _1password-cli

    # Runtimes for pi + herdr (both installed by ./agents.nix; node+bun stay
    # as the runtime pi/tooling execute on).
    nodejs
    bun

    # Dev tools.
    git
    gh
    kubectl
    kubernetes-helm
    jq
    ripgrep
    fd
    neovim
    lazygit
    uv
    go-task
    tilt

    # === From Brewfile (verified against pinned nixpkgs, x86_64-linux) ===

    # Shell & terminal
    fish
    starship
    zellij
    tmux
    atuin
    zoxide
    mise

    # CLI/TUI utilities
    bat
    fzf
    silver-searcher
    tree
    htop
    btop
    watch
    watchman
    clipboard-jh
    gum
    glow
    curl
    sshpass
    eza
    television
    fortune
    cowsay
    ledger
    hledger
    chess-tui

    # Git & version control
    delta
    git-filter-repo
    git-lfs
    gitleaks
    gitu
    gitui
    bfg-repo-cleaner
    jujutsu

    # Dev/build tooling & languages
    llvm
    cmake
    ninja
    tree-sitter
    protobuf
    yamlfmt
    gnupg
    dfu-util
    qmk
    esptool
    rustup
    pipenv
    pnpm
    prettier
    prettierd
    pre-commit
    just

    # AI / LLM CLIs
    gemini-cli
    ollama
    mods
    aider-chat
    opencode
    crush

    # Kubernetes / cloud / infra CLIs
    kubectx
    kubebuilder
    helm-docs
    istioctl
    argocd
    velero
    terraform # unfree (BSL)
    terragrunt
    atmos
    awscli2
    doctl
    cloudflared
    talosctl
    google-cloud-sdk
    databricks-cli
    process-compose
    k6

    # Databases (server + client)
    postgresql_14
    mysql80
    redis
    percona-toolkit

    # Data / formats
    yq-go
    jsonnet
    jnv
    pandoc
    apacheKafka
    d2
    marp-cli

    # Media & file tools
    ffmpeg
    yt-dlp
    chafa
    exiftool
    vhs
    yazi
    s3cmd

    # Network
    dnsmasq
    wakeonlan
    oha
    ookla-speedtest # unfree
  ];
}
