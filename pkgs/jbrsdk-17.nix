{ pkgs }:

let
  stdenv = pkgs.stdenv;
  system = stdenv.hostPlatform.system;

  # 定义不同系统架构对应的包下载参数
  srcs = {
    "aarch64-darwin" = {
      url = "https://cache-redirector.jetbrains.com/intellij-jbr/jbrsdk-17.0.12-osx-aarch64-b1087.25.tar.gz";
      sha256 = "1ihpijnwdyvl3pqjszfi17rxhsq0ikdaq3r33fiwyi7z08gmmfpp";
    };
    "x86_64-linux" = {
      url = "https://cache-redirector.jetbrains.com/intellij-jbr/jbrsdk-17.0.12-linux-x64-b1087.25.tar.gz";
      sha256 = "0cxxw02mad2ljlry78f7km9d7plkpgnspxggy9q2h2ly4fz452vi";
    };
  };

  # 获取当前系统匹配的下载源，如果不支持则抛出错误
  srcAttrs = srcs.${system} or (throw "Unsupported system architecture: ${system}");

in
stdenv.mkDerivation rec {
  pname = "jbrsdk-17";
  version = "17.0.12-b1087.25";

  src = pkgs.fetchurl {
    inherit (srcAttrs) url sha256;
  };

  # 预编译包直接安装
  dontBuild = true;
  dontStrip = true;

  # Linux 需要的链接库 and 自动补丁 Hook
  nativeBuildInputs = pkgs.lib.optionals stdenv.isLinux [ pkgs.autoPatchelfHook ];
  
  buildInputs = pkgs.lib.optionals stdenv.isLinux (with pkgs; [
    alsa-lib
    fontconfig
    libx11
    libxext
    libxi
    libxrender
    libxtst
    wayland
    stdenv.cc.cc.lib
  ]);

  installPhase = ''
    mkdir -p $out
    # 解压并拷贝 JDK 文件目录
    if [ -d Contents/Home ]; then
      cp -r Contents/Home/* $out/
    else
      cp -r * $out/
    fi
  '';

  meta = with pkgs.lib; {
    description = "JetBrains Runtime 17 SDK with DCEVM support (precompiled binary)";
    homepage = "https://github.com/JetBrains/JetBrainsRuntime";
    license = licenses.gpl2;
    platforms = [ "aarch64-darwin" "x86_64-linux" ];
  };
}
