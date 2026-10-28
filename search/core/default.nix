{
  lib,
  rustPlatform,
  version,
}:

rustPlatform.buildRustPackage {
  pname = "omde-search-core";
  inherit version;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src/lib.rs
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;
  doCheck = true;

  installPhase = ''
    runHook preInstall
    lib=$(find target -name libomde_search_core.a -path '*/release/*' -print -quit)
    test -n "$lib"
    install -Dm644 "$lib" "$out/lib/libomde_search_core.a"
    runHook postInstall
  '';

  meta = {
    description = "OMDE's Rust fuzzy-search core";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
