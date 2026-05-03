# SPDX-License-Identifier: MIT
#
# Copyright © 2025-2026 Nix community projects
#
# Taken from <https://github.com/nix-community/disko/blob/63b4e7e/docs/disko-images.md>.

with import <nixpkgs> { };

writeShellApplication {
    name = "test-image";
    runtimeInputs = [ qemu ];
    text = ''
        if [ -z "$1" ]; then
            echo "Usage: $0 <path-to-boot-image>"
            exit 1
        fi

        tmpFile=$(mktemp /tmp/test-image.XXXXXX)
        trap 'rm -f $tmpFile' EXIT
        cp "$1" "$tmpFile"

        qemu-system-x86_64 \
            -enable-kvm \
            -m 4G \
            -cpu max \
            -smp 4 \
            -netdev user,id=net0,hostfwd=tcp::2222-:22 \
            -device virtio-net-pci,netdev=net0 \
            -drive if=pflash,format=raw,readonly=on,file=${OVMF.firmware} \
            -drive if=pflash,format=raw,readonly=on,file=${OVMF.variables} \
            -drive "if=virtio,format=raw,file=$tmpFile"
    '';
}
