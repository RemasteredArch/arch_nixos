{
    pkgs,
    useMold ? true,
    ...
}:

with pkgs;
[
    gnumake
    bear
    cpplint
    valgrind
    ninja
    expect
]
++ (if useMold then [ pkgs.mold ] else [ ])
