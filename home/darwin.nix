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

  home = {
    username = "lin";
    homeDirectory = "/Users/lin";
    stateVersion = "25.11";
  };

  home.packages = with pkgs; [
    # cli
    fd
    fzf
    gemini-cli
    nodejs
    jq
    jdk21
    maven

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
