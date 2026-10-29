{
  flake.modules.homeManager.omde =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.omde;

      motionType = lib.types.submodule {
        options = {
          duration = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = "Milliseconds.";
          };
          curve = lib.mkOption {
            type = lib.types.listOf lib.types.number;
            description = "Cubic bezier control points, x1 y1 x2 y2.";
          };
        };
      };

      windowType = lib.types.submodule {
        options = {
          openZoom = lib.mkOption {
            type = lib.types.float;
            description = "Mango window open zoom ratio.";
          };
          closeZoom = lib.mkOption {
            type = lib.types.float;
            description = "Mango window close zoom ratio.";
          };
          dimAlpha = lib.mkOption {
            type = lib.types.str;
            description = "Alpha byte appended to the background color for unfocused window dimming.";
          };
        };
      };

      # Stylix is the palette source when available.
      stylixColors =
        if (config.lib ? stylix) && (config.lib.stylix ? colors) then
          config.lib.stylix.colors
        else
          {
            base00 = "1c2023";
            base01 = "393f45";
            base02 = "565e65";
            base03 = "747c84";
            base04 = "adb3ba";
            base05 = "c7ccd1";
            base06 = "dfe2e5";
            base07 = "f3f4f5";
            base08 = "c7ae95";
            base09 = "c7c795";
            base0A = "aec795";
            base0B = "95c7ae";
            base0C = "95aec7";
            base0D = "ae95c7";
            base0E = "c795ae";
            base0F = "c79595";
          };
    in
    {
      options.omde.theme = {
        # Transitional override. empty means "derive from omde.theme.hex".
        colors = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Explicit color overrides as CSS colors; empty derives from omde.theme.hex.";
        };

        roles = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            background = "base00";
            foreground = "base05";
            muted = "base03";
            accent = "base05";
            warning = "base0A";
            critical = "base08";
          };
          description = "Semantic roles mapped to base16 palette slots.";
        };

        hex = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          default = lib.mapAttrs (_: slot: "#${stylixColors.${slot}}") cfg.theme.roles;
          description = "Semantic roles as CSS hex colors, derived from Stylix.";
        };

        raw = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          default = lib.mapAttrs (_: slot: stylixColors.${slot}) cfg.theme.roles;
          description = "Semantic roles as raw base16 hex strings (no #), derived from Stylix.";
        };

        palette = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          default = lib.filterAttrs (name: _: builtins.match "base0[0-9A-F]" name != null) stylixColors;
          description = "Full base16 palette (base00..base0F) used by Mango and app theme generation.";
        };

        resolvedColors = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          default = if cfg.theme.colors == { } then cfg.theme.hex else cfg.theme.colors;
          description = "The colors written to palette.json: explicit overrides or the derived hex roles.";
        };

        font = {
          family = lib.mkOption {
            type = lib.types.str;
            default = config.stylix.fonts.monospace.name or "CaskaydiaCove Nerd Font";
            description = "Monospace family; icons are Nerd Font glyphs.";
          };
          size = lib.mkOption {
            type = lib.types.numbers.nonnegative;
            default = config.stylix.fonts.sizes.desktop or 12.5;
            description = "Points; every length in the shell derives from this.";
          };
        };

        borderWidth = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 1;
          description = "Pixels, snapped to whole device pixels per output.";
        };

        radius = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 0;
          description = "Corner radius in pixels, shared with Mango and apps.";
        };

        motion = lib.mkOption {
          type = lib.types.attrsOf motionType;
          default = {
            enter = {
              duration = 250;
              curve = [
                0.05
                0.7
                0.1
                1.0
              ];
            };
            exit = {
              duration = 150;
              curve = [
                0.3
                0.0
                0.8
                0.15
              ];
            };
            move = {
              duration = 300;
              curve = [
                0.05
                0.7
                0.1
                1.0
              ];
            };
            effect = {
              duration = 150;
              curve = [
                0.34
                0.8
                0.34
                1.0
              ];
            };
          };
          description = "Named motion roles, shared with Mango.";
        };

        windows = lib.mkOption {
          type = windowType;
          default = {
            openZoom = 0.92;
            closeZoom = 0.96;
            dimAlpha = "33";
          };
          description = "Mango window open/close zoom and unfocused dim alpha.";
        };
      };
    };
}
