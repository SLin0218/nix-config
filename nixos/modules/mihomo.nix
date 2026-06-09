{ config, pkgs, lib, ... }:

let
  mihomo-common = import ../../mihomo-common.nix { inherit lib; };
  settings = lib.recursiveUpdate (mihomo-common.mkSettings) {
    tun.enable = false;
  };
  yamlFormat = pkgs.formats.yaml { };
  templateConfig = yamlFormat.generate "mihomo-config-template.yaml" settings;
in
{
  # 声明 age 秘钥文件
  age.secrets.jmssub = {
    file = ../../secrets/update-subscription.age;
  };

  # 激活脚本：在系统激活阶段动态生成带有秘钥的配置文件
  system.activationScripts.postActivation.text = ''
    echo "Applying secrets to Mihomo config..."

    # 确保目标目录存在
    mkdir -p /etc/mihomo

    # 检查秘钥文件是否存在
    if [ -f "${config.age.secrets.jmssub.path}" ]; then
      # shellcheck disable=SC1091
      source "${config.age.secrets.jmssub.path}"

      ${pkgs.gnused}/bin/sed \
        -e "s/__JMS_SERVICE__/$SERVICE/g" \
        -e "s/__JMS_ID__/$ID/g" \
        "${templateConfig}" > /etc/mihomo/config.yaml

      echo "Mihomo config generated successfully at /etc/mihomo/config.yaml"
    else
      echo "Error: jmssub secret not found at ${config.age.secrets.jmssub.path}"
      exit 1
    fi
  '';

  services.mihomo = {
    enable = true;
    configFile = "/etc/mihomo/config.yaml";
    tunMode = true;
    processesInfo = true;
  };


  systemd.services.mihomo = {
    serviceConfig = {
      # 关键配置：赋予处理底层网络数据包和透明代理所需的内核能力
      AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_NET_BIND_SERVICE" ];
    };
  };

}
