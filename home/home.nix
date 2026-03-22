{ inputs, lib, config, pkgs, ... }: let
  nvimPath = "${config.home.homeDirectory}/.config/nix-config/config/nvim/";
  keydPath = "${config.home.homeDirectory}/.config/nix-config/config/keyd/app.conf";
  agsPath = "${config.home.homeDirectory}/.config/nix-config/config/ags/";
  customPkgs = import ../pkgs/default.nix pkgs;
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
  ];

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink nvimPath;
  xdg.configFile."keyd/app.conf".source = config.lib.file.mkOutOfStoreSymlink keydPath;
  xdg.configFile."ags".source = config.lib.file.mkOutOfStoreSymlink agsPath;

  home.activation.linkAgsModules = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ${agsPath}/node_modules
    $DRY_RUN_CMD ln -sf ${customPkgs.lunar-javascript}/lib/node_modules/lunar-javascript $VERBOSE_ARG ${agsPath}/node_modules/
  '';

  home = {
    username = "lin";
    homeDirectory = "/home/lin";
    stateVersion = "25.11";
  };


  home.packages = with pkgs; [
    #gui
    kitty

    # cli
    fastfetch
    fzf
    fd
    bat
    zip
    unzip
    eza
    brightnessctl
    gemini-cli
    nodejs
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    NIXOS_OZONE_WL = "1"; # 为 Wayland 优化 Electron
    NODE_PATH = "${config.home.profileDirectory}/lib/node_modules";
  };


  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";
}
