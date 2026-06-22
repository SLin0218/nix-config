{ pkgs, ... }:

{
  networking.hostName = "lindeMacBook-Pro";

  homebrew = {
    casks = [
      "android-studio"
      "hiddenbar"
    ];
  };
}
