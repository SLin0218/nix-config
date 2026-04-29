{ config, lib, pkgs, utils, ... }:

let
  sing-box-common = import ../../sing-box-common.nix { inherit lib; };
in
{
  services.sing-box = {
    enable = true;
    settings = sing-box-common.mkSettings {
      inbounds = [
        {
          type = "mixed";
          tag = "mixed-in";
          listen_port = 7890;
          set_system_proxy = false;
        }
        {
          type = "tproxy";
          tag = "basic-in";
          listen = "127.0.0.1";
          listen_port = 9898;
        }
      ];
    };
  };

  systemd.services.sing-box = {
    after = [ "agenix.service" ];
    # 允许普通用户查看日志
    serviceConfig.RuntimeDirectory = "sing-box";
    serviceConfig.StateDirectoryMode = lib.mkForce "0711";
    serviceConfig.ExecStartPre = lib.mkAfter [
      "${pkgs.update-singbox-sub}/bin/update-singbox-sub"
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
            10.0.0.0/8,
            169.254.0.0/16,
            100.64.0.0/10,
            172.16.0.0/12,
            172.168.15.0/24,
            192.168.0.0/16,
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
