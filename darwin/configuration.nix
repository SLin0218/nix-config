{ pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.neovim
  ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
  system.primaryUser = "lin";

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "fcdeMac-mini";

  users.users.lin = {
    name = "lin";
    home = "/Users/lin";
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = false;
      upgrade = true;
    };
    global = {
      brewfile = true;
    };

    brews = [
      "sing-box"
    ];

    casks = [
      "squirrel-app"
      "hammerspoon"
      "karabiner-elements"
      "raycast"
      "font-lxgw-wenkai"
      "font-jetbrains-mono-nerd-font"
    ];

    taps = [
    ];
  };
}


