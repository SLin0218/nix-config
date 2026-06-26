{ pkgs, ... }:

{
  imports = [ ./modules/mihomo.nix ];
  networking.hostName = "fcdeMac-mini";
  nixpkgs.hostPlatform = "aarch64-darwin";

  homebrew = {
    casks = [
      "raycast"
    ];
  };
}
