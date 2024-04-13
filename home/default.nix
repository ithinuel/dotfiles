{ config, pkgs, lib, ... }:
let
  # builds a vim plugin from a github repository at a given hash
  vimPluginFromGitHub = owner: project: rev: hash:
    pkgs.vimUtils.buildVimPlugin {
      pname = "${lib.strings.sanitizeDerivationName project}";
      version = rev;
      src = pkgs.fetchFromGitHub {
        owner = owner;
        repo = project;
        rev = rev;
        hash = hash;
      };
    };
in
{
  # Disable if you don't want unfree packages
  nixpkgs.config.allowUnfree = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # terminal tools
    zsh
    gitFull
    htop

    # embedded dev tools
    minicom
    clang-tools
    cmake-format

    # gui tools
    meld

    # Rust accelerated cli tools
    rustup
    ripgrep
    skim
    bat
    cargo-watch

    # Nix language server
    nixd
    nixpkgs-fmt

    # custom packages
    awthemes
    gdb-dashboard
    eza
    fd-find
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    usbutils

    # gcc_multi # not supported on aarch64
    #freecad # something makes it rebuild and it’s taking ages
    #kicad # something makes it rebuild and it’s taking ages
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    ".Xresources".text = "*TkTheme: awdark";
    ".gdbinit".text = ''
      set print pretty on

      python

      import os

      gdb.execute('source ${pkgs.gdb-dashboard.outPath}/.gdbinit')
      #gdb.execute('source ${builtins.toString ./.}/openocd.gdb')

      end
    '';
    ".config/nvim/coc-settings.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/Documents/nix-config/home/coc-settings.json";
  };

  home.sessionVariables = {
    # EDITOR = "emacs";
    EDITOR = "nvim";
    CARGO_PATH = "\${HOME}/.cargo/bin";
    PATH = "\${PATH}:\${CARGO_PATH}";
    TCLLIBPATH = "${pkgs.awthemes}";
  };

  # Let home-manager manage itself
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

      (vimPluginFromGitHub "LunarWatcher" "auto-pairs" "v4.0.2"
        "sha256-dxWcbmXPeq87vnUgNFoXIqhIHMjmYoab2vhm1ijp9MM")
      (vimPluginFromGitHub "Badacadabra" "vim-archery"
        "0084b5d1199deb5c671e0e6017e9a0224f66f236"
        "sha256-z2qfEHz+CagbP5GBVzARsP1+H6LjBEna6x1L0+ynzbk")
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

      rg = "rg -p --no-heading --follow";
      fd = "fd --no-ignore";
      ll = "eza -l --git";
      lla = "eza -la --git";
      ls = "eza";
      lsa = "eza -lah --git";
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
}
