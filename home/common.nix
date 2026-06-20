{ inputs, lib, config, pkgs, ... }:

{
  imports = [
    ./modules/zsh.nix
    ./modules/starship.nix
    ./modules/kitty.nix
    ./modules/theme.nix
    ./modules/fastfetch.nix
    ./modules/editor.nix
  ];

  home.file.".sqlfluff".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix-config/config/.sqlfluff";

  home = {
    username = "lin";
    stateVersion = "25.11";
  };

  home.packages = with pkgs; [
    # common cli
    fd
    jq
    antigravity-cli
    nodejs
    pnpm
    delta
    # update-singbox-sub
    t
    mpc
    mpv
    android-tools

    # build tools
    gdb
    python3
    cmake
    gnumake
    gcc
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs = {
    home-manager.enable = true;
    btop.enable = true;
    eza.enable = true;
    bat.enable = true;
  };
}
