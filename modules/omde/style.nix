{
  flake.modules.homeManager.omde =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      cfg = config.omde;
      theme = cfg.theme;
    in
    {
      config = lib.mkIf cfg.enable (
        {
          home.packages = [ pkgs.adwaita-icon-theme ];

          programs.fuzzel = {
            enable = lib.mkDefault true;
            settings.border = {
              width = lib.mkDefault theme.borderWidth;
              radius = lib.mkDefault theme.radius;
            };
          };
        }
        // lib.optionalAttrs (options ? stylix) {
          stylix.targets.rofi.enable = lib.mkDefault false;
          stylix.targets.qt.enable = lib.mkDefault true;

          stylix.icons = lib.mkOverride 900 {
            enable = true;
            dark = "Papirus-Dark";
            light = "Papirus";
            package = pkgs.papirus-icon-theme;
          };

          xdg.configFile."kdeglobals".text = ''
            [Icons]
            Theme=${config.stylix.icons.${config.stylix.polarity}}
          '';

          gtk.colorScheme = lib.mkDefault config.stylix.polarity;

          stylix.targets.gtk.extraCss = ''
            * {
              border-radius: ${toString theme.radius}px;
            }

            window,
            popover.background,
            popover > contents,
            menu,
            tooltip,
            .csd,
            .csd decoration {
              box-shadow: none;
            }

            popover.background {
              border-width: ${toString theme.borderWidth}px;
              border-color: ${theme.hex.muted};
            }

            popover > contents,
            menu,
            tooltip {
              border: ${toString theme.borderWidth}px solid ${theme.hex.muted};
            }
          '';
        }
      );
    };
}
