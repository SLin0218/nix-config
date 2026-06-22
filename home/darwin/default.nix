{ inputs, lib, config, pkgs, ... }:
let
  configDir = "${config.home.homeDirectory}/.config/nix-config/config/";
in
{
  imports = [
    ../common.nix
    ./modules/karabiner.nix
  ];

  home.file."/Library/Rime".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/rime-data";
  home.file.".hammerspoon".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/hammerspoon";

  home = {
    homeDirectory = "/Users/lin";
  };

  home.sessionVariables = {
    __ETC_ZSHRC_SOURCED = 1;
    HOMEBREW_INSTALL_CLEANUP = 1;
    HOMEBREW_BREW_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
    HOMEBREW_CORE_GIT_REMOTE = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
    HOMEBREW_INSTALL_FROM_API = 1;
  };

  home.packages = with pkgs; [
    # darwin specific
    jdk21
    maven
  ];
}
