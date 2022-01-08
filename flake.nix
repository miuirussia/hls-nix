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

  outputs = inputs @ { nixpkgs, haskell-nix, flake-utils, ... }:
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
        "ghc921"
      ];

      materializableGhcVersions = [
        "ghc884"
        "ghc8107"
        "ghc901"
        "ghc921"
      ];

      forAllGhcs = f: nixpkgs.lib.genAttrs supportedGhcVersions (ghc: f ghc);

      library = import ./lib.nix;
    in
      flake-utils.lib.eachSystem supportedSystem (
        system: let
          pkgs = import nixpkgs {
            config.allowUnfree = true;
            overlays = [ haskell-nix.overlay ];
            inherit system;
          };
        in
          {
            lib = forAllGhcs (
              ghcVersion: library { inherit pkgs system ghcVersion inputs; }
            );

            materialization = forAllGhcs (
              ghcVersion:
                (library { inherit pkgs system ghcVersion inputs; disableMaterialization = true; }).project.plan-nix
            );

            apps = let
              pkgs = import nixpkgs {
                config.allowUnfree = true;
                overlays = [ haskell-nix.overlay ];
                inherit system;
              };
              mkHlsMaterialization = ghcVersion: (library { inherit pkgs system ghcVersion inputs; disableMaterialization = true; }).project.plan-nix;
              generateMaterializationBin = pkgs.writeShellScriptBin "generateMaterialization" (
                ''
                  # This runs the 'updateMaterialize' script in all platform combinations we care about.
                  mkdir -p "$1"
                '' + (
                  builtins.concatStringsSep "\n" (
                    builtins.map (
                      ghc: ''
                        echo "Generating materialization for $1/hls-unstable-${ghc}..."
                        rm -rf "$1/hls-unstable-${ghc}"
                        cp -r ${mkHlsMaterialization ghc} "$1/hls-unstable-${ghc}"
                        chmod -R +w "$1/hls-unstable-${ghc}"
                      ''
                    ) materializableGhcVersions
                  )
                )
              );
            in
              {
                generateMaterialization = {
                  type = "app";
                  program = "${generateMaterializationBin}/bin/generateMaterialization";
                };
              };
          }
      );
}
