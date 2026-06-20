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

  home.sessionVariables = {
    __ETC_ZSHRC_SOURCED = 1;
    HOMEBREW_INSTALL_CLEANUP = 1;
  };

  home.packages = with pkgs; [
    # darwin specific
    jdk21
    maven
  ];
}
