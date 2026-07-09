{
  pkgs,
  ...
}:

{
  imports = [
    ./modules/zsh.nix
    ./modules/starship.nix
    ./modules/kitty.nix
    ./modules/theme.nix
    ./modules/fastfetch.nix
    ./modules/editor.nix
  ];

  home.file.".sqlfluff".source = ../config/sqlfluff;
  home.file.".gitconfig".source = ../config/gitconfig;

  home = {
    username = "lin";
    stateVersion = "25.11";
  };

  home.packages = with pkgs; [
    # common cli
    fd
    jq
    nixd
    nixfmt
    ripgrep
    nodejs
    pnpm
    delta
    fzf
    mycli
    httpie

    jetbrains.idea

    # translate
    t
    mpc
    mpv
    android-tools

    gnupg
    pinentry-curses

    git-crypt

    # build tools
    gdb
    python3
    cmake
    gnumake
    gcc
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    SSH_AUTH_SOCK = "$(gpgconf --list-dir agent-ssh-socket)";
    GPG_TTY = "$(tty)";
  };

  programs = {
    home-manager.enable = true;
    btop.enable = true;
    eza.enable = true;
    bat.enable = true;
  };
}
