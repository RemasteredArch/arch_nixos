set -euo pipefail

root_dir="$(dirname "$0")"
cd "$root_dir"

function print_help() {
    cat << EOF
Build tools for \`arch_nixos\`.

Usage:
    $0 vm [--no-build]
            Builds and runs a virtual machine of the \`laptop\`
            host. This is very slow and takes at least 64 GiB
            of storage (probably ~128 GiB)!

    $0 switch <host>
            Builds the specified flake output and reconfigures
            the current NixOS install to its result.

    $0 help
            Prints this message.

Options:
    --no-build      Skip building the virual machine, just run
                    the existing \`boot.raw\` image.
EOF
}

function build_vm() {
    set -x

    local vm_dir="$root_dir/vm"
    [ -d "$vm_dir" ] || mkdir "$vm_dir"
    cd "$vm_dir"

    # This takes around fifteen minutes on my laptop.
    if [ "${1:-}" != '--no-build' ]; then
        nix build ../#nixosConfigurations.laptop.config.system.build.diskoImagesScript
        sudo ./result
    fi

    # This takes a couple minutes on my laptop.
    "$(nix-build ./qemu.nix)/bin/test-image" ./boot.raw
}

function switch() {
    local host="$1"

    sudo nixos-rebuild switch --flake ".#$host"
}

command="${1:-}"
[ $# -gt 0 ] && shift
case "$command" in
    vm)
        build_vm "$@"
        ;;
    switch)
        [ $# -gt 0 ] || {
            echo 'Missing host!'
            echo
            print_help
            exit 1
        }
        switch "$@"
        ;;
    help)
        print_help
        exit 0
        ;;
    *)
        print_help
        exit 1
        ;;
esac
