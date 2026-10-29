{ inputs, ... }:
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
      system = pkgs.stdenv.hostPlatform.system;
      ipc = call: "spawn,qs ipc -c omde call ${call}";

      execOnce = lib.optionalString (!cfg.systemd.enable) ''
        exec_once = ["${lib.getExe' config.omde.cli.package "omde"} shell --daemon"]
      '';

      omdeToml = pkgs.writeText "omde.toml" ''
        [global]
        ${execOnce}

        [bind.default]
        "SUPER+space" = "${ipc "launcher toggle"}"
        "SUPER+Escape" = "${ipc "session lock"}"
        "SUPER+w" = "${ipc "launcher windows"}"
        "SUPER+v" = "${ipc "launcher clipboard"}"
        "Print" = "${ipc "screenshot take region"}"
        "SHIFT+Print" = "${ipc "screenshot take screen"}"
        "SUPER+Print" = "${ipc "screenshot take annotate"}"

        [bind.default.lock]
        "XF86AudioPlay" = "${ipc "media playPause"}"
        "XF86AudioNext" = "${ipc "media next"}"
        "XF86AudioPrev" = "${ipc "media previous"}"

        [[rule.layer_rule]]
        layer_name = "^omde-(launcher|osd|notification|polkit|wifi|shield)$"
        no_animation = 1

        [[rule.window_rule]]
        app_id = "satty"
        is_floating = 1
        no_animation = 1
      '';
    in
    {
      options.omde.mango = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to write OMDE's part of Mango's config.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = config.osConfig.programs.mango.package or inputs.mangowm.packages.${system}.default;
          defaultText = lib.literalMD "Mango from the NixOS module, else the `mangowm` input";
          description = "Mango used to validate mango/omde.toml.";
        };
      };

      config = lib.mkIf (cfg.enable && cfg.mango.enable) {
        assertions = [
          {
            assertion = config.wayland.windowManager.mango.enable or false;
            message = "omde.mango writes mango/omde.toml, which needs Mango's Home Manager module.";
          }
        ];

        xdg.configFile."mango/config.toml".source = ./config.toml;

        xdg.configFile."mango/omde.toml".source = pkgs.runCommand "mango-omde.toml" { } ''
          cp ${omdeToml} $out
          ${lib.getExe' cfg.mango.package "mango"} -c $out -p
        '';
      };
    };
}
