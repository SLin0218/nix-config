{ ... }:

{
  imports = [ ./modules/mihomo.nix ];
  networking.hostName = "lindeMacBook-Pro";
  nixpkgs.hostPlatform = "aarch64-darwin";

  homebrew = {
    brews = [
      "container"
    ];

    casks = [
      "android-studio"
      "stats"
      "steam"
      "flameshot"
    ];
  };
}
