{ inputs, lib, config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./modules/hyprland.nix
    ./modules/browser.nix
    ./modules/ags.nix
    ./modules/hypr.nix
    ./modules/music.nix
    ./modules/lang.nix
  ];

  # 静态配置
  xdg.configFile."keyd/app.conf".source = ../config/keyd/app.conf;

  # 动态配置
  home.file.".local/share/fcitx5/rime".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix-config/config/rime-data";

  home = {
    homeDirectory = "/home/lin";
  };


  home.packages = with pkgs; [
    # gui
    inkscape
    wechat
    antigravity-fhs
    jetbrains.idea

    # linux cli
    zip
    unzip
    brightnessctl
    satty
    grim
    imagemagick
    wl-clipboard
    mpc
    libnotify
    mpv
  ];

  home.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XCURSOR_SIZE = "32";
  };

  programs = {
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
        obs-vaapi
        obs-gstreamer
        obs-vkcapture
      ];
    };
  };

  services.cliphist = {
    enable = true;
  };

  systemd.user.startServices = "sd-switch";
}
