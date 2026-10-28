{ config, ... }:
let
  omde = config.flake.homeManagerModules.default;
in
{
  flake.nixosModules.default =
    { options, lib, ... }:
    {
      config = lib.mkIf (options ? home-manager) {
        home-manager.sharedModules = [ omde ];
      };
    };
}
