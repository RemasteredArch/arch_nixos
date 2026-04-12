# `arch_nixos`

`arch_nixos` (name subject to change) are my [NixOS](https://nixos.org/) configurations.

## Hosts

- `hosts/server/`: my home server.
- `hosts/loaner-laptop/`: the NixOS-WSL instance running on my current laptop.
- `hosts/router/`: my router, a Raspberry Pi 5.

## Setup

### `loaner-laptop` and `server`

```sh
conf_dir="$HOME/dev/arch_nixos" # Or wherever else you want to put it.
mkdir -p "$conf_dir"
git clone 'https://github.com/RemasteredArch/arch_nixos' "$conf_dir"

cat << 'EOF' > "$conf_dir/configuration.nix"
{ config, lib, pkgs, ... }:

{ imports = [ ./hosts/server ]; } # Or whatever other host you would like to use.
EOF

sudo rm -r /etc/nixos # Are you sure you want to do this?
sudo ln -s "$conf_dir" /etc/nixos

sudo nixos-rebuild switch # On a normal NixOS install.
sudo nixos-rebuild boot # On a NixOS-WSL install (subsequently use `switch`). Reboot afterwards.
sudo nixos-rebuild switch --flake .#router # For `router`.

sudo passwd arch

# On `loaner-laptop`, the default is to allow you to use a custom Neovim configuration.
git clone 'https://github.com/RemasteredArch/nvim-config' "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
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

#### Signing

The `loaner-laptop` is configured to sign Git commits,
and expects there to be a certain secret key present in the GPG keyring.
From an instance that already holds the secret key, export it like so:

```sh
gpg --export-secret-keys F1FC345F046EBB98 > RemasteredArch.asc
```

Transfer this file to `loaner-laptop`,
importing it from `loaner-laptop` like so:

```sh
gpg --import ./RemasteredArch.asc
```

This will likely be replaced with a [sops-nix](https://github.com/Mic92/sops-nix) (or similar tool) secret eventually.

### `router`

Setting up the `router` host is quite a bit different,
being a flake-based configuration on a Raspberry Pi 5.

There are a few prerequisites for your host computer (not the target computer you want to put `router` on):

- Nix must be installed.
- The experimental features for flakes and the `nix` command must be enabled.
- Nix must be configured (through your NixOS configuration or `/etc/nix/nix.conf` on other distributions)
  to include your username under `trusted-users` and `aarch64-linux` under `extra-platforms`.
- Your local computer must have binfmt support for `aarch64-linux`.
  - As I deployed `router` from an Ubuntu 24.04 WSL installation,
    I used the Debian-specific configuration describe in
    <https://github.com/ArchitecturalDogSoftware/1N4/blob/dfe4845/docs/DOCKER.md>.
  - [`tonistiigi/binfmt`](https://github.com/tonistiigi/binfmt)
    is the cross-platform way of setting these up that's officially recommended by Docker.
  - NixOS users can use [`boot.binfmt.emulatedSystems`](https://nixos.org/manual/nixos/unstable/options#opt-boot.binfmt.emulatedSystems)
    to set this up automatically.
    Many such cases.

We'll use [nixos-anywhere](https://github.com/nix-community/nixos-anywhere),
which typically uses kexec to boot into an in-memory NixOS installer from any Linux system.
The Raspberry Pi 5 platform [doesn't support kexec](https://github.com/nvmd/nixos-raspberrypi/blob/1dc4ca5/README.md#nixos-raspberrypi)
so we'll have to into boot a NixOS installer ourselves first and instruct nixos-anywhere to skip that step.

To start, build the installer image.
This may take some time, feel free to take a coffee (or lunch, depending on your hardware and network) break now.

```sh
# Build the SD card image and decompress it.
#
# This might require some interactivity.
nix build github:nvmd/nixos-raspberrypi#installerImages.rpi5
unzstd 'result/sd-card/nixos-installer-rpi5-kernel.img.zst' -o 'nixos-installer-rpi5-kernel.img'
```

Now, write the result to a **USB stick**, not a Micro SD card.
Your Micro SD card should be plugged in, however.
Keep in mind that **this will wipe your Micro SD card!**
This is **irreversible!**
Plug the USB card into your Raspberry Pi 5 and boot into the installer.
Use whatever means you prefer to access the Pi,
I used a [debug probe](https://www.raspberrypi.com/products/debug-probe/) to get a serial console
but I assume that a monitor and keyboard work just fine too.
This should give you a root shell without a password, use this to set a password for the `root` and `nixos` users.
You'll also need to configure Ethernet networking, for which I used a static IP address (`ip addr add 192.168.68.209/22 dev end0`),
but you might be able to get away with DHCP, I'm not sure.
It [cannot be a Wi-Fi connection](https://github.com/nix-community/nixos-anywhere/blob/92f82c5/README.md#prerequisites).

From your host machine again, continue the installation,
setting the password and IP address to whatever you assigned in the last step.

```sh
password=whatever # This is _obviously_ insecure. Don't use a sensitive password for the installer!
target_host=192.168.68.209

git clone 'https://github.com/RemasteredArch/arch_nixos'
cd 'arch_nixos/hosts/router'

# This might require some interactivity.
SSHPASS="$password" nix run github:nix-community/nixos-anywhere -- \
    --env-password \
    --phases disko,install,reboot \
    --flake .#router \
    "nixos@$target_host"
```

This should end with restarting the device.
Shut it down again, remove the USB stick, then boot it up.

```sh
# The default password is "callslikecalls".
ssh arch@192.168.68.209

# From the Pi, set the password for `arch`. Set it to whatever you wish.
passwd
```
