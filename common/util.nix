{ pkgs }:
{
    withFonts =
        package: fonts:
        let
            # TO-DO: is this reliable? Should I just take a separate binary name input?
            name = package.pname;
            fontConfig = pkgs.makeFontsConf { fontDirectories = fonts; };
            binPath = "${package}/bin/${name}";
        in
        pkgs.symlinkJoin {
            inherit name;
            paths = [
                (pkgs.writeShellScriptBin name ''
                    export FONTCONFIG_FILE="${fontConfig}"
                    exec '${binPath}' "$@"
                '')
                package
            ];
        };
}
