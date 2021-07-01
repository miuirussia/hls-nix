#!/usr/bin/env bash
nix build -j8 -f default.nix project.project.plan-nix.passthru.updateMaterialized --no-link --argstr ghcVersion ghc865 --arg checkMaterialization true
nix build -j8 -f default.nix project.project.plan-nix.passthru.updateMaterialized --no-link --argstr ghcVersion ghc884 --arg checkMaterialization true
nix build -j8 -f default.nix project.project.plan-nix.passthru.updateMaterialized --no-link --argstr ghcVersion ghc8105 --arg checkMaterialization true
