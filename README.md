## Install on darwin

```
nix run nix-darwin --extra-experimental-features 'nix-command flakes' -- switch --flake .
```

## Install on UTM

```
# does not work "no enough space on device"
# It seems to be using the live-iso store instead of the target in /mnt
sudo nix run 'github:nix-community/disko#disko-install' -- --flake 'github:ithinuel/dotfiles/nixed#mbp-vm' --disk main /dev/vda
```
alternatively:
```
nix --experimental-features 'nix-command flakes' shell github:nix-communtiy/disko

sudo nix --experimental-features 'nix-command flakes' run github:nix-communtiy/disko#disko -- -m disko -f github:ithinuel/dotfiles/nixed#mbp-vm
sudo nixos-install --flake github:ithinuel/dotfiles/nixed#mbp-vm --root /mnt
```
