{ pkgs, ...}:

{
  catppuccin = {
    enable = true;      # 默认为所有支持的应用开启
    flavor = "mocha";   # latte, frappe, macchiato, mocha
    accent = "lavender"; # blue, flamingo, green, pink, etc.
    brave.enable = true;
  };
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-lavender-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "lavender" ];
        variant = "mocha";
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
      name = "catppuccin-mocha-lavender-cursors";
      package = pkgs.catppuccin-cursors.mochaLavender;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };
}
