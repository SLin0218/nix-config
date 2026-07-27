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
  ];
in
{
  imports = [
    ../common.nix
  ];

  dconf.enable = false;

  # 映射特定的 Rime 配置文件与 Hammerspoon 配置
  home.file = builtins.listToAttrs (
    map (path: {
      name = ".local/share/fcitx5/rime/${path}";
      value = {
        source = ../../config/rime-data + "/${path}";
      };
    }) rimeFiles
  );

  home = {
    homeDirectory = "/home/lin";
  };

  home.packages = with pkgs; [
    zip
    unzip
    wl-clipboard
    tproxy
  ];

  systemd.user.startServices = "sd-switch";
}
