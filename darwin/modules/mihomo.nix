{ config, pkgs, lib, ... }:

let
  mihomo-common = import ../../mihomo-common.nix { inherit lib; };
  # 生成带有占位符的 JSON 模板（这个文件在 Nix Store 里，是只读的）
  settings = lib.recursiveUpdate (mihomo-common.mkSettings) {
    tun.enable = true;
    proxies = [
      {
        name = "TW";
        type = "http";
        server = "192.168.1.100";
        port = 8888;
      }
    ] ++ mihomo-common.mkSettings.proxies;
    rules = [ "IP-CIDR,172.16.90.0/24,TW" ] ++ mihomo-common.mkSettings.rules;
  };
  yamlFormat = pkgs.formats.yaml { };
  templateConfig = yamlFormat.generate "mihomo-config-template.yaml" settings;
in
{

  # 激活脚本：在系统激活阶段动态生成带有秘钥的配置文件
  system.activationScripts.postActivation.text = ''
    echo "Applying secrets to Mihomo config..."

    # 确保目标目录存在
    mkdir -p /etc/mihomo

    # shellcheck disable=SC1091
    source "/etc/mihomo/jmssub"

    ${pkgs.gnused}/bin/sed \
      -e "s/__SERVICE__/$SERVICE/g" \
      -e "s/__ID__/$ID/g" \
      "${templateConfig}" > /etc/mihomo/config.yaml

    echo "Mihomo config generated successfully at /etc/mihomo/config.yaml"
  '';

  launchd.daemons.mihomo = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.mihomo}/bin/mihomo"
        "-d"
        "/etc/mihomo/"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/mihomo/info.log";
      StandardErrorPath = "/var/log/mihomo/error.log";
    };
  };

}
