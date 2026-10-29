{
  lib,
  stdenvNoCC,
  version,
}:
stdenvNoCC.mkDerivation {
  pname = "omde-qml";
  inherit version;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = ./qml;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -d "$out/share/omde"
    cp -a qml "$out/share/omde/qml"
    runHook postInstall
  '';

  meta = {
    description = "OMDE, a Quickshell setup for Mango";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
