{
  config,
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
  home.file.".gnupg/gpg-agent.conf".text = ''
    default-cache-ttl 600
    max-cache-ttl 7200
    pinentry-program ${config.home.homeDirectory}/.gnupg/pinentry-wrapper.sh
    enable-ssh-support
  '';
  home.file.".gnupg/pinentry-wrapper.sh" = {
    source = ../config/gnupg/pinentry-wrapper.sh;
    executable = true;
  };

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
    pandoc
    (texlive.combine {
      inherit (texlive) scheme-medium collection-langchinese collection-latexextra;
    })
    nmap

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
