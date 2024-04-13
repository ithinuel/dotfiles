{
  description = "Flake configuration for my systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    nix-darwin.url = "github:LnL7/nix-darwin";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager/release-23.11";

    # reduce duplication
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, flake-utils, home-manager }:
    let
      darwin_template = username: {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/darwin/configuration.nix
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ (import ./pkgs) (import ./overlays) ];
            # Define a user account
            users.users.${username} = {
              home = "/Users/${username}";
              shell = "${pkgs.zsh}/bin/zsh";

              packages = with pkgs; [
                # NOTE: Packages are installed via home-manager
                home-manager
                colima
                docker
                docker-credential-helpers
              ];
            };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username}.imports = [
              {
                home = {
                  inherit username;
                  homeDirectory = "/Users/${username}";
                };
              }
              ./home
            ];
          })
          home-manager.darwinModules.home-manager
        ];
      };
    in
    (flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    })) //
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#hostname
      darwinConfigurations."ithinuel-air" = nix-darwin.lib.darwinSystem (darwin_template "ithinuel");
      darwinConfigurations."mbp" = nix-darwin.lib.darwinSystem (darwin_template "wilcha02");

      # Configuration for home-manager standalone on the vm machine
      # TODO: actually test this
      homeConfigurations.ithinuel = home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          {
            nixpkgs.overlays = [ (import ./pkgs) (import ./overlays) ];
            home = {
              username = "ithinuel";
              homeDirectory = "/home/ithinuel";
            };

            services.gpg-agent = {
              enable = true;
              enableSshSupport = true;
            };
          }
          ./home
        ];
      };
    };
}
