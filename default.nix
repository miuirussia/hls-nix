{ sources ? import ./sources
, checkMaterialization ? false
, index-state ? "2021-05-22T00:00:00Z"
, index-sha256 ? "a154e09d3065552f413f83de105a230a3655f7f91058277a87b8d37ac1698587"
, ghcVersion ? "ghc865"
, hackageVersion ? "1.1.0.0"
}:

let
  ghcPatches = [];

  addGhcPatches = ghc: patches: ghc.overrideAttrs (
    prev: {
      patches = prev.patches ++ patches;

      src = prev.src.overrideAttrs (
        prevSrc: {
          patches = prevSrc.patches ++ patches;
        }
      );
    }
  );

  nixpkgs-unstable = import sources.nixpkgs-unstable {
    config = {};
    overlays = [];
  };

  nixpkgs-hn = let
    haskell-nix = import sources."haskell.nix" {};
    args = haskell-nix.nixpkgsArgs // {
      config = {};
      overlays = haskell-nix.overlays;
    };
  in
    import sources.nixpkgs-unstable args;

  haskell-nix = nixpkgs-hn.haskell-nix;

  planConfigFor = name: compiler-nix-name: modules:
    let
      isDarwin = builtins.elem builtins.currentSystem
        nixpkgs-unstable.lib.systems.doubles.darwin;
      platformName = if isDarwin then "macOS" else "linux";
      needsNewName = name == "hls-unstable";
      newName = if needsNewName then "${name}-${ghcVersion}" else name;
    in
      {
        inherit name modules index-state index-sha256 compiler-nix-name
          checkMaterialization
          ;
        configureArgs = "--disable-benchmarks";
        lookupSha256 = { location, ... }: null;
        materialized = ./materialized + "-${platformName}/${newName}";
      };

  allExes = pkg: pkg.components.exes;

  defaultModules = [ { enableSeparateDataOutput = true; } ];

  createProject = name:
    let
      planConfig = planConfigFor name ghcVersion defaultModules // {
        src = sources."${name}";
        cabalProjectLocal = ''
          reorder-goals: True
        '';
      };
    in
      (haskell-nix.cabalProject planConfig).haskell-language-server;

  fromHackage = name:
    let
      planConfig = planConfigFor name ghcVersion defaultModules // {
        version = hackageVersion;
      };
    in
      allExes (haskell-nix.hackage-package planConfig);

  fromSource = name:
    let
      hls = createProject name;
    in
      allExes hls;

  project = createProject "hls-unstable";
  build = fromSource "hls-unstable";
  hackage = fromHackage "haskell-language-server";

  trueVersion = {
    "ghc861" = "8.6.1";
    "ghc862" = "8.6.2";
    "ghc863" = "8.6.3";
    "ghc864" = "8.6.4";
    "ghc865" = "8.6.5";
    "ghc881" = "8.8.1";
    "ghc882" = "8.8.2";
    "ghc883" = "8.8.3";
    "ghc884" = "8.8.4";
    "ghc8101" = "8.10.1";
    "ghc8102" = "8.10.2";
    "ghc8103" = "8.10.3";
    "ghc8104" = "8.10.4";
    "ghc901" = "9.0.1";
  }."${ghcVersion}" or (throw "unsupported GHC Version: ${ghcVersion}");

  longDesc = suffix: ''
    Haskell Language Server (HLS) is the latest attempt make an IDE-like
    experience for Haskell that's compatible with different editors. HLS
    implements Microsoft's Language Server Protocol (LSP). With this
    approach, a background service is launched for a project that answers
    questions needed by an editor for common IDE features.
    Note that you need a version of HLS compiled specifically for the GHC
    compiler used by your project.  If you have multiple versions of GHC and
    HLS installed in your path, then a provided wrapper can be used to
    select the right one for the version of GHC used by your project.
    ${suffix}
  '';

  hls = build.haskell-language-server.overrideAttrs (
    old: {
      name = "haskell-language-server-${ghcVersion}";
      meta = old.meta // {
        description =
          "Haskell Language Server (HLS) for GHC ${trueVersion}";
        longDescription = longDesc ''
          This package provides the server executable compiled against
          ${trueVersion}.  It has the name original name of
          "haskell-language-server," which may clash with versions compiled for
          other compilers.
        '';
      };
    }
  );

  hls-renamed = nixpkgs-hn.stdenv.mkDerivation {
    name = "haskell-language-server-${ghcVersion}-renamed";
    version = hls.version;
    phases = [ "installPhase" ];
    nativeBuildInputs = [ nixpkgs-hn.makeWrapper ];
    installPhase = ''
      mkdir --parents $out/bin
      makeWrapper \
          "${hls}/bin/haskell-language-server" \
          "$out/bin/haskell-language-server-${trueVersion}"
    '';
    meta = hls.meta // {
      description =
        "Haskell Language Server (HLS) for GHC ${trueVersion}, renamed binary";
      longDescription = longDesc ''
        This package provides the server executable compiled against
        ${trueVersion}.  The binary has been renamed from
        "haskell-language-server" to "haskell-language-server-${ghcVersion}" to
        allow Nix to install multiple versions to the same profile for those
        that wish to use the HLS wrapper.
      '';
    };
  };

  hls-wrapper = build.haskell-language-server-wrapper.overrideAttrs (
    old: {
      name = "haskell-language-server-wrapper";
      meta = old.meta // {
        description = "Haskell Language Server (HLS) wrapper";
        longDescription = "This package provides the server wrapper.";
      };
    }
  );

  hls-wrapper-nix = nixpkgs-unstable.callPackage ./hls-wrapper-nix.nix {
    inherit hls-wrapper;
    nix-project-lib = (import sources.nix-project).nix-project-lib;
  };

  stack = nixpkgs-unstable.stack;

  stack-with-args = args: (
    nixpkgs-unstable.writeScriptBin "stack" ''
      #!${nixpkgs-unstable.runtimeShell}
      exec "${stack}/bin/stack" ${args} "$@"
    ''
  ) // {
    name = "stack-with-args";
    version = stack.version;
    meta.description = "Haskell Stack with args: ${args}";
    meta.longDescription = ''
      	This package provides a wrapper script around the Haskell Stack
              executable that tacks on `${args}` to every
              call.  This forces disablment of Nix across all platforms.
    '';
  };

  stack-nix = stack-with-args "--nix";
  stack-nonix = stack-with-args "--no-nix --system-ghc";

  stackNixPackages = stackYaml: pkgs:
    let
      lib = nixpkgs-unstable.lib;
      jsonFile = nixpkgs-unstable.runCommand "yaml2json" {} ''
        "${nixpkgs-unstable.yj}/bin/yj" < ${stackYaml} > "$out"
      '';
      json = builtins.fromJSON (builtins.readFile jsonFile);
      packageNames = json.nix.packages;
      err = path: throw "package not found: ${path}";
      select = path:
        lib.attrByPath (lib.splitString "." path) (err path) pkgs;
    in
      builtins.map select packageNames;

  cabal-install = nixpkgs-hn.cabal-install;
  ghc = nixpkgs-hn.haskell-nix.compiler."${ghcVersion}";
  implicit-hie = nixpkgs-hn.haskellPackages.implicit-hie;
in
{
  inherit
    cabal-install
    ghc
    hls
    hls-renamed
    hls-wrapper
    hls-wrapper-nix
    implicit-hie
    project
    stack
    stack-nix
    stack-nonix
    stackNixPackages
    hackage
    ;
}
