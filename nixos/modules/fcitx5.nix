{ config, lib, pkgs, ... }:

{
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-rime
        fcitx5-gtk
        rime-data
      ];
    };
  };

  catppuccin.fcitx5 = {
    enable = true;
    enableRounded = true;
  };

}
