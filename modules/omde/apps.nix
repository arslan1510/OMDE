{
  flake.modules.homeManager.omde =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      config = lib.mkIf config.omde.enable {
        programs.ghostty = {
          enable = lib.mkDefault true;
          systemd.enable = lib.mkDefault false;
        };

        home.packages = [ pkgs.kdePackages.dolphin ];

        xdg.terminal-exec = {
          enable = lib.mkDefault true;
          settings.default = lib.mkDefault [ "com.mitchellh.ghostty.desktop" ];
        };

        xdg.mimeApps = {
          enable = lib.mkDefault true;
          defaultApplications."inode/directory" = lib.mkDefault [ "org.kde.dolphin.desktop" ];
        };
      };
    };
}
