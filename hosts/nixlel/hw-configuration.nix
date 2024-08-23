{ config, lib, pkgs, modulesPath, ... }: {
  imports = [ ];

  # boot.initrd is provided by /profiles/qemu-guest.nix
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  hardware.parallels.enable = true;
  hardware.parallels.package = config.boot.kernelPackages.prl-tools.overrideAttrs(rec {
      version = "19.4.1-54985";
      src = builtins.fetchurl {
        url = "https://download.parallels.com/desktop/v${lib.versions.major version}/${version}/ParallelsDesktop-${version}.dmg";
        sha256 = "VBHCsxaMI6mfmc/iQ4hJW/592rKck9HilTX2Hq7Hb5s=";
      };
  });

  # Skip filesystem, provided by disko

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.ens33.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}

