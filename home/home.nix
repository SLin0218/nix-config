{ inputs, lib, config, pkgs, ... }: let
  nvimPath = "${config.home.homeDirectory}/.config/nix-config/config/nvim/";
  keydPath = "${config.home.homeDirectory}/.config/nix-config/config/keyd/app.conf";
  agsPath = "${config.home.homeDirectory}/.config/nix-config/config/ags/";
  ideaVimrcPath = "${config.home.homeDirectory}/.config/nix-config/config/ideavimrc";
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
  ];

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink nvimPath;
  xdg.configFile."keyd/app.conf".source = config.lib.file.mkOutOfStoreSymlink keydPath;
  xdg.configFile."ags".source = config.lib.file.mkOutOfStoreSymlink agsPath;
  home.file.".ideavimrc".source = config.lib.file.mkOutOfStoreSymlink ideaVimrcPath;

  home.activation.linkAgsModules = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ ! -d ${agsPath}/node_modules ]];then
      $DRY_RUN_CMD mkdir -p ${agsPath}/node_modules
    fi
    rm ${agsPath}/node_modules/lunar-javascript
    rm ${agsPath}/node_modules/ags
    $DRY_RUN_CMD ln -sf ${pkgs.lunar-javascript}/lib/node_modules/lunar-javascript $VERBOSE_ARG ${agsPath}/node_modules/
    $DRY_RUN_CMD ln -sf ${pkgs.ags}/share/ags/js/lib $VERBOSE_ARG ${agsPath}/node_modules/ags
  '';

  home = {
    username = "lin";
    homeDirectory = "/home/lin";
    stateVersion = "25.11";
  };


  home.packages = with pkgs; [
    #gui
    kitty
    inkscape
    wechat
    qqmusic-sandbox
    antigravity-fhs
    jetbrains.idea

    # cli
    fzf
    fd
    bat
    zip
    unzip
    eza
    brightnessctl
    gemini-cli
    nodejs
    satty          # 图片标注工具
    grim           # 截图工具
    imagemagick    # 终端查看图片信息
    jq
    wl-clipboard
    btop

  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1"; # 为 Wayland 优化 Electron
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XCURSOR_SIZE = "32";
  };


  programs.home-manager.enable = true;

  services.cliphist = {
    enable = true;
  };

  systemd.user.startServices = "sd-switch";
}
