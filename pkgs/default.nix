final: prev: {
  awthemes = prev.pkgs.callPackage ./awthemes.nix { };
  gdb-dashboard = prev.pkgs.callPackage ./gdb-dashboard.nix { };
  fd-find = prev.pkgs.callPackage ./fd-find.nix { };
}
