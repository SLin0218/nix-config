{ pkgs, lib }:

let
  pname = "qqmusic";
  version = "1.1.8";

  src = pkgs.fetchurl {
    url = "https://c.y.qq.com/cgi-bin/file_redirect.fcg?bid=dldir&file=ecosfile_plink%2Fmusic_clntupate%2Flinux%2Fother%2Fqqmusic-1.1.8.AppImage&sign=1-845b70c2cc9293f3393a2ce533d708f75362c0c7f412dcc1b1a3f42b8cf0bb34-68cb7c17";
    sha256 = "1s5spilil8d3yl3l1kxvh2n0b25p7qvpddjxcncnciciq9457lw8";
  };

  appimageContents = pkgs.appimageTools.extract {
    inherit pname version src;
  };

  qqmusic-raw = pkgs.appimageTools.wrapAppImage {
    inherit pname version;
    src = appimageContents;
  };

  qqmusic-sandboxed = pkgs.writeShellScriptBin "qqmusic" ''
    # 定义并创建沙箱目录
    SANDBOX_DIR="$HOME/.local/share/qqmusic-sandbox"
    mkdir -p "$SANDBOX_DIR"

    # 针对 XWayland 注入 Xresources DPI 配置，修复 Fcitx5 候选框
    echo "Xft.dpi: 160" | ${pkgs.xrdb}/bin/xrdb -merge

    # 执行 bubblewrap 沙箱
    exec ${pkgs.bubblewrap}/bin/bwrap \
      --dev-bind / / \
      --bind "$SANDBOX_DIR" "$HOME" \
      --ro-bind-try "$HOME/.Xauthority" "$HOME/.Xauthority" \
      --setenv HOME "$HOME" \
      --setenv XDG_DATA_DIRS "/run/current-system/sw/share" \
      --setenv LANG "zh_CN.UTF-8" \
      --setenv NIXOS_OZONE_WL "1" \
      --setenv QT_QPA_PLATFORM "wayland;xcb" \
      ${qqmusic-raw}/bin/qqmusic --no-sandbox \
        --ozone-platform-hint=auto \
        --enable-features=WaylandWindowDecorations \
        "$@"
  '';

in
pkgs.symlinkJoin {
  name = "${pname}-sandboxed-${version}";
  paths = [ qqmusic-sandboxed qqmusic-raw ];
  postBuild = ''
    mkdir -p $out/share/applications
    if [ -f ${appimageContents}/qqmusic.desktop ]; then
      cp ${appimageContents}/qqmusic.desktop $out/share/applications/
      sed -i "s|^Exec=.*|Exec=$out/bin/qqmusic %U|" $out/share/applications/qqmusic.desktop
    fi
  '';

  meta = with lib; {
    description = "QQ Music (Linux) with bubblewrap sandbox";
    homepage = "https://y.qq.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "qqmusic";
  };
}
