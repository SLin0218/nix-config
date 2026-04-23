{ pkgs, config, ... }: let
  # 使用绝对路径，并确保没有末尾斜杠
  configDir = "${config.home.homeDirectory}/.config/nix-config/config";
in
{
  # 1. 基础文件链接
  home.file.".ideavimrc".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/ideavimrc";

  # 2. 使用 xdg.configFile 管理目录软链接，这是 Home Manager 推荐的处理方式
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/nvim";
  xdg.configFile."slin-emacs".source = config.lib.file.mkOutOfStoreSymlink "${configDir}/emacs";

  # 3. Emacs 初始化引导
  xdg.configFile."emacs/init.el".text = ''
    (add-to-list 'load-path "~/.config/slin-emacs")
    (require 'slin-emacs)
  '';

  # 5. Emacs 软件包管理
  programs.emacs = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.emacs else pkgs.emacs-gtk;
  };
}
