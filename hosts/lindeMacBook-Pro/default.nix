{ pkgs, ... }:

{
  imports = [ ./modules/mihomo.nix ];
  networking.hostName = "lindeMacBook-Pro";
  nixpkgs.hostPlatform = "aarch64-darwin";

  homebrew = {
    brews = [
      "jadx"
    ];

    casks = [
      "android-studio"
      "stats"
      "steam"
    ];
  };
}
