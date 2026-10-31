{ self, ... }:
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

      mkBool =
        default: description:
        lib.mkOption {
          type = lib.types.bool;
          inherit default description;
        };
      mkUint =
        default: description:
        lib.mkOption {
          type = lib.types.ints.unsigned;
          inherit default description;
        };
      mkPositive =
        default: description:
        lib.mkOption {
          type = lib.types.ints.positive;
          inherit default description;
        };
      mkPercent =
        default: description:
        lib.mkOption {
          type = lib.types.ints.between 0 100;
          inherit default description;
        };
      mkStr =
        default: description:
        lib.mkOption {
          type = lib.types.str;
          inherit default description;
        };
      mkList =
        default: description:
        lib.mkOption {
          type = lib.types.listOf lib.types.str;
          inherit default description;
        };

      qml =
        if cfg.liveReload.enable then
          config.lib.file.mkOutOfStoreSymlink "${toString cfg.liveReload.source}/qml"
        else
          "${cfg.qmlPackage}/share/omde/qml";

      omdeCli = pkgs.callPackage (self.outPath + "/cli") {
        mango = cfg.mango.package;
        quickshell = cfg.package;
      };
    in
    {
      options.omde = {
        enable = lib.mkEnableOption "OMDE desktop shell";

        package = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${system}.default;
          defaultText = lib.literalExpression "self.packages.\${system}.default";
          description = "Quickshell with OMDE's logind and search QML modules.";
        };

        qmlPackage = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${system}.omde-qml;
          defaultText = lib.literalExpression "self.packages.\${system}.omde-qml";
          description = "The QML tree; share/omde/qml is linked into Quickshell's config.";
        };

        cli.package = lib.mkOption {
          type = lib.types.package;
          default = omdeCli;
          defaultText = lib.literalMD "the `omde` command built against `omde.package`";
          description = "The command that starts and controls OMDE.";
        };

        bar = {
          visibleTags = mkUint 3 "Tags the bar keeps room for; more scroll through it.";

          columns = mkPositive 102 "Widest the bar may get, in character columns; the launcher matches it.";

          screenNames =
            mkList [ ]
              "Screens the bar may move to as focus changes, by output name; empty means all.";

          modules = {
            layout = mkBool true "Mango's layout picker (left end).";
            title = mkBool true "Focused window icon and title.";
            clock = mkBool true "Center clock and its calendar.";
            media = mkBool true "Media player while there is one.";
            network = mkBool true "Network cell and its list.";
            bluetooth = mkBool true "Bluetooth cell and its list.";
            audio = mkBool true "Volume cell and its list.";
            brightness = mkBool true "Brightness cell.";
            system = mkBool true "CPU/memory cell.";
            battery = mkBool true "Battery cell and power profiles.";
            notifications = mkBool true "Notification bell and its list.";
            tray = mkBool true "Tray behind the bar's right end.";
            keepAwake = mkBool true "Cup that keeps the session awake.";
          };
        };

        clock = {
          format = mkStr "hh:mm" "Clock format, in Qt's date/time syntax.";
          dateFormat = mkStr "dddd d MMMM yyyy" "Date under the clock, in Qt's date/time syntax.";
        };

        steps = {
          volume = mkPercent 5 "Percent per wheel notch on the volume cell.";
          brightness = mkPercent 5 "Percent per wheel notch on the brightness cell.";
        };

        battery = {
          low = mkPercent 20 "Battery percent at which a notice appears.";
          critical = mkPercent 10 "Battery percent at which the notice turns critical.";
        };

        osd = {
          timeout = mkUint 3000 "Milliseconds the volume/brightness slider stays up after the last change.";
        };

        system = {
          interval = mkUint 3000 "Milliseconds between /proc samples for the CPU/memory cell.";
          processInterval = mkUint 2000 "Milliseconds between process-list samples, while the list is up.";
          processCount = mkPositive 6 "Processes listed.";
          warning = mkPercent 90 "CPU or memory percent at which the icon turns to the warning color.";
        };

        notifications = {
          timeout = mkUint 5000 "Milliseconds a toast stays up.";
          maxPopups = mkUint 3 "Toasts stacked at once.";
          columns = mkPositive 44 "Width of the notification list and toasts, in character columns.";
        };

        idle = {
          lock = mkUint 300 "Seconds without input before locking; 0 never.";
          screenOff = mkUint 360 "Seconds without input before the screens turn off; 0 never.";
        };

        launcher = {
          rows = mkPositive 8 "Rows shown before the launcher scrolls.";
          terminal = mkList [
            "xdg-terminal-exec"
          ] "Command prefix for Terminal=true desktop entries; the app's command is appended.";
        };

        screenshot = {
          dir = mkStr "${config.home.homeDirectory}/Pictures/Screenshots" "Where screenshots are saved";
        };

        scale = lib.mkOption {
          type = lib.types.numbers.nonnegative;
          default = 1.0;
          description = "Multiplies every length in the shell; 1 is the font's own size.";
        };

        wallpaper = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Image drawn on every screen's background layer; null is the packaged wallpaper.";
        };

        liveReload = {
          enable = lib.mkEnableOption "linking OMDE's QML from a source checkout";

          source = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Checkout to link qml/ from; required when live reload is on.";
          };
        };

        systemd = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Start OMDE as a systemd user service. Off lets Mango start it from mango/omde.toml instead.";
          };

          target = lib.mkOption {
            type = lib.types.str;
            default =
              if config.wayland.windowManager.mango.enable or false then
                "mango-session.target"
              else
                config.wayland.systemd.target;
            defaultText = lib.literalMD "`mango-session.target` with Mango, else `wayland.systemd.target`.";
            description = "User target the service is ordered against and wanted by.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = config.programs.quickshell.enable;
            message = "OMDE is installed through programs.quickshell; don't disable it.";
          }
          {
            assertion = !cfg.liveReload.enable || cfg.liveReload.source != null;
            message = "omde.liveReload.source must be set when live reload is enabled.";
          }
        ];

        systemd.user.services.omde = lib.mkIf cfg.systemd.enable {
          Unit = {
            Description = "OMDE, a Quickshell bar for Mango";
            After = [ cfg.systemd.target ];
            PartOf = [ cfg.systemd.target ];
            X-Restart-Triggers = [
              "${config.xdg.configFile."omde/config.json".source}"
              "${config.xdg.configFile."omde/palette.json".source}"
            ];
          };

          Service = {
            Type = "exec";
            ExecStart = "${lib.getExe cfg.cli.package} run";
            Restart = "on-failure";
            RestartSec = "5s";
            TimeoutStopSec = "5s";
            Slice = "session.slice";
          };

          Install.WantedBy = [ cfg.systemd.target ];
        };

        programs.quickshell = {
          enable = lib.mkDefault true;
          package = lib.mkDefault cfg.package;
          configs.omde = qml;
        };

        home.packages = [
          cfg.cli.package
        ]
        ++ (with pkgs; [
          grim
          slurp
          satty
          wl-clipboard
          libnotify
          brightnessctl
        ]);
        services.cliphist.enable = true;

        dconf.settings."org/blueman/general".plugin-list = lib.mkDefault [ "!StatusNotifierItem" ];

        xdg.configFile."omde/config.json".text = builtins.toJSON {
          bar = {
            inherit (cfg.bar) visibleTags columns screenNames;
            modules = {
              inherit (cfg.bar.modules)
                layout
                title
                clock
                media
                network
                bluetooth
                audio
                brightness
                system
                battery
                notifications
                tray
                keepAwake
                ;
            };
          };
          clock = {
            inherit (cfg.clock) format dateFormat;
          };
          steps = {
            inherit (cfg.steps) volume brightness;
          };
          battery = {
            inherit (cfg.battery) low critical;
          };
          osd = {
            inherit (cfg.osd) timeout;
          };
          system = {
            inherit (cfg.system)
              interval
              processInterval
              processCount
              warning
              ;
          };
          notifications = {
            inherit (cfg.notifications) timeout maxPopups columns;
          };
          idle = {
            inherit (cfg.idle) lock screenOff;
          };
          launcher = {
            inherit (cfg.launcher) rows terminal;
          };
          screenshot = {
            inherit (cfg.screenshot) dir;
          };
          inherit (cfg) scale;
          wallpaper = if cfg.wallpaper == null then "" else "${cfg.wallpaper}";
        };

        xdg.configFile."omde/palette.json".text = builtins.toJSON {
          colors = cfg.theme.resolvedColors;
          font = { inherit (cfg.theme.font) family size; };
          inherit (cfg.theme) borderWidth motion;
        };
      };
    };
}
