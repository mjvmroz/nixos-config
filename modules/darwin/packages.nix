{ pkgs }:

with pkgs;
let
  shared-packages = import ../shared/packages.nix { inherit pkgs; };

  ucm-desktop = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "ucm-desktop";
    version = "1.4.0";

    src = pkgs.fetchurl {
      url = "https://github.com/unisonweb/ucm-desktop/releases/download/v${version}/UCM.Desktop-${version}-arm64.dmg";
      sha256 = "1e6e5f22545285842ee05f65feb201ffa34adac716ff5a13687f678df1c2ef9a";
    };

    nativeBuildInputs = [ pkgs.undmg ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/Applications
      cp -r "UCM Desktop.app" $out/Applications/
    '';

    meta = with pkgs.lib; {
      description = "Desktop companion app for the Unison Code Manager";
      homepage = "https://github.com/unisonweb/ucm-desktop";
      license = licenses.mit;
      platforms = platforms.darwin;
      maintainers = [ ];
    };
  };
in
shared-packages ++ [ ucm-desktop ]
