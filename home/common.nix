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

  # 自动下载并软链接 HotswapAgent 包到 ~/lib/hotswap-agent.jar
  home.file."lib/hotswap-agent.jar".source = pkgs.fetchurl {
    url = "https://github.com/HotswapProjects/HotswapAgent/releases/download/RELEASE-2.0.3/hotswap-agent-2.0.3.jar";
    sha256 = "1ycl0mzzhysxw0j94j6kzvsbjkbzh87k39z2s8v3alnqnwj9gx2f";
  };

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

    # rime
    librime

    # java & build tools
    jbrsdk-21
    maven
    mvn-springboot-debug

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
    JAVA_HOME = "${pkgs.jbrsdk-21}";
  };

  programs = {
    home-manager.enable = true;
    btop.enable = true;
    eza.enable = true;
    bat.enable = true;
  };
}
