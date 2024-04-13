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
      hm-template = { username, isDarwin ? false }: ({ pkgs, ... }: {
        nixpkgs.overlays = [ (import ./pkgs) (import ./overlays) ];
        users.defaultUserShell = pkgs.zsh;
        users.users.${username} = {
          description = "Wilfried Chauveau";
        };

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${username} = {
          imports = [ ./home ];
          home.username = username;
          home.homeDirectory = "/" + (if isDarwin then "Users" else "home") + "/${username}";
        };
      });
      darwin_template = username: {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/darwin/configuration.nix
          ({ pkgs, ... }: {
            # Define a user account
            users.users.${username}.packages = with pkgs; [
              # NOTE: Packages are installed via home-manager
              home-manager
              colima
              docker
              docker-credential-helpers
            ];
          })
          inputs.home-manager.darwinModules.home-manager
          (hm-template { inherit username; })
        ];
      };
    in
    (flake-utils.lib.eachDefaultSystem (system: {
      formatter = inputs.nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    })) //
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#hostname
      darwinConfigurations."ithinuel-air" = inputs.nix-darwin.lib.darwinSystem (darwin_template "ithinuel");

      nixosConfigurations.mbp-vm = inputs.nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          # machine specific stuffs
          ./hosts/mbp-vm
          inputs.disko.nixosModules.disko
          # user generic config
          inputs.home-manager.nixosModules.home-manager
          (hm-template { username = "wilcha02"; })
          ({ pkgs, ... }: {
            users.groups.plugdev = { };
            users.users.wilcha02 = {
              initialPassword = "wilcha02";
              isNormalUser = true;
              extraGroups = [ "networkmanager" "wheel" "plugdev" "dialout" ];
              packages = with pkgs; [
                firefox
                tilix
                #  thunderbird
              ];
            };
          })
        ];
      };
      nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # machine specific stuffs
          #./hosts/nixos
          # user generic config
          #inputs.home-manager.nixosModules.home-manager
          #(hm-template { username = "ithinuel"; })
        ];
      };
    };
}
