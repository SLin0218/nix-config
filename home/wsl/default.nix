{ config, pkgs, ... }:

{
  imports = [
    ../common.nix
  ];

  home = {
    homeDirectory = "/home/lin";
  };

  home.packages = with pkgs; [
    zip
    unzip
    wl-clipboard
  ];

  systemd.user.startServices = "sd-switch";
}
