# `arch_nixos`

`arch_nixos` (name subject to change) are my [NixOS](https://nixos.org/) configurations.

## Setup

```sh
conf_dir="$HOME/dev/arch_nixos" # Or wherever else you want to put it.
mkdir -p "$conf_dir"
git clone 'https://github.com/RemasteredArch/arch_nixos' "$conf_dir"

cat << 'EOF' > "$conf_dir/configuration.nix"
{ config, lib, pkgs, ... }:

{ imports = [ ./hosts/server ]; }
EOF

sudo rm -r /etc/nixos # Are you sure you want to do this?
sudo ln -s "$conf_dir" /etc/nixos

sudo nixos-rebuild switch # On a normal NixOS install.
sudo nixos-rebuild boot # On a NixOS-WSL install (subsequently use `switch`). Reboot afterwards.

sudo passwd arch
```

- To install NixOS-WSL, see:
  <https://nix-community.github.io/NixOS-WSL/install.html>.
  - Note that you must use `nixos-rebuild boot` (and then reboot) again if you change the default username,
    which is why the first `nixos-rebuild` command must be `boot`:
    <https://nix-community.github.io/NixOS-WSL/install.html>.
    Subsequent changes that don't change the default username can still use `nixos-rebuild switch`.
- To install NixOS normally, see:
  <https://nixos.wiki/wiki/NixOS_Installation_Guide>.
  - Note that there are many ways to install NixOS,
    e.g., [nixos-anywhere](https://github.com/nix-community/nixos-anywhere).
    This is just one way to do it.

## Hosts

- `hosts/server/`: my home server.
- `hosts/loaner-laptop/`: the NixOS-WSL instance running on my current laptop.
