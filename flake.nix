{
  description = "Haskell Language server";

  inputs = {
    nixpkgs.url = "github:miuirussia/nixpkgs/nixpkgs-unstable";

    hackage.url = "github:miuirussia/hackage.nix";
    hackage.flake = false;

    stackage.url = "github:input-output-hk/stackage.nix";
    stackage.flake = false;

    haskell-nix.url = "github:input-output-hk/haskell.nix";
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
              mkHlsMaterialization = ghcVersion: (library { inherit pkgs system ghcVersion inputs; }).project.plan-nix.passthru.generateMaterialized;
              generateMaterializationBin = pkgs.writeShellScriptBin "generateMaterialization" ''
                # This runs the 'updateMaterialize' script in all platform combinations we care about.
                echo "Generating materialization for $1/hls-unstable-ghc865..."
                ${mkHlsMaterialization "ghc865"} $1/hls-unstable-ghc865
                echo "Generating materialization for $1/hls-unstable-ghc884..."
                ${mkHlsMaterialization "ghc884"} $1/hls-unstable-ghc884
                echo "Generating materialization for $1/hls-unstable-ghc8104..."
                ${mkHlsMaterialization "ghc8104"} $1/hls-unstable-ghc8104
                echo "Generating materialization for $1/hls-unstable-ghc8105..."
                ${mkHlsMaterialization "ghc8105"} $1/hls-unstable-ghc8105
                echo "Generating materialization for $1/hls-unstable-ghc8106..."
                ${mkHlsMaterialization "ghc8106"} $1/hls-unstable-ghc8106
                echo "Generating materialization for $1/hls-unstable-ghc8107..."
                ${mkHlsMaterialization "ghc8107"} $1/hls-unstable-ghc8107
                echo "Generating materialization for $1/hls-unstable-ghc901..."
                ${mkHlsMaterialization "ghc901"}  $1/hls-unstable-ghc901
              '';
            in {
              generateMaterialization = {
                type = "app";
                program = "${generateMaterializationBin}/bin/generateMaterialization";
              };
            }
        );
      };
}
