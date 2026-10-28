{
  lib,
  stdenv,
  cmake,
  qt6,
  core,
  version,
}:

stdenv.mkDerivation {
  pname = "omde-search";
  inherit version;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./CMakeLists.txt
      ./searchcore.h
      ./searchindex.cpp
      ./searchindex.hpp
      ./tests/tst_search.cpp
    ];
  };

  strictDeps = true;

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    core
  ];
  dontWrapQtApps = true;
  doCheck = true;

  cmakeFlags = [
    "-DOMDE_SEARCH_CORE_LIB=${core}/lib/libomde_search_core.a"
  ];

  checkPhase = ''
    runHook preCheck
    ctest --output-on-failure
    runHook postCheck
  '';

  meta = {
    description = "OMDE's fuzzy-search QML module";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
