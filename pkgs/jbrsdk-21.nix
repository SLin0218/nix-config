{ pkgs }:

let
  stdenv = pkgs.stdenv;
  system = stdenv.hostPlatform.system;

  # 定义不同系统架构对应的包下载参数
  srcs = {
    "aarch64-darwin" = {
      url = "https://cache-redirector.jetbrains.com/intellij-jbr/jbrsdk-21.0.3-osx-aarch64-b446.1.tar.gz";
      sha256 = "1naw25vwa806qlyw0bkx6ky6phwyb5mhn40y4jrx4b8xfvq8nm5d";
    };
    "x86_64-linux" = {
      url = "https://cache-redirector.jetbrains.com/intellij-jbr/jbrsdk-21.0.3-linux-x64-b446.1.tar.gz";
      sha256 = "07vb97bl4xhh0iqfiddg71r43whxj7prdzlakyhyimd66vipa3yd";
    };
  };

  # 获取当前系统匹配的下载源，如果不支持则抛出错误
  srcAttrs = srcs.${system} or (throw "Unsupported system architecture: ${system}");

in
stdenv.mkDerivation rec {
  pname = "jbrsdk-21";
  version = "21.0.3-b446.1";

  src = pkgs.fetchurl {
    inherit (srcAttrs) url sha256;
  };

  # 预编译包直接安装
  dontBuild = true;
  dontStrip = true;

  # Linux 需要的链接库和自动补丁 Hook
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
    description = "JetBrains Runtime 21 SDK with DCEVM support (precompiled binary)";
    homepage = "https://github.com/JetBrains/JetBrainsRuntime";
    license = licenses.gpl2;
    platforms = [ "aarch64-darwin" "x86_64-linux" ];
  };
}
