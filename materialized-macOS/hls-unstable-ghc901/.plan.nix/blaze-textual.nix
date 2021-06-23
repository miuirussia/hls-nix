{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  {
    flags = { developer = false; native = true; integer-simple = false; };
    package = {
      specVersion = "1.8";
      identifier = { name = "blaze-textual"; version = "0.2.1.0"; };
      license = "BSD-3-Clause";
      copyright = "Copyright 2011 MailRank, Inc.";
      maintainer = "Bryan O'Sullivan <bos@serpentine.com>";
      author = "Bryan O'Sullivan <bos@serpentine.com>";
      homepage = "http://github.com/bos/blaze-textual";
      url = "";
      synopsis = "Fast rendering of common datatypes";
      description = "A library for efficiently rendering Haskell datatypes to\nbytestrings.\n\n/Note/: if you use GHCi or Template Haskell, please see the\n@README@ file for important details about building this package,\nand other packages that depend on it:\n<https://github.com/bos/blaze-textual#readme>";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [ "LICENSE" ];
      dataDir = ".";
      dataFiles = [];
      extraSrcFiles = [ "README.markdown" "changelog.md" "tests/*.hs" ];
      extraTmpFiles = [];
      extraDocFiles = [];
      };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."old-locale" or (errorHandler.buildDepError "old-locale"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ] ++ (pkgs.lib).optional (!flags.native) (hsPkgs."double-conversion" or (errorHandler.buildDepError "double-conversion"))) ++ (if flags.integer-simple
          then [
            (hsPkgs."integer-simple" or (errorHandler.buildDepError "integer-simple"))
            ]
          else [
            (hsPkgs."integer-gmp" or (errorHandler.buildDepError "integer-gmp"))
            ]);
        buildable = true;
        modules = [
          "Blaze/Text"
          "Blaze/Text/Double"
          "Blaze/Text/Int"
          ] ++ (pkgs.lib).optional (flags.native) "Blaze/Text/Double/Native";
        };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."blaze-builder" or (errorHandler.buildDepError "blaze-builder"))
            (hsPkgs."blaze-textual" or (errorHandler.buildDepError "blaze-textual"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."double-conversion" or (errorHandler.buildDepError "double-conversion"))
            (hsPkgs."test-framework" or (errorHandler.buildDepError "test-framework"))
            (hsPkgs."test-framework-quickcheck2" or (errorHandler.buildDepError "test-framework-quickcheck2"))
            ];
          buildable = true;
          hsSourceDirs = [ "tests" ];
          mainPath = [ "QC.hs" ];
          };
        };
      };
    } // rec { src = (pkgs.lib).mkDefault .././.source-repository-packages/0; }