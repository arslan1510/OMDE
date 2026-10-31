{
  flake.modules.homeManager.omde =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.omde;
    in
    {
      options.omde.services.removableMedia.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable udiskie for automatic mounting and removable-media notifications.";
      };

      config = lib.mkIf (cfg.enable && cfg.services.removableMedia.enable) {
        services.udiskie = {
          enable = lib.mkDefault true;
          package = lib.mkDefault (
            pkgs.udiskie.overridePythonAttrs (old: {
              disabledTests = (old.disabledTests or [ ]) ++ [ "test_is_valid" ];
            })
          );
          automount = lib.mkDefault true;
          notify = lib.mkDefault true;
          tray = lib.mkDefault "never";
        };
      };
    };
}
