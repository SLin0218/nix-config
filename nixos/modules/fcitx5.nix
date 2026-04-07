{ config, lib, pkgs, ... }:

{

  i18n = {
    extraLocaleSettings = {
      LC_TIME = "en_US.UTF-8"; # 或者 "zh_CN.UTF-8"
    };
    supportedLocales = [
      "zh_CN.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
    inputMethod = {
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
  };

  catppuccin.fcitx5 = {
    enable = true;
    enableRounded = true;
  };

}
