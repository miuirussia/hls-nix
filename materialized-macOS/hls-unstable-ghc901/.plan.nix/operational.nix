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
    flags = { buildexamples = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "operational"; version = "0.2.3.5"; };
      license = "BSD-3-Clause";
      copyright = "(c) Heinrich Apfelmus 2010-2013";
      maintainer = "Heinrich Apfelmus <apfelmus quantentunnel de>";
      author = "Heinrich Apfelmus";
      homepage = "http://wiki.haskell.org/Operational";
      url = "";
      synopsis = "Implementation of difficult monads made easy\nwith operational semantics.";
      description = "This library makes it easy to implement monads with tricky control flow.\n\nThis is useful for: writing web applications in a sequential style, programming games with a uniform interface for human and AI players and easy replay capababilities, implementing fast parser monads, designing monadic DSLs, etc.\n\nSee the project homepage <http://wiki.haskell.org/Operational> for a more detailed introduction and features.\n\nRelated packages:\n\n* MonadPrompt — <http://hackage.haskell.org/package/MonadPrompt>\n\n* free — <http://hackage.haskell.org/package/free>\n\n* free-operational — <http://hackage.haskell.org/package/free-operational>";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [ "LICENSE" ];
      dataDir = ".";
      dataFiles = [];
      extraSrcFiles = [
        "CHANGELOG.md"
        "doc/*.md"
        "doc/examples/*.hs"
        "doc/examples/*.lhs"
        "doc/examples/*.md"
        ];
      extraTmpFiles = [];
      extraDocFiles = [];
      };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          ];
        buildable = true;
        modules = [ "Control/Monad/Operational" ];
        hsSourceDirs = [ "src" ];
        };
      exes = {
        "operational-TicTacToe" = {
          depends = [
            (hsPkgs."operational" or (errorHandler.buildDepError "operational"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            ];
          buildable = if !flags.buildexamples then false else true;
          hsSourceDirs = [ "doc/examples" ];
          mainPath = [
            "TicTacToe.hs"
            ] ++ (pkgs.lib).optional (!flags.buildexamples) "";
          };
        };
      };
    } // {
    src = (pkgs.lib).mkDefault (pkgs.fetchgit {
      url = "4";
      rev = "minimal";
      sha256 = "";
      }) // {
      url = "4";
      rev = "minimal";
      sha256 = "";
      };
    }