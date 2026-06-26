{ pkgs, ... }:

{
  imports = [ ./modules/mihomo.nix ];
  networking.hostName = "lindeMacBook-Pro";
  nixpkgs.hostPlatform = "aarch64-darwin";

  homebrew = {
    casks = [
      "android-studio"
      "stats"
    ];
  };
}
