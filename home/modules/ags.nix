{ inputs, pkgs, config, ... }:
let
  mySystem = pkgs.stdenv.hostPlatform.system;
in
{
  programs.ags = {
    enable = true;

    # configDir = ../../config/ags;

    extraPackages = with pkgs; [
      inputs.astal.packages.${mySystem}.io
      inputs.astal.packages.${mySystem}.astal4

      inputs.astal.packages.${mySystem}.battery
      inputs.astal.packages.${mySystem}.hyprland
      inputs.astal.packages.${mySystem}.tray
      inputs.astal.packages.${mySystem}.notifd
      inputs.astal.packages.${mySystem}.wireplumber
      inputs.astal.packages.${mySystem}.network
      inputs.astal.packages.${mySystem}.bluetooth

      libadwaita
    ];
  };
}
