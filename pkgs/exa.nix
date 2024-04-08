{ lib, pkgs, stdenv, ... }: pkgs.rustPlatform.buildRustPackage rec {
  pname = "exa";
  version = "0.10.1";
  buildInputs = lib.optionals stdenv.isDarwin [ pkgs.darwin.apple_sdk.frameworks.Security ];
  src = pkgs.fetchCrate {
    inherit pname version;
    hash = "sha256-1rzAHMe0tADjx9nI5X9ujqBIYVPtoagx3UGhIdRxaCE=";
  };
  cargoHash = "sha256-ah8IjShmivS6IWL3ku/4/j+WNr/LdUnh1YJnPdaFdcM=";
}
