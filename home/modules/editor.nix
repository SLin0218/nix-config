
{ pkgs, config, ... }: let
  nvimPath = "${config.home.homeDirectory}/.config/nix-config/config/nvim/";
  emacsPath = "${config.home.homeDirectory}/.config/nix-config/config/emacs/";
  ideaVimrcPath = "${config.home.homeDirectory}/.config/nix-config/config/ideavimrc";
in
{
  home.file.".ideavimrc".source = config.lib.file.mkOutOfStoreSymlink ideaVimrcPath;
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink nvimPath;
  xdg.configFile."slin-emacs".source = config.lib.file.mkOutOfStoreSymlink emacsPath;
  xdg.configFile."emacs/init.el".text = ''
    (add-to-list 'load-path "~/.config/slin-emacs")
    (require 'slin-emacs)
  '';

  programs.emacs = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.emacs else pkgs.emacs-gtk;
  };

}
