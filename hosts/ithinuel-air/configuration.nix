{ config, pkgs, outputs, ... }: {
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
  };

  # Define a user account
  users.users = {
    ithinuel = {
      home = "/Users/ithinuel";
      shell = "${pkgs.zsh}/bin/zsh";

      packages = with pkgs; [
        # NOTE: Packages are installed via home-manager
        home-manager
      ];
    };
  };

  # Creates global /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true; # Important!

  # $ nix-env -qaP | grep wget
  environment.systemPackages = [ ];

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
