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
        "SUPER+b" = "${ipc "bar toggle"}"
        "Print" = "${ipc "screenshot take region"}"
        "SHIFT+Print" = "${ipc "screenshot take screen"}"
        "SUPER+Print" = "${ipc "screenshot take annotate"}"

        [bind.default.lock]
        "XF86AudioPlay" = "${ipc "media playPause"}"
        "XF86AudioNext" = "${ipc "media next"}"
        "XF86AudioPrev" = "${ipc "media previous"}"

        [[rule.layer_rule]]
        layer_name = "^omde(-(launcher|osd|notification|polkit|wifi|shield))?$"
        no_animation = 1

        [[rule.window_rule]]
        app_id = "satty"
        is_floating = 1
        no_animation = 1
      '';
    in
    {
      imports = [ inputs.mangowm.hmModules.mango ];

      options.omde.mango = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Mango and OMDE's compositor configuration.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.mangowm.packages.${system}.default;
          defaultText = lib.literalMD "Mango from the `mangowm` input, shared with NixOS when integrated";
          description = "Mango used by the compositor, CLI, and generated configuration checks.";
        };
      };

      config = lib.mkIf (cfg.enable && cfg.mango.enable) {
        assertions = [
          {
            assertion = config.wayland.windowManager.mango.enable or false;
            message = "omde.mango requires wayland.windowManager.mango.enable.";
          }
        ];

        wayland.windowManager.mango = {
          enable = lib.mkDefault true;
          package = lib.mkDefault cfg.mango.package;
          systemd.xdgAutostart = lib.mkDefault true;
        };

        xdg.configFile."mango/config.toml".source = ./config.toml;

        xdg.configFile."mango/omde.toml".source = pkgs.runCommand "mango-omde.toml" { } ''
          cp ${omdeToml} $out
          ${lib.getExe' cfg.mango.package "mango"} -c $out -p
        '';
      };
    };
}
