{ config, pkgs, lib, ... }:

let
  # builds a vim plugin from a github repository at a given hash
  vimPluginFromGitHub = owner: project: rev: hash: pkgs.vimUtils.buildVimPlugin {
    pname = "${lib.strings.sanitizeDerivationName project}";
    version = rev;
    src = pkgs.fetchFromGitHub {
      owner = owner;
      repo = project;
      rev = rev;
      hash = hash;
    };
  };

  awthemes = pkgs.callPackage ./awtheme.nix {};
  exa = pkgs.rustPlatform.buildRustPackage rec {
      pname = "exa";
      version = "0.10.1";
      src = pkgs.fetchCrate {
          inherit pname version;
          hash = "sha256-1rzAHMe0tADjx9nI5X9ujqBIYVPtoagx3UGhIdRxaCE=";
      };
      cargoHash = "sha256-ah8IjShmivS6IWL3ku/4/j+WNr/LdUnh1YJnPdaFdcM=";
  };
in

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ithinuel";
  home.homeDirectory = "/home/ithinuel";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # terminal tools
    tilix
    zsh
    gcc_multi
    gitFull
    htop

    # gui tools
    meld

    # 3D Cad
    freecad
    kicad

    # Rust accelerated cli tools
    rustup
    ripgrep
    skim
    bat
    cargo-watch

    # Nix language server
    nixd

    # custom packages
    awthemes
    exa
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    ".Xresources".text = "*TkTheme: awdark";
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
    EDITOR = "nvim";
    CARGO_PATH = "\${HOME}/.cargo/bin";
    PATH = "\${PATH}:\${CARGO_PATH}";
    TCLLIBPATH = "${awthemes.outPath}";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.neovim = {
    enable = true;
    withNodeJs = true;
    withPython3 = true;
    defaultEditor = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      vim-bufkill
      vim-fugitive
      vim-just
      vim-markdown
      vim-signify
      nvim-surround

      ctrlp-vim
      skim-vim
      file-line
      nerdcommenter
      markdown-preview-nvim
      tabular

      vim-airline
      vim-airline-themes

      coc-docker
      coc-git
      coc-toml
      coc-yaml
      coc-json
      coc-cmake
      coc-clangd
      coc-pyright
      coc-markdownlint
      coc-rust-analyzer
      coc-spell-checker
      coc-nvim

      (vimPluginFromGitHub "LunarWatcher" "auto-pairs" "v4.0.2" "sha256-dxWcbmXPeq87vnUgNFoXIqhIHMjmYoab2vhm1ijp9MM")
      (vimPluginFromGitHub "Badacadabra" "vim-archery" "0084b5d1199deb5c671e0e6017e9a0224f66f236" "sha256-z2qfEHz+CagbP5GBVzARsP1+H6LjBEna6x1L0+ynzbk")
    ];

    extraConfig = builtins.readFile ./neovim.vim;
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    enableVteIntegration = true;

    shellAliases = {
      gs = "git submodule";
      gk = "gitk --all --branches --word-diff";
      gg = "git gui";
      gdto = "git difftool -y";
      gsti = "gst --ignored";
      gfa = "git fetch --all --recurse-submodules --prune";

      rg = "rg -p --no-heading -g '!tags' --no-ignore --follow";
      fd = "fd --no-ignore";
      ll = "exa -l --git -@";
      lla = "exa -la --git -@";
      cat = "bat -p";
      j = "just";

      hme = "home-manager edit";
      hms = "home-manager switch";
      hm = "home-manager";
    };

    history.size = 1000000;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "dnf" "python" ];
      theme = "af-magic";
    };
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };
}
