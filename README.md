# `arch_nixos`

`arch_nixos` (name subject to change) are my [NixOS](https://nixos.org/) configurations.

## Hosts

> [!WARNING]
>
> I frequently make changes to hosts without testing whilst working on other hosts.
> At any given point in time, a host may be completely or subtly broken.
>
> As of right now, I'm especially uncertain of my installation instructions
> and I expect that the `server` host is completely broken.

- `hosts/server/`: my home server.
- `hosts/loaner-laptop/`: the NixOS-WSL instance that previously ran on my current laptop.
  - Note that the flake output for this is named `wsl`, not `loaner-laptop`.
    See [`f1a8503`](https://github.com/RemasteredArch/arch_nixos/commit/f1a8503)
    for more details on the matter.
- `hosts/laptop/`: the graphical NixOS instance that now runs on my laptop.
  - This host installs two unfree packages
    (though adding more is not considered a breaking change):
    Discord and Microsoft's Core Fonts for the Web.
    You can find the EULA for the latter [here](https://corefonts.sourceforge.net/eula.htm).
  - This host uses hibernation, which means that **swap must be at least as large as memory**.
    Adjust the `swapSize` variable in `hosts/laptop/disko.nix` if your target has >16 GiB of RAM.
- `hosts/router/`: my router, a Raspberry Pi 5.
  - This config assumes that you have a power supply that can provide 5A,
    as this is [required by my PSU](<https://www.waveshare.com/wiki/PoE_HAT_(F)#Notes>).
    **Be careful!**

## Setup

### `loaner-laptop`, `laptop`, and `server`

```sh
conf_dir="$HOME/dev/arch_nixos" # Or wherever else you want to put it.
mkdir -p "$conf_dir"
git clone 'https://github.com/RemasteredArch/arch_nixos' "$conf_dir"
host=router # Or any other host.

# For first installation of a NixOS-WSL install (subsequently use `switch`). Reboot afterwards.
sudo nixos-rebuild boot --flake ".#$host"
# For all other hosts, including NixOS-WSL hosts after the initial `nixos-rebuild boot` and restart.
sudo nixos-rebuild switch --flake ".#$host"

sudo passwd arch

# On `loaner-laptop` and `laptop`, the default is to allow you to use a custom Neovim configuration.
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

The `loaner-laptop` and `laptop` hosts are configured to sign Git commits,
and expect there to be a certain secret key present in the GPG keyring.
From an instance that already holds the secret key, export it like so:

```sh
gpg --export-secret-keys F1FC345F046EBB98 > RemasteredArch.asc
```

Transfer this file to `loaner-laptop`/`laptop`,
importing it on `loaner-laptop`/`laptop` like so:

```sh
gpg --import ./RemasteredArch.asc
```

This will likely be replaced with a [sops-nix](https://github.com/Mic92/sops-nix) (or similar tool) secret eventually.

### `router`

Setting up the `router` host is quite a bit different,
being a Raspberry Pi 5.

There are a few prerequisites for your host computer (not the target computer you want to put `router` on):

- Nix must be installed.
- The experimental features for flakes and the `nix` command must be enabled.
- Nix must be configured (through your NixOS configuration or `/etc/nix/nix.conf` on other distributions)
  to include your username under `trusted-users` and `aarch64-linux` under `extra-platforms`.
  - You probably don't actually need to be a trusted user.
    I suspect this was a holdover from when I tried to add a cache in the flake's `nixConfig`, which I no longer do.
    I'm not going to remove the instruction to make yourself a trusted user because it may still be necessary,
    but I encourage you to try without it (given the security risks of a trusted user).
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
nix build 'github:nvmd/nixos-raspberrypi#installerImages.rpi5'
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
cd 'arch_nixos'

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

## License

I haven't decided on a license for these configurations yet
--- feel free to bother me about it if you'd like to reuse some code from here.

This project, does, however, include code from other projects:

- `pkgs/wslu/package.nix` contains MIT code adopted from Nixpkgs.
  See that file for more details.
- `pkgs/wslu/fallback-conf-nix-store.diff` contains a patch of code license `GPL-3.0-or-later`.
  See [wslu](https://github.com/wslutilities/wslu) for more details.
- `vm/qemu.nix` contains MIT code from [disko](https://github.com/nix-community/disko).
  See that file for more details.
