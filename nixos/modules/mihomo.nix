{ config, pkgs, lib, ... }:

let
  mihomo-common = import ../../mihomo-common.nix { inherit lib; };
  # 生成带有占位符的 JSON 模板（这个文件在 Nix Store 里，是只读的）
  settings = lib.recursiveUpdate (mihomo-common.mkSettings) {
    tun.enable = false;
  };
  jsonFormat = pkgs.formats.json { };
  templateConfig = jsonFormat.generate "mihomo-config-template.json" settings;
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
        "${templateConfig}" > /etc/mihomo/config.json

      echo "Mihomo config generated successfully at /etc/mihomo/config.json"
    else
      echo "Error: jmssub secret not found at ${config.age.secrets.jmssub.path}"
      exit 1
    fi
  '';

  systemd.services.mihomo = {
    configFile = "/etc/mihomo/config.json";
  };

}
