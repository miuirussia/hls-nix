#!/bin/bash
nix-build -A project.plan-nix.passthru.updateMaterialized --argstr ghcVersion ghc865 --arg checkMaterialization true 2>&1 | tee >( grep -om1 '/nix/store/.*-updateMaterialized' | bash )
nix-build -A project.plan-nix.passthru.updateMaterialized --argstr ghcVersion ghc884 --arg checkMaterialization true 2>&1 | tee >( grep -om1 '/nix/store/.*-updateMaterialized' | bash )
nix-build -A project.plan-nix.passthru.updateMaterialized --argstr ghcVersion ghc8105 --arg checkMaterialization true 2>&1 | tee >( grep -om1 '/nix/store/.*-updateMaterialized' | bash )
