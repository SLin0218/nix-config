{ pkgs, ... }:

{
  networking.hostName = "lins-iMac";
  nixpkgs.hostPlatform = "x86_64-darwin";

  homebrew = {
    casks = [
      "raycast"
    ];
  };
}
