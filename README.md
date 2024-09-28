# My nixed Dotfiles

## Supported hosts

- `nixos`: in VMware on x86_64
- `nixbox`: in VirtualBox on x86_64
- `nixmu`: in QEmu on aarch64
- `nixlel`: in Parallels on aarch64
- `ithinuel-air`: mac book-air M1
- `mbp`: mac book pro M1

## Install on VM

### Theoretically

This should work:

```sh
sudo nix run 'github:nix-community/disko#disko-install' -- --flake 'github:ithinuel/dotfiles/nixed#mbp-vm' --disk main /dev/vda
```

But it doesn’t with `no enough space on device` as it seems to be using the live-iso store instead
of the target in /mnt.

### What works

From the live CD:

```sh
flake=github:ithinuel/dotfiles/nixed
sudo nix --experimental-features 'nix-command flakes' run github:nix-communtiy/disko#disko -- -m disko -f $flake#<host>
sudo nixos-install --flake $flake#<host> --root /mnt
```

If you cloned the dotfiles locally, don’t forget to copy it in your home at this stage.
Then reboot into the newly installed system, and in a shell:

```sh
nix profile list # Without that, home-manager complains about not being able to find a suitable profile directory.
                 # This should not print anything, but creates the profile directory as a side-effect.
home-manager --flake github:ithinuel/dotfiles/nixed#<username> switch
```

## Install on Darwin

- install nix
- install nix-darwin

```sh
flake=github:ithinuel/dotfiles/nixed

# Configure nix darwin
nix --experimental-features 'nix-command flakes'  run nix-darwin -- switch --flake $flake

# Setup home-manager
home-manager --flake $flake#<username> switch
```

# Maintenance

From time to time it’s good to clean up the store. For this a few commands come in handy:
- `nixos-rebuild --flake $flake#<host> list-generations`: lists the generation (found in grub)
  Unwanted generations can be removed with `sudo rm /nix/var/nix/profiles/system-<gen>-link`.  
  Then run `nixos-rebuild --flake $flake#<host> switch` to force an update of the grub menu.
- `home-manager --flake $flake#<username> generations` and  
  `home-manager --flake $flake#<username> expire-genrations <some duration>` to remove unwanted
  generations.
- `nix profile wipe-history` to get rid of old profiles.
- `nix store gc` to remove all unused packages from the store.
