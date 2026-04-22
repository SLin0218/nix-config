{ inputs, config, lib, pkgs, ... }:

{
  imports = [
     ./hardware-configuration.nix
     ./modules/sing-box.nix
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
  boot.kernelParams = [
    "i915.enable_guc=3"      # 开启 GuC/HuC 提交和加载
    "i915.force_probe=46a8"
  ];

  environment.sessionVariables = {
    # 强制禁用 DRM 修改器，解决 DMA-BUF 协商失败
    WLR_DRM_NO_MODIFIERS = "1";
    # 确保使用 Intel Media Driver (iHD) 而不是旧的 i965
    LIBVA_DRIVER_NAME = "iHD";

    # 告诉应用在 Wayland 下运行，避免回退到 Xwayland 导致协商失败
    NIXOS_OZONE_WL = "1";
    GDK_BACKEND = "wayland";
  };

  # 开启硬件绘图支持
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # 核心：适用于 Broadwell 及以后的 iHD 驱动
      vpl-gpu-rt         # 适用于 Alder Lake+ 的 QuickSync 视频处理
      libvdpau-va-gl # 可选：让 VDPAU 应用也能用 VA-API
    ];
  };

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

      docker-compose
    ];

    variables.EDITOR = "nvim";
  };


  virtualisation.docker.enable = true;

  users.users = {
    lin = {
      initialPassword = "123456";
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "networkmanager" "audio" "docker" "etc" "keyd" "input"  "docker" ];
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
    gpu-screen-recorder.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  fonts = {
    packages = with pkgs; [
      adwaita-fonts
      sarasa-gothic
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono

      roboto-mono
      vista-fonts-chs
    ];

    fontconfig = {
      antialias = true;
      hinting.enable = true;
      hinting.autohint = true;
      defaultFonts = {
        sansSerif = [ "Microsoft YaHei" "Noto Sans CJK SC" "Source Han Sans SC" "DejaVu Sans" ];
        serif = [ "Noto Serif CJK SC" "Source Han Serif SC" "DejaVu Serif" ];
        monospace = [ "Noto Sans Mono CJK SC" "Sarasa Mono SC" "DejaVu Sans Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    # Enable font directory for system-wide access
    fontDir.enable = true;
  };

  i18n = {
    extraLocaleSettings = {
      LC_TIME = "en_US.UTF-8"; # 或者 "zh_CN.UTF-8"
    };
    supportedLocales = [
      "zh_CN.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };


  system.stateVersion = "25.11";
}
