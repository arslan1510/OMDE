{
  config,
  self,
  inputs,
  ...
}:
let
  version = "0.1.1";
in
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];

  flake.homeManagerModules.default =
    { ... }:
    {
      imports = [ config.flake.modules.homeManager.omde ];
    };

  flake.nixosModules.default =
    { ... }:
    {
      imports = [ config.flake.modules.nixos.omde ];
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, inputs', ... }:
    let
      logind = pkgs.callPackage ../logind { inherit version; };
      search-core = pkgs.callPackage ../search/core { inherit version; };
      search = pkgs.callPackage ../search {
        inherit version;
        core = search-core;
      };
      omde-qml = pkgs.callPackage ../package.nix { inherit version; };
      quickshell = inputs'.quickshell.packages.default.withModules [
        logind
        search
      ];
      omde-cli = pkgs.callPackage ../cli {
        inherit version;
        mango = inputs'.mangowm.packages.default;
        quickshell = quickshell;
      };
      omde-session =
        (pkgs.writeTextDir "share/wayland-sessions/omde.desktop" ''
          [Desktop Entry]
          Name=OMDE
          Comment=OMDE, a Quickshell + Mango desktop environment
          Exec=${pkgs.lib.getExe omde-cli} session
          Type=Application
          DesktopNames=OMDE;mango;wlroots
        '')
        // {
          providedSessions = [ "omde" ];
        };
    in
    {
      formatter = pkgs.nixfmt-tree;

      packages = {
        omde = omde-cli;
        omde-cli = omde-cli;
        omde-qml = omde-qml;
        omde-session = omde-session;
        omde-logind = logind;
        omde-search = search;
        omde-search-core = search-core;

        default = quickshell;
      };

      checks = {
        inherit omde-cli;
        omde-qml = omde-qml;
        omde-session = omde-session;
        omde-logind = logind;
        omde-search = search;
        omde-search-core = search-core;

        hm-eval =
          let
            hm = inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                self.homeManagerModules.default
                inputs.mangowm.hmModules.mango
                {
                  home.username = "omde";
                  home.homeDirectory = "/home/omde";
                  home.stateVersion = "26.05";
                  omde.enable = true;
                  wayland.windowManager.mango.enable = true;
                }
              ];
            };
          in
          pkgs.writeText "omde-hm-eval.json" (
            builtins.toJSON {
              palette = {
                inherit (hm.config.xdg.configFile."omde/palette.json") text target;
              };
              config = {
                inherit (hm.config.xdg.configFile."omde/config.json") text target;
              };
            }
          );
      };
    };
}
