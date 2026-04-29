# SPDX-License-Identifier: MIT
#
# This file and `./fallback-conf-nix-store.diff` are copied (and subsequently edited) from
# <https://github.com/NixOS/nixpkgs/tree/8e8f937c762050f893941ff9f39b1a1da1ad596f/pkgs/by-name/ws/wslu>.
# This is presumably copyright [Sandro Jäckel](https://github.com/SuperSandro2000),
# [Jamie Magee](https://github.com/JamieMagee), and other Nixpkgs contributors.

{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:

pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "wslu";
    version = "4.1.4";

    src = pkgs.fetchFromGitHub {
        owner = "wslutilities";
        repo = "wslu";
        tag = "v${finalAttrs.version}";
        hash = "sha256-ssiwYkQg2rOirC/ZZVq2bJm4Ggc364uRkoS2y365Eb0=";
    };

    nativeBuildInputs = [ pkgs.copyDesktopItems ];

    patches = [
        ./fallback-conf-nix-store.diff
    ];

    postPatch = ''
        substituteInPlace src/wslu-header \
          --subst-var out
        substituteInPlace src/etc/wslview.desktop \
          --replace-fail /usr/bin/wslview wslview
    '';

    makeFlags = [
        "DESTDIR=$(out)"
        "PREFIX="
    ];

    meta = {
        description = "Collection of utilities for Windows Subsystem for Linux";
        homepage = "https://github.com/wslutilities/wslu";
        changelog = "https://github.com/wslutilities/wslu/releases/tag/v${finalAttrs.version}";
        license = lib.licenses.gpl3Plus;
        # Previously maintained by [Jamie Magee](https://github.com/JamieMagee). I'm adopting this
        # package because it was (rightfully) removed from Nixpkgs but I still want `wslview` from
        # it. I've changed the maintainer to myself because Jamie Magee is no longer the point of
        # contact for this, but I don't mean to diminish his contributions here. Thank you!
        maintainers = [ (import ../maintainer-profile.nix) ];
        platforms = lib.platforms.linux;
    };
})
