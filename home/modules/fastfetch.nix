{ ... }:

{

  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "~/.config/nix-config/config/logo.png";
        type = "kitty";
        # width = 28;
        # height = 12;
        padding = {
          top = 2;
          left = 2;
        };
      };
      modules = [
        "title"
        "separator"
        "os"
        "host"
        "kernel"
        "uptime"
        "packages"
        "shell"
        "display"
        "de"
        "wm"
        "wmtheme"
        "theme"
        "icons"
        "font"
        "cursor"
        "terminal"
        "terminalfont"
        "cpu"
        "gpu"
        "memory"
        "disk"
        "battery"
        "poweradapter"
        "locale"
        "break"
        "colors"
      ];
    };
  };
}
