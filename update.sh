#!/usr/bin/env bash

set -euo pipefail

nix build -j8 -f default.nix hls-renamed --no-link --argstr ghcVersion ghc865 --arg checkMaterialization true 2>&1 | grep -om1 '/nix/store/.*-updateMaterialized' | bash
nix build -j8 -f default.nix hls-renamed --no-link --argstr ghcVersion ghc884 --arg checkMaterialization true 2>&1 | grep -om1 '/nix/store/.*-updateMaterialized' | bash
nix build -j8 -f default.nix hls-renamed --no-link --argstr ghcVersion ghc8104 --arg checkMaterialization true 2>&1 | grep -om1 '/nix/store/.*-updateMaterialized' | bash
nix build -j8 -f default.nix hls-renamed --no-link --argstr ghcVersion ghc8105 --arg checkMaterialization true 2>&1 | grep -om1 '/nix/store/.*-updateMaterialized' | bash
nix build -j8 -f default.nix hls-renamed --no-link --argstr ghcVersion ghc901 --arg checkMaterialization true 2>&1 | grep -om1 '/nix/store/.*-updateMaterialized' | bash
