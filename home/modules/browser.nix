{ pkgs, ... }: {
  programs.chromium = {
    enable = true;
    package = pkgs.brave;

    # 命令行启动参数
    commandLineArgs = [
      "--enable-features=TouchpadMemoryPressureMonitor" # 内存优化
      "--ozone-platform-hint=auto"                      # Wayland 自动支持 (对 Hyprland 非常重要)
    ];

  };
}
