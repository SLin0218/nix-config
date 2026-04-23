{ inputs, lib, config, pkgs, ... }:

{
  imports = [
    ./common.nix
    ./modules/karabiner.nix
  ];

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
