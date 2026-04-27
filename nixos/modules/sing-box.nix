{ config, lib, pkgs, utils, ... }:

{
  services.sing-box = {
    enable = true;
    settings = {
      log = {
        level = "info";
        output = "box.log";
      };
      dns = {
        servers = [
          {
            tag = "cf";
            type = "tls";
            server = "1.1.1.1";
            detour = "proxy";
          }
          {
            tag = "local";
            type = "udp";
            server = "223.5.5.5";
          }
        ];
        rules = [
          {
            rule_set = "geosite-category-ads-all";
            action = "reject";
          }
          {
            rule_set = "geosite-geolocation-cn";
            server = "local";
          }
          {
            type = "logical";
            mode = "and";
            rules = [
              {
                rule_set = "geosite-geolocation-!cn";
                invert = true;
              }
              {
                rule_set = "geoip-cn";
              }
            ];
            server = "local";
          }
        ];
        strategy = "ipv4_only";
        disable_cache = true;
      };
      inbounds = [
        {
          type = "mixed";
          tag = "mixed-in";
          listen_port = 7890;
          set_system_proxy = false;
        }
        {
          type = "tproxy";
          tag = "tproxy-in";
          listen = "127.0.0.1";
          listen_port = 9898;
        }
      ];
      outbounds = [];
      route = {
        rules = [
          {
            clash_mode = "direct";
            outbound = "direct";
          }
          {
            clash_mode = "global";
            outbound = "proxy";
          }
          {
            action = "sniff";
          }
          {
            type = "logical";
            mode = "or";
            rules = [
              { protocol = "dns"; }
              { port = 53; }
            ];
            action = "hijack-dns";
          }
          {
            ip_is_private = true;
            outbound = "direct";
          }
          {
            domain_suffix = [ ".gstatic.com" ];
            outbound = "proxy";
          }
          {
            domain_suffix = [ ".yunbosoft.com" ];
            outbound = "direct";
          }
          {
            domain_keyword = [ "honeycom" ];
            outbound = "direct";
          }
          {
            rule_set = [ "geosite-geolocation-cn" ];
            outbound = "direct";
          }
          {
            type = "logical";
            mode = "and";
            rules = [
              { rule_set = "geoip-cn"; }
              {
                rule_set = "geosite-geolocation-!cn";
                invert = true;
              }
            ];
            outbound = "direct";
          }
        ];
        rule_set = [
          {
            type = "remote";
            tag = "geosite-geolocation-cn";
            format = "binary";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-cn.srs";
          }
          {
            type = "remote";
            tag = "geoip-cn";
            format = "binary";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs";
          }
          {
            type = "remote";
            tag = "geosite-category-ads-all";
            format = "binary";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/refs/heads/rule-set/geosite-category-ads-all.srs";
          }
          {
            type = "remote";
            tag = "geosite-geolocation-!cn";
            format = "binary";
            url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-!cn.srs";
          }
        ];
        final = "proxy";
        auto_detect_interface = true;
        default_domain_resolver = {
          server = "cf";
          rewrite_ttl = 60;
          client_subnet = "1.1.1.1";
        };
      };
      experimental = {
        cache_file = {
          enabled = true;
          store_rdrc = true;
        };
        clash_api = {
          external_controller = "127.0.0.1:9090";
          external_ui = "dashboard";
        };
      };
    };
  };

  systemd.services.sing-box = {
    after = [ "agenix.service" ];
    # 允许普通用户查看日志
    serviceConfig.RuntimeDirectory = "sing-box";
    serviceConfig.StateDirectoryMode = lib.mkForce "0711";
    serviceConfig.ExecStartPre = lib.mkAfter [
      (let
        script = pkgs.writeShellScript "update-subscription-script" ''
          export PATH="${pkgs.coreutils}/bin:${pkgs.curl}/bin:${pkgs.jq}/bin:$PATH"

          echo "Updating subscription..."
          export $(grep -v '^#' "${config.age.secrets.update-subscription.path}" | xargs)
          SUBSCRIPTION_URL="https://jmssub.net/members/getsub.php?service=$SERVICE&id=$ID"

          SUBS_RESP=$(curl -s "''${SUBSCRIPTION_URL}")
          BASE_OUTBOUNDS='[{"type":"selector","tag":"proxy","outbounds":["auto"]},{"type":"urltest","tag":"auto","outbounds":[]},{"type":"direct","tag":"direct"}]'
          NODES_JSON=""

          while IFS= read -r line; do
            [ -z "$line" ] && continue
            proto="''${line%%://*}"
            content="''${line#*://}"
            content="''${content%%#*}"

            # Base64 补齐并解码
            len=$((''${#content} % 4))
            [ $len -eq 2 ] && content="''${content}=="
            [ $len -eq 3 ] && content="''${content}="
            decoded=$(echo "$content" | base64 -d 2>/dev/null)

            [ -z "$decoded" ] && continue

            node=""
            if [ "$proto" = "ss" ]; then
              # 1. 提取 tag_name (移除 @ 前的部分和 . 后的部分)
              tag_tmp="''${line#*@}"
              tag_name="''${tag_tmp%%.*}"

              node=$(jq -nc --arg d "$decoded" --arg tn "$tag_name" '
                      ($d | split("@")) as $parts |
                      ($parts[0] | split(":")) as $cred |
                      ($parts[1] | split(":")) as $addr |
                      if ($addr | length) < 2 then empty
                      else {
                          "tag": $tn,
                          "type": "shadowsocks",
                          "server": $addr[0],
                          "server_port": ($addr[1] | tonumber),
                          "password": $cred[1],
                          "method": $cred[0]
                      } end')

            elif [ "$proto" = "vmess" ]; then
              node=$(echo "$decoded" | jq -c '
                      if . == null then empty
                      else {
                          "tag": (.ps | capture("@(?<t>[0-9a-zA-Z]+)\\.").t // .ps // "unnamed"),
                          "type": "vmess",
                          "server": .add,
                          "server_port": (.port | tonumber),
                          "uuid": .id,
                          "alter_id": (.aid | tonumber),
                          "security": "auto"
                      } end')
            fi
            if [ -n "$node" ]; then
              NODES_JSON="''${NODES_JSON}''${node}"$'\n'
              echo "Processed: $proto config"
            fi
        done <<EOF
        $(echo "$SUBS_RESP" | base64 -d)
        EOF

        OUTBOUNDS_FILE=/run/sing-box/outbounds.json

        if [ -n "$NODES_JSON" ]; then
          echo "$NODES_JSON" | jq -s --argjson base "$BASE_OUTBOUNDS" '
                . as $new_nodes |
                ($new_nodes | map(.tag)) as $tags |
                ($base | .[0].outbounds += $tags | .[1].outbounds += $tags) + $new_nodes |
                {outbounds: .}
            ' > $OUTBOUNDS_FILE
          chown --reference=/run/sing-box $OUTBOUNDS_FILE
          echo "Update successful."
        else
          echo "No valid nodes found."
        fi
        '';
      in
      "${script}")
    ];
  };

  # 1. 开启路由转发 (如果需要作为网关)
  #boot.kernel.sysctl = {
  #  "net.ipv4.conf.all.forwarding" = 1;
  #};

  # 配置策略路由 (iprule)
  networking.localCommands = ''
    # 创建路由表 100，将流量重定向到本地
    ip rule add fwmark 1 lookup 100 || true
    ip route add local default dev lo table 100 || true
  '';

  # 固定sing-box uid 用于 nftables 放行自身流量
  users.users.sing-box.uid = 994;

  # 使用 nftables
  networking.nftables = {
    enable = true;
    ruleset = ''
      table ip singbox {

        # 定义需要排除的私有网段
        set reserved_clusters {
          type ipv4_addr
          flags interval
          elements = {
            192.168.0.0/16,
            192.73.0.0/16,
            10.0.0.0/8,
            100.64.0.0/10,
            127.0.0.0/8,
            169.254.0.0/16,
            172.16.0.0/12,
            172.168.0.0/16,
            192.0.0.0/24,
            224.0.0.0/4,
            240.0.0.0/4
          }
        }

        chain prerouting {
          type filter hook prerouting priority mangle; policy accept;
          udp dport 53 mark set 1 tproxy to 127.0.0.1:9898 accept
		      ip daddr @reserved_clusters return
          #ip daddr $RESERVED_IP return
          meta l4proto {tcp, udp} mark set 1 tproxy to 127.0.0.1:9898 accept
        }
        chain output {
          type route hook output priority mangle; policy accept;
          meta skuid 994 accept
          udp dport 53 mark set 1 accept
		      ip daddr @reserved_clusters return
          meta l4proto {tcp, udp} mark set 1 accept
        }
      }

      # 反向路径过滤放行 mark 1
      table inet nixos-fw {
        chain rpfilter-allow {
          meta mark 1 accept comment "allow sing-box tproxy"
        }
      }
    '';
  };

}
