{ pkgs, ...}:

{
  catppuccin = {
    enable = true;      # 默认为所有支持的应用开启
    flavor = "macchiato";   # latte, frappe, macchiato, mocha
    accent = "blue"; # blue, flamingo, green, pink, etc.
  };
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-macchiato-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        variant = "macchiato";
        size = "standard";
      };
    };

    #iconTheme = {
    #  name = "Papirus-Dark";
    #  package = pkgs.catppuccin-papirus-folders.override {
    #    flavor = "macchiato";
    #    accent = "lavender";
    #  };
    #};

    cursorTheme = {
      name = "catppuccin-macchiato-blue-cursors";
      package = pkgs.catppuccin-cursors.macchiatoBlue;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };
}
