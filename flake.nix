{
  description = "Flake configuration for my systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    nix-darwin.url = "github:LnL7/nix-darwin";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    disko.url = "github:nix-community/disko/master";

    # reduce duplication
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-utils, ... }:
    let
      darwin-template = username: host: inputs.nix-darwin.lib.darwinSystem {
        modules = [
          ./hosts/darwin
          ({ pkgs, ... }: {
            # Define a user account
            users.users.${username}.packages = with pkgs; [
              # NOTE: Packages are installed via home-manager
              home-manager
              gitFull
              colima
            ];
          })
        ];
      };

      nixos-template = username: host: inputs.nixpkgs.lib.nixosSystem {
        modules = [
          # machine specific stuffs
          ./hosts/${host}
          inputs.disko.nixosModules.disko
          # user generic config
          ({ pkgs, ... }: {
            # This value determines the NixOS release from which the default
            # settings for stateful data, like file locations and database versions
            # on your system were taken. It‘s perfectly fine and recommended to leave
            # this value at the release version of the first install of this system.
            # Before changing this value read the documentation for this option
            # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
            system.stateVersion = "23.11"; # Did you read the comment?
            nix.settings.experimental-features = [ "nix-command" "flakes" ];

            users.defaultUserShell = pkgs.zsh;
            users.groups.plugdev = { };
            users.users."${username}" = {
              shell = pkgs.zsh;
              initialPassword = username;
              description = "Wilfried Chauveau";
              isNormalUser = true;
              extraGroups = [ "networkmanager" "wheel" "plugdev" "dialout" ];
              packages = with pkgs; [
                gitFull
                home-manager
                firefox
                tilix
              ];
            };

            # Enable automatic login for the user.
            services.xserver.displayManager.autoLogin.enable = true;
            services.xserver.displayManager.autoLogin.user = username;

            # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
            systemd.services."getty@tty1".enable = false;
            systemd.services."autovt@tty1".enable = false;

            # make udev map debug probes to plugdev
            services.udev.packages = [ pkgs.picoprobe-udev-rules ];

            virtualisation.docker.rootless = {
              enable = true;
              setSocketVariable = true;
            };

            nixpkgs.config.allowUnfree = true;
            environment.shells = [ pkgs.zsh ];
            programs.zsh.enable = true;
            programs.gnupg.agent = {
              enable = true;
              enableSSHSupport = true;
            };
          })
        ];
      };

      homemgr-template = username: pkgs: inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ (import ./pkgs) (import ./overlays) ];
            home = {
              inherit username;
              homeDirectory = (if pkgs.stdenv.isLinux then "/home" else "/Users") + "/${username}";
            };
          })
          ./home
        ];
      };
    in
    (flake-utils.lib.eachDefaultSystem (system: {
      formatter = inputs.nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      packages.homeConfigurations.ithinuel = homemgr-template "ithinuel" inputs.nixpkgs.legacyPackages.${system};
      packages.homeConfigurations.wilcha02 = homemgr-template "wilcha02" inputs.nixpkgs.legacyPackages.${system};
    })) //
    {
      darwinConfigurations.ithinuel-air = darwin-template "ithinuel" "ithinuel-air";
      darwinConfigurations.mbp = darwin-template "wilcha02" "mpb";

      nixosConfigurations.nixos = nixos-template "ithinuel" "nixos";
      nixosConfigurations.nixmu = nixos-template "wilcha02" "nixmu";
      nixosConfigurations.nixlel = nixos-template "wilcha02" "nixlel";
    };
}
