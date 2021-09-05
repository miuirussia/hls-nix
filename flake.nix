{
  description = "Haskell Language server";

  inputs = {
    nixpkgs.url = "github:miuirussia/nixpkgs/nixpkgs-unstable";

    hackage.url = "github:miuirussia/hackage.nix";
    hackage.flake = false;

    stackage.url = "github:input-output-hk/stackage.nix";
    stackage.flake = false;

    haskell-nix.url = "github:miuirussia/haskell.nix";
    haskell-nix.inputs.nixpkgs.follows = "nixpkgs";
    haskell-nix.inputs.hackage.follows = "hackage";
    haskell-nix.inputs.stackage.follows = "stackage";

    nix-project.url = "github:shajra/nix-project";
    nix-project.flake = false;

    hls-stable.url = "github:haskell/haskell-language-server/0.6.0";
    hls-stable.flake = false;

    hls-unstable.url = "github:haskell/haskell-language-server";
    hls-unstable.flake = false;

    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
  };

  outputs = inputs @ { nixpkgs, haskell-nix, ... }:
    let
      supportedSystem = [ "x86_64-linux" "x86_64-darwin" ];

      supportedGhcVersions = [
        "ghc861"
        "ghc862"
        "ghc863"
        "ghc864"
        "ghc865"
        "ghc881"
        "ghc882"
        "ghc883"
        "ghc884"
        "ghc8101"
        "ghc8102"
        "ghc8103"
        "ghc8104"
        "ghc8105"
        "ghc8106"
        "ghc8107"
        "ghc901"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystem (system: f system);

      forAllGhcs = f: nixpkgs.lib.genAttrs supportedGhcVersions (ghc: f ghc);

      library = import ./lib.nix;
    in
      {
        build = forAllSystems (
          system:
            forAllGhcs (
              ghcVersion: let
                pkgs = import nixpkgs {
                  config.allowUnfree = true;
                  overlays = [ haskell-nix.overlay ];
                  inherit system;
                };
              in
                library { inherit pkgs system ghcVersion inputs; }
            )
        );

        apps = forAllSystems (
          system:
            let
              pkgs = import nixpkgs {
                config.allowUnfree = true;
                overlays = [ haskell-nix.overlay ];
                inherit system;
              };
              mkHlsMaterialization = ghcVersion: (library { inherit pkgs system ghcVersion inputs; }).project.plan-nix.passthru.updateMaterialized;
              updateMaterializedBin = pkgs.writeShellScriptBin "updateMaterialized" ''
                # This runs the 'updateMaterialize' script in all platform combinations we care about.
                ${mkHlsMaterialization "ghc865"}
                ${mkHlsMaterialization "ghc884"}
                ${mkHlsMaterialization "ghc8104"}
                ${mkHlsMaterialization "ghc8105"}
                ${mkHlsMaterialization "ghc8106"}
                ${mkHlsMaterialization "ghc8107"}
                ${mkHlsMaterialization "ghc901"}
              '';
            in {
              updateMaterialized = {
                type = "app";
                program = "${updateMaterializedBin}/bin/updateMaterialized";
              };
            }
        );
      };
}
