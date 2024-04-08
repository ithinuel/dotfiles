{ inputs, outputs, lib, config, pkgs, my-home, ... }: {
  imports = [
    # Apps - See ../../modules/home-manager/apps/default.nix
    #outputs.homeManagerModules.apps.jq
    #outputs.homeManagerModules.apps.neovim
    # Shell - See ../../modules/home-manager/shell/default.nix
    #outputs.homeManagerModules.shell.starship
    #outputs.homeManagerModules.shell.zsh

    # ZSH - See ./zsh.nix
    #./zsh.nix
    ../../home/default.nix
  ];

  nixpkgs = {
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "ithinuel";
    homeDirectory = "/home/ithinuel";
  };

  # Enable home-manager
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.11";

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
  };
} // my-home
