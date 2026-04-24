{ inputs, lib, config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./modules/karabiner.nix
  ];

  home.file."/Library/Rime".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nix-config/config/rime-data";

  home = {
    homeDirectory = "/Users/lin";
  };

  home.packages = with pkgs; [
    # darwin specific
    fzf
    jdk21
    maven
    mycli
    httpie
  ];
}
