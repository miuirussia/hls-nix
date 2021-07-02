#!/bin/bash
$(nix-build -A project.plan-nix.passthru.updateMaterialized --argstr ghcVersion ghc865)
$(nix-build -A project.plan-nix.passthru.updateMaterialized --argstr ghcVersion ghc884)
$(nix-build -A project.plan-nix.passthru.updateMaterialized --argstr ghcVersion ghc8105)
