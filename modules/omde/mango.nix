{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omde;
  ipc = call: "spawn,qs ipc -c omde call ${call}";

  execOnce = lib.optionalString (!cfg.systemd.enable) ''
    exec_once = ["${config.xdg.configHome}/quickshell/omde/run"]
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
  config = lib.mkIf (cfg.enable && cfg.mango.enable) {
    xdg.configFile."mango/omde.toml".source = pkgs.runCommand "mango-omde.toml" { } ''
      cp ${omdeToml} $out
      ${lib.getExe' cfg.mango.package "mango"} -c $out -p
    '';
  };
}
