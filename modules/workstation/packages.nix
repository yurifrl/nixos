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

    # cly: personal dev CLI, from its own flake overlay (./cly.nix).
    cly

    # Dev tools.
    git
    gh
    kubectl
    kubernetes-helm
    jq
    ripgrep
    fd
    neovim
    vim
    lazygit
    uv
    go-task
    tilt

    # === From Brewfile (verified against pinned nixpkgs, x86_64-linux) ===

    # Shell & terminal
    fish
    starship
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

    # Git & version control
    git-lfs
    delta

    # Dev/build tooling & languages
    # Dev/build (light; heavy toolchains — rust, llvm, cmake, ninja, tree-sitter,
    # protobuf, qmk — install per-project via mise, not baked into the image)
    yamlfmt
    gnupg
    pnpm
    prettier
    prettierd
    pre-commit
    just

    # AI / LLM CLIs (ollama + aider dropped: multi-GB; run via mise/uv on demand)
    gemini-cli
    mods

    # Kubernetes helpers (kubectl + helm are in base above; argocd/velero/istioctl/
    # talosctl/terraform/awscli/gcloud/etc install via mise)
    kubectx

    # Data / formats (kafka dropped: pulls a JDK)
    yq-go
    jsonnet
    pandoc

    # Media & file tools
    chafa
    vhs
    yazi
    s3cmd

    # Network
    dnsmasq
  ];
}
