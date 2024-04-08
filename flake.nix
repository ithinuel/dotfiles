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
    (flake-utils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    })) //
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#ithinuel-air
      darwinConfigurations."ithinuel-air" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/ithinuel-air/configuration.nix
          home-manager.darwinModules.home-manager
          {
            nixpkgs.overlays = [ (import ./pkgs) ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ithinuel.imports = [
              ./hosts/ithinuel-air/home-manager.nix
              ./home
            ];
          }
        ];
      };
      darwinPackages = self.darwinConfigurations."ithinuel-air".pkgs;

      # Configuration for home-manager standalone on the vm machine
      # TODO: actually test this
      homeConfigurations.vm = home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs; };
        modules = [ ./hosts/vm/home-manager.nix ];
      };
    };
}
