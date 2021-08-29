{ pkgs ? import <nixpkgs> {} }:

let

  mkHlsMaterialization = ghcVersion: let
    hls = import ./default.nix { inherit ghcVersion; };
  in hls.project.plan-nix.passthru.updateMaterialized;
  updateMaterialized = pkgs.writeShellScriptBin "updateMaterialized" ''
    # This runs the 'updateMaterialize' script in all platform combinations we care about.
    ${mkHlsMaterialization "ghc865"}
    ${mkHlsMaterialization "ghc884"}
    ${mkHlsMaterialization "ghc8104"}
    ${mkHlsMaterialization "ghc8105"}
    ${mkHlsMaterialization "ghc8106"}
    ${mkHlsMaterialization "ghc8107"}
    ${mkHlsMaterialization "ghc901"}
  '';
in
pkgs.mkShell {
  nativeBuildInputs = [ updateMaterialized ];
}
