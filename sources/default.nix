let

    srcs = import ./sources.nix;

    lib = (import srcs.nixpkgs { config = {}; overlays = []; }).lib;

    isDarwin = builtins.elem builtins.currentSystem lib.systems.doubles.darwin;

    sources = builtins.fromJSON
        (builtins.readFile ./sources.json);

    pkgs = import (import ./sources.nix).nixpkgs {
        config = {};
        overlays = [];
    };

    fromGitHub = source: name:
        with source; pkgs.fetchFromGitHub {
            inherit owner repo rev name sha256;
            fetchSubmodules = true;
        };

    mkPatchedNixpkgs = { src }:
      pkgs.stdenv.mkDerivation {
        name = "nixpkgs-${src.branch}-patched";
        patches = [
          ./nixpkgs.patch
        ];

        inherit src;

        installPhase = ''
          mkdir -p $out
          cp -r . $out
        '';

        doCheck = false;
        dontFixup = true;
      };

    nixpkgs =
        if isDarwin
        then srcs // {
          nixpkgs-stable = mkPatchedNixpkgs {
            src = srcs.nixpkgs-stable-darwin;
          };
        }
        else srcs // {
          nixpkgs-stable = mkPatchedNixpkgs {
            src = srcs.nixpkgs-stable-linux;
          };
        };

    overrides = {
        hls-stable =
            let s = sources.hls-stable;
            in fromGitHub s "haskell-hls-${s.branch}-src";
        hls-unstable =
            let s = sources.hls-unstable;
            in fromGitHub s "haskell-hls-${s.branch}-src";

        vimspector =
            let
              src = srcs.vimspector;
            in pkgs.stdenv.mkDerivation {
              name = "vimspector-src";

              inherit src;

              patches = [
                ./vimspector.patch
              ];

              installPhase = ''
                mkdir -p $out
                cp -r . $out
              '';

              doCheck = false;
              dontFixup = true;
            };
    };

in nixpkgs // overrides
