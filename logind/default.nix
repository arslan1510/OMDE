{
  lib,
  stdenv,
  cmake,
  qt6,
  version,
}:

stdenv.mkDerivation {
  pname = "omde-logind";
  inherit version;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./CMakeLists.txt
      ./logind.cpp
      ./logind.hpp
      ./tests/tst_logind.cpp
    ];
  };

  strictDeps = true;

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
  ];
  dontWrapQtApps = true;
  doCheck = true;

  checkPhase = ''
    runHook preCheck
    ctest --output-on-failure
    runHook postCheck
  '';

  meta = {
    description = "OMDE's logind QML module";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
