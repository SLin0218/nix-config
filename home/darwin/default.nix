{ config, pkgs, ... }:
let
  rimeFiles = [
    "build/flypy.reverse.bin"
    "build/flypy.table.bin"
    "default.custom.yaml"
    "flypy.schema.yaml"
    "flypy_full.txt"
    "flypy_ok.txt"
    "flypy_sys.txt"
    "flypy_top.txt"
    "flypy_user.txt"
    "flypydz.dict.yaml"
    "flypydz.schema.yaml"
    "lua/calculator_translator.lua"
    "rime.lua"
    "squirrel.custom.yaml"
  ];
in
{
  imports = [
    ../common.nix
    ./modules/karabiner.nix
  ];

  # 映射特定的 Rime 配置文件与 Hammerspoon 配置
  home.file = {
    ".hammerspoon".source = ../../config/hammerspoon;
  }
  // builtins.listToAttrs (
    map (path: {
      name = "Library/Rime/${path}";
      value = {
        source = ../../config/rime-data + "/${path}";
      };
    }) rimeFiles
  );

  home = {
    homeDirectory = "/Users/${config.home.username}";
  };

  home.sessionVariables = {
    __ETC_ZSHRC_SOURCED = 1;
    # HOMEBREW_BREW_GIT_REMOTE  = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git";
    # HOMEBREW_CORE_GIT_REMOTE  = "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git";
    # HOMEBREW_API_DOMAIN       = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api";
    # HOMEBREW_BOTTLE_DOMAIN    = "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles";
    # HOMEBREW_PIP_INDEX_URL    = "https://pypi.tuna.tsinghua.edu.cn/simple";
    HOMEBREW_INSTALL_CLEANUP = 1;
    HOMEBREW_INSTALL_FROM_API = 1;
  };

  home.packages = [ ];
}
