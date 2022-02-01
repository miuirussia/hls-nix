{ inputs
, pkgs
, system
, checkMaterialization ? false
, disableMaterialization ? false
, index-state ? "2022-01-25T00:00:00Z"
, index-sha256 ? "2a8c4ad2f1404f295a8933027bd172f1bc37dfc485e3472e158f782a5eccbb81"
, ghcVersion ? "ghc865"
, hackageVersion ? "1.2.0.0"
}:

let
  ghcPatches = [ ];

  sourcesRepositoryPackage = {
    "https://github.com/anka-213/HieDb"."a3f7521f6c5af1b977040cce09c8f7354f8984eb" = "0caf4q87bzvc3pzcpzbf91gdj7dvzdahzwxq0ql5dm52s5jmh0in";
    "https://github.com/anka-213/dependent-sum"."8cf4c7fbc3bfa2be475a17bb7c94a1e1e9a830b5" = "0x3lgd1ckd1666infydx9iijdvllw4kikb8k9fx90kczmc3m7p2s";
    "https://github.com/fendor/dependent-sum"."5de03c38b0de4945f4e9bce1b026110e69dc8118" = "1k7hfwaghc5i78rmqndzss40zhqq51zy2glczz0fbljvnfzz8pwm";
    "https://github.com/anka-213/lsp"."tag-ghc-9.0.1-without-pr-326" = "1xml8c9ccy1362riwnizwnxhxs915gw171p0vg2g4a7g35sc8vwm";
    "https://github.com/anka-213/th-extras"."57a97b4df128eb7b360e8ab9c5759392de8d1659" = "1yg0ikw63kmgp35kwhdi63sbk4f6g7bdj5app3z442xz0zb5mn22";
    "https://github.com/hsyl20/ghc-api-compat"."8fee87eac97a538dbe81ff1ab18cff10f2f9fa15" = "16bibb7f3s2sxdvdy2mq6w1nj1lc8zhms54lwmj17ijhvjys29vg";
    "https://github.com/jneira/hie-bios/"."9b1445ab5efcabfad54043fc9b8e50e9d8c5bbf3" = "0jfm7shlkb8vg2srprabvsnhmr77bvp59z771cl81i28gjvppjzi";
    "https://github.com/jwaldmann/blaze-textual.git"."d8ee6cf80e27f9619d621c936bb4bda4b99a183f" = "0k1xv17f4dk67d6ina3hrljvj009cink4qb9yac1cz5qzv6lhiqb";
    "https://github.com/mithrandi/czipwith.git"."b6245884ae83e00dd2b5261762549b37390179f8" = "0hapj3n8vnk2xx1vqn6v6g10kzn0cjgcfa8pnnng6kzi58dsir6s";
    "https://github.com/haskell/lsp.git"."ef59c28b41ed4c5775f0ab0c1e985839359cec96" = "1whcgw4hhn2aplrpy9w8q6rafwy7znnp0rczgr6py15fqyw2fwb5";
    "https://github.com/HeinrichApfelmus/operational"."16e19aaf34e286f3d27b3988c61040823ec66537" = "1831g81pnx8sn0w1j9srs37bmai2wv521dvmjqjdy21a8xqairiz";
  };

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

  haskell-nix = pkgs.haskell-nix;

  planConfigFor = name: compiler-nix-name: modules:
    let
      isDarwin = builtins.elem system pkgs.lib.systems.doubles.darwin;
      platformName = if isDarwin then "macOS" else "linux";
      needsNewName = name == "hls-unstable";
      newName = if needsNewName then "${name}-${ghcVersion}" else name;
    in
    {
      inherit name modules index-state index-sha256 compiler-nix-name
        checkMaterialization
        ;
      configureArgs = "--disable-benchmarks";
      lookupSha256 = { location, tag, ... }: sourcesRepositoryPackage."${location}"."${tag}" or null;
      materialized = if disableMaterialization then null else ./materialized + "-${platformName}/${newName}";
    };

  allExes = pkg: pkg.components.exes;

  defaultModules = [
    {
      enableSeparateDataOutput = true;
      packages.haskell-language-server.components.library.ghcOptions = [ "-dynamic" ];
      packages.haskell-language-server.components.exes.haskell-language-server-wrapper.ghcOptions = [ "-dynamic" ];
      packages.haskell-language-server.components.exes.haskell-language-server.ghcOptions = [ "-dynamic" ];
    }
  ];

  createProject = name:
    let
      src = inputs."${name}";
      cabalProject =
        if (builtins.pathExists "${src}/cabal-${ghcVersion}.project") then
          builtins.readFile "${src}/cabal-${ghcVersion}.project"
        else
          builtins.readFile "${src}/cabal.project";
      planConfig = planConfigFor name ghcVersion defaultModules // {
        inherit cabalProject src;
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

  hls-project = createProject "hls-unstable";
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
    "ghc8105" = "8.10.5";
    "ghc8106" = "8.10.6";
    "ghc8107" = "8.10.7";
    "ghc901" = "9.0.1";
    "ghc902" = "9.0.2";
    "ghc921" = "9.2.1";
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

  hls-renamed = pkgs.stdenv.mkDerivation {
    name = "haskell-language-server-${ghcVersion}-renamed";
    version = hls.version;
    phases = [ "installPhase" ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      mkdir --parents $out/bin
      makeWrapper \
          "${hls}/bin/haskell-language-server" \
          "$out/bin/haskell-language-server-${trueVersion}" \
          --prefix PATH : ${pkgs.lib.makeBinPath [(stack-with-args "--no-nix --system-ghc --no-install-ghc") pkgs.haskell-nix.compiler."${ghcVersion}" pkgs.cabal-install]}
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

  mkHlsWrapper = injectPackages: pkgs.stdenv.mkDerivation {
    name = "haskell-language-server-wrapper-with-pkgs";
    version = hls.version;
    phases = [ "installPhase" ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      mkdir --parents $out/bin
      makeWrapper \
        "${build.haskell-language-server-wrapper}/bin/haskell-language-server-wrapper" \
        "$out/bin/haskell-language-server-wrapper" \
        --prefix PATH : ${pkgs.lib.makeBinPath injectPackages}
    '';
  };

  hls-wrapper-nix = pkgs.callPackage ./hls-wrapper-nix.nix {
    inherit hls-wrapper;
    nix-project-lib = (import inputs.nix-project).nix-project-lib;
  };

  stack = pkgs.stack;

  stack-with-args = args: (
    pkgs.writeScriptBin "stack" ''
      #!${pkgs.runtimeShell}
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
      lib = pkgs.lib;
      jsonFile = pkgs.runCommand "yaml2json" { } ''
        "${pkgs.yj}/bin/yj" < ${stackYaml} > "$out"
      '';
      json = builtins.fromJSON (builtins.readFile jsonFile);
      packageNames = json.nix.packages;
      err = path: throw "package not found: ${path}";
      select = path:
        lib.attrByPath (lib.splitString "." path) (err path) pkgs;
    in
    builtins.map select packageNames;

  cabal-install = pkgs.cabal-install;
  ghc = pkgs.haskell-nix.compiler."${ghcVersion}";
  implicit-hie = pkgs.haskellPackages.implicit-hie;
  project = hls-project.project;
in
{

  inherit
    cabal-install
    ghc
    hls
    hls-renamed
    hls-wrapper
    hls-wrapper-nix
    mkHlsWrapper
    implicit-hie
    stack
    stack-nix
    stack-nonix
    stackNixPackages
    hackage
    project
    ;
}
