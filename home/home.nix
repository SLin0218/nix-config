{ inputs, lib, config, pkgs, ... }: let
  keydPath = "${config.home.homeDirectory}/.config/nix-config/config/keyd/app.conf";
  rimeDataPath = "${config.home.homeDirectory}/.config/nix-config/config/rime-data/";
in
{
  imports = [
    ./modules/zsh.nix
    ./modules/starship.nix
    ./modules/hyprland.nix
    ./modules/browser.nix
    ./modules/kitty.nix
    ./modules/theme.nix
    ./modules/ags.nix
    ./modules/fastfetch.nix
    ./modules/hypr.nix
    ./modules/editor.nix
    ./modules/music.nix
    ./modules/lang.nix
  ];

  xdg.configFile."keyd/app.conf".source = config.lib.file.mkOutOfStoreSymlink keydPath;
  home.file.".local/share/fcitx5/rime".source = config.lib.file.mkOutOfStoreSymlink rimeDataPath;

  home = {
    username = "lin";
    homeDirectory = "/home/lin";
    stateVersion = "25.11";
  };


  home.packages = with pkgs; [
    #gui
    inkscape
    wechat
    antigravity-fhs
    jetbrains.idea

    # cli
    fd
    zip
    unzip
    brightnessctl
    gemini-cli
    nodejs
    satty          # 图片标注工具
    grim           # 截图工具
    imagemagick    # 终端查看图片信息
    jq
    wl-clipboard
    mpc
    libnotify
    mpv
    rtkit
    gdb

  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1"; # 为 Wayland 优化 Electron
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XCURSOR_SIZE = "32";
    # 强制 Wayland 合成器和客户端不使用复杂的显存修改器
    WLR_DRM_NO_MODIFIERS = "1";
  };

  programs = {
    home-manager.enable = true;
    btop.enable = true;
    eza.enable = true;
    bat.enable = true;
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
        obs-vaapi #optional AMD hardware acceleration
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
