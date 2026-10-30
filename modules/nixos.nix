{
  config,
  inputs,
  self,
  ...
}:
let
  omdeHomeManagerModule = config.flake.homeManagerModules.default;
in
{
  flake.modules.nixos.omde =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      cfg = config.omde;
      system = pkgs.stdenv.hostPlatform.system;

      omdeCli = pkgs.callPackage (self.outPath + "/cli") {
        mango = cfg.mango.package;
        quickshell = self.packages.${system}.default;
      };

      sessionDesktop =
        (pkgs.writeTextDir "share/wayland-sessions/omde.desktop" ''
          [Desktop Entry]
          Name=OMDE
          Comment=OMDE, a Quickshell + Mango desktop environment
          Exec=${lib.getExe omdeCli} session
          Type=Application
          DesktopNames=OMDE;mango;wlroots
        '')
        // {
          providedSessions = [ "omde" ];
        };
    in
    {

      options.omde = {
        enable = lib.mkEnableOption "OMDE, a Quickshell + Mango desktop environment";

        integrateHomeManager = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Inject OMDE's Home Manager module and default it on. Set false when the host imports the module or does not use Home Manager.";
        };

        mango = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable Mango and OMDE's compositor integration.";
          };

          package = lib.mkOption {
            type = lib.types.package;
            default = inputs.mangowm.packages.${system}.default;
            defaultText = lib.literalMD "Mango from the mangowm input";
            description = "Mango package used by both the system and the shell.";
          };
        };

        session.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install a Wayland session entry that runs omde session.";
        };

        services = {
          audio.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable PipeWire, ALSA/Pulse compatibility, and rtkit.";
          };

          network.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable NetworkManager for the bar's network controls.";
          };

          bluetooth.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable BlueZ and blueman for the bar's Bluetooth controls.";
          };

          power.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable UPower and power-profiles-daemon.";
          };

          keyring.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable GNOME Keyring as the Secret Service provider.";
          };

          removableMedia.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable udisks2 for removable media.";
          };

          portals.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable xdg-desktop-portal and the wlr screencast chooser.";
          };
        };

        hardware.graphics.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable hardware graphics support.";
        };

        theme = {
          base16Scheme = lib.mkOption {
            type = lib.types.str;
            default = "${pkgs.base16-schemes}/share/themes/ashes.yaml";
            description = "Stylix base16 scheme used by the desktop.";
          };

          polarity = lib.mkOption {
            type = lib.types.enum [
              "dark"
              "light"
            ];
            default = "dark";
            description = "Stylix polarity.";
          };
        };
      };

      config = lib.mkMerge [
        # Add the HM module when Home Manager is present; cfg.enable adds the default.
        (lib.mkIf (cfg.integrateHomeManager && options ? home-manager) {
          home-manager.sharedModules = [
            omdeHomeManagerModule
          ]
          ++ lib.optional cfg.enable { omde.enable = lib.mkDefault true; };
        })
        (lib.mkIf cfg.enable {
          assertions = [
            {
              assertion = !cfg.integrateHomeManager || options ? home-manager;
              message = "Home Manager is not imported. Import home-manager.nixosModules.home-manager or set omde.integrateHomeManager = false.";
            }
            {
              assertion = options ? stylix;
              message = "OMDE needs Stylix. Import stylix.nixosModules.stylix.";
            }
            {
              assertion = !cfg.mango.enable || options ? programs.mango;
              message = "Mango's NixOS module is not imported. Import mangowm.nixosModules.mango or set omde.mango.enable = false.";
            }
          ];

          programs.mango = lib.mkIf (options ? programs.mango) {
            enable = lib.mkDefault cfg.mango.enable;
            package = lib.mkDefault cfg.mango.package;
          };

          stylix = lib.mkIf (options ? stylix) {
            enable = lib.mkDefault true;
            polarity = cfg.theme.polarity;
            base16Scheme = cfg.theme.base16Scheme;

            fonts = {
              monospace = lib.mkDefault {
                package = pkgs.nerd-fonts.caskaydia-cove;
                name = "CaskaydiaCove Nerd Font";
              };
              sansSerif = lib.mkDefault {
                package = pkgs.geist-font;
                name = "Geist";
              };
              serif = lib.mkDefault {
                package = pkgs.source-serif;
                name = "Source Serif 4";
              };
              emoji = lib.mkDefault {
                package = pkgs.noto-fonts-color-emoji;
                name = "Noto Color Emoji";
              };
              sizes = lib.mkDefault {
                applications = 13.75;
                desktop = 12.5;
                popups = 12.5;
                terminal = 12.5;
              };
            };

            cursor = {
              package = pkgs.volantes-cursors;
              name = "volantes_cursors";
              size = 20;
            };

            targets.gtksourceview.enable = false;
          };

          networking.networkmanager.enable = lib.mkDefault cfg.services.network.enable;

          hardware.bluetooth.enable = lib.mkDefault cfg.services.bluetooth.enable;
          services.blueman.enable = lib.mkDefault cfg.services.bluetooth.enable;

          services.upower.enable = lib.mkDefault cfg.services.power.enable;
          services.power-profiles-daemon.enable = lib.mkIf (!config.services.tuned.enable) (
            lib.mkDefault cfg.services.power.enable
          );

          services.pipewire = lib.mkIf cfg.services.audio.enable {
            enable = lib.mkDefault true;
            alsa.enable = lib.mkDefault true;
            pulse.enable = lib.mkDefault true;
          };
          security.rtkit.enable = lib.mkIf cfg.services.audio.enable (lib.mkDefault true);

          security.polkit.enable = lib.mkDefault true;
          services.dbus.enable = lib.mkDefault true;
          programs.dconf.enable = lib.mkDefault true;

          services.gnome.gnome-keyring.enable = lib.mkIf cfg.services.keyring.enable (lib.mkDefault true);
          services.gnome.gcr-ssh-agent.enable = lib.mkDefault false;

          services.udisks2.enable = lib.mkIf cfg.services.removableMedia.enable (lib.mkDefault true);

          xdg.portal = lib.mkIf cfg.services.portals.enable {
            enable = lib.mkDefault true;
            wlr.settings.screencast = {
              chooser_type = "dmenu";
              chooser_cmd = "${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt 'Share: '";
            };
          };

          hardware.graphics.enable = lib.mkDefault cfg.hardware.graphics.enable;
          environment.sessionVariables.NIXOS_OZONE_WL = lib.mkDefault "1";
          fonts.packages = [ pkgs.noto-fonts ];

          environment.systemPackages = [ omdeCli ];
          services.displayManager.sessionPackages = lib.optional (
            cfg.mango.enable && cfg.session.enable
          ) sessionDesktop;

        })
      ];
    };
}
