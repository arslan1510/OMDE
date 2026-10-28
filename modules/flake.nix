{ self, inputs, ... }:
let
  version = "0.1.0";
in
{
  imports = [
    ./omde
    ./nixos.nix
  ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, inputs', ... }:
    let
      logind = pkgs.callPackage ../logind { inherit version; };
      search-core = pkgs.callPackage ../search/core { inherit version; };
      search = pkgs.callPackage ../search { inherit version; core = search-core; };
      omde = pkgs.callPackage ../package.nix { inherit version; };
    in
    {
      formatter = pkgs.nixfmt-tree;

      packages = {
        inherit omde;
        omde-logind = logind;
        omde-search = search;
        omde-search-core = search-core;

        default = inputs'.quickshell.packages.default.withModules [ logind search ];
      };

      checks = {
        omde-logind = logind;
        omde-search = search;
        omde-search-core = search-core;

        hm-eval =
          let
            hm = inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                self.homeManagerModules.default
                {
                  home.username = "omde";
                  home.homeDirectory = "/home/omde";
                  home.stateVersion = "26.05";
                  omde.enable = true;
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
