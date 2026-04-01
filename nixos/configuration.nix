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
      # 自动搜索其他操作系统
      useOSProber = true;
      # 指定 EFI 分区所在的位置
      efiInstallAsRemovable = false;
      device = "nodev"; # UEFI 模式下设为 "nodev"
      # 限制显示的版本数量，防止菜单过长
      configurationLimit = 10;
    };
  };
  # 加载 Dell 专用的内核模块
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "coretemp" "dell_smm_hwmon" ];
  # 为模块添加参数以强制启用（部分 Dell 机型需要）
  boot.extraModprobeConfig = ''
    options dell_smm_hwmon ignore_dmi=1
  '';

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
      lm_sensors # 传感器驱动
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
      roboto-mono
    ];

    fontconfig = {
      antialias = true;
      hinting.enable = true;
      hinting.autohint = true;
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
