{ inputs, config, lib, pkgs, ... }:

{
  imports = [
     ./hardware-configuration.nix
     ./modules/sing-box.nix
     ./modules/fcitx5.nix
     ./modules/keyd.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = true;
    # 一直等待
    timeout = null;
    grub = {
      enable = true;
      # 指定为 EFI 模式
      efiSupport = true;
      # 自动搜索其他操作系统（如 Windows），可选
      useOSProber = true;
      # 指定 EFI 分区所在的位置，通常是 /boot 或 /boot/efi
      efiInstallAsRemovable = false;
      device = "nodev"; # UEFI 模式下设为 "nodev"
      # 限制显示的版本数量，防止菜单过长
      configurationLimit = 10;
    };
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.networkmanager.enable = true;
  networking.hostName = "inspiron-lin";
  time.timeZone = "Asia/Shanghai";

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath;
      trusted-users = [ "lin" ];

      auto-optimise-store = true;
    };

    channel.enable = false;

    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };


  environment = {
    systemPackages = with pkgs; [
      git
      neovim
      wget
      sing-box
      keyd
      upower
    ];

    variables.EDITOR = "nvim";

    sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
    };

  };



  users.users = {
    lin = {
      initialPassword = "1771312";
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "networkmanager" "audio" "docker" "etc" "keyd" "input" ];
      shell = pkgs.zsh;
    };
  };

  services = {
    openssh.enable = true;
    upower.enable = true;
  };

  security.pam.services.hyprlock = {};

  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };
    zsh.enable = true;
  };

  fonts = {
    packages = with pkgs; [
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
    ];

    fontconfig = {
      antialias = true;
      hinting.enable = true;
      defaultFonts = {
        sansSerif = [ "Noto Sans CJK SC" "Source Han Sans SC" "DejaVu Sans" ];
        serif = [ "Noto Serif CJK SC" "Source Han Serif SC" "DejaVu Serif" ];
        monospace = [ "Noto Sans Mono CJK SC" "Sarasa Mono SC" "DejaVu Sans Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    # Enable font directory for system-wide access
    fontDir.enable = true;
  };

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "lavender";
  };

  system.stateVersion = "25.11";
}
