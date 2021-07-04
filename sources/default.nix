let

  srcs = import ./sources.nix;

  lib = (import srcs.nixpkgs { config = {}; overlays = []; }).lib;

  isDarwin = builtins.elem builtins.currentSystem lib.systems.doubles.darwin;

  sources = builtins.fromJSON
    (builtins.readFile ./sources.json);

  pkgs = import srcs.nixpkgs {
    config = {};
    overlays = [];
  };

  fromGitHub = source: name:
    with source; pkgs.fetchFromGitHub {
      inherit owner repo rev name sha256;
      fetchSubmodules = true;
    };

  mkPatchedSource = { name, src, patches }:
    pkgs.stdenv.mkDerivation {
      name = "${name}-${src.rev}-patched";

      inherit patches src;

      installPhase = ''
        mkdir -p $out
        cp -r . $out
      '';

      doCheck = false;
      dontFixup = true;
    };

  nixpkgs-stable =
    if isDarwin
    then srcs // {
      nixpkgs-stable = mkPatchedSource {
        name = "nixpkgs-stable-darwin";
        src = srcs.nixpkgs-stable-darwin;
        patches = [ ./nixpkgs.patch ];
      };
    }
    else srcs // {
      nixpkgs-stable = mkPatchedSource {
        name = "nixpkgs-stable-linux";
        src = srcs.nixpkgs-stable-linux;
        patches = [ ./nixpkgs.patch ];
      };
    };

  overrides = {
    "haskell.nix" = mkPatchedSource {
      name = "haskell.nix";
      src = srcs."haskell.nix";
      patches = [ ./hnix_sphinx_fix.patch ];
    };
  };
in
nixpkgs-stable // overrides
