#!/bin/bash
$(nix-build --no-out-link -A project.plan-nix.passthru.updateMaterialized --argstr ghcVersion ghc865)
$(nix-build --no-out-link -A project.plan-nix.passthru.updateMaterialized --argstr ghcVersion ghc884)
$(nix-build --no-out-link -A project.plan-nix.passthru.updateMaterialized --argstr ghcVersion ghc8105)
