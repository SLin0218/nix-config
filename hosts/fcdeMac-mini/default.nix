{ pkgs, ... }:

{
  networking.hostName = "fcdeMac-mini";
  nixpkgs.hostPlatform = "aarch64-darwin";
}
