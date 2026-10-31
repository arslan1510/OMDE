{
  lib,
  writeTextDir,
  cli,
}:
(writeTextDir "share/wayland-sessions/omde.desktop" ''
  [Desktop Entry]
  Name=OMDE
  Comment=OMDE, a Quickshell + Mango desktop environment
  Exec=${lib.getExe cli} session
  Type=Application
  DesktopNames=OMDE;mango;wlroots
'')
// {
  providedSessions = [ "omde" ];
}
