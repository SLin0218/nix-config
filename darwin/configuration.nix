{ pkgs, age, ... }:

{

  imports = [
     ./modules/sing-box.nix
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.neovim
    pkgs.sing-box
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

  # Disable documentation to avoid build failures with mdbook
  documentation.enable = false;
  documentation.man.enable = false;

  users.users.lin = {
    name = "lin";
    home = "/Users/lin";
  };

  # Fonts managed by Nix
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    lxgw-wenkai
  ];

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
    ];
  };

  age.secrets.update-subscription.file = ../secrets/update-subscription.age;
}


