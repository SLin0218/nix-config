{ config, pkgs, lib, ... }:

let
  outbounds-file = "/etc/sing-box/outbounds.json";
in
{

  environment.etc."sing-box/config.json".text = builtins.toJSON {
    log = { level = "info"; timestamp = true; };
    dns = {
      servers = [
        { tag = "cf"; type = "tls"; server = "1.1.1.1"; detour = "proxy"; }
        { tag = "local"; type = "udp"; server = "223.5.5.5"; }
      ];
      rules = [
        { rule_set = "geosite-category-ads-all"; action = "reject"; }
        { rule_set = "geosite-geolocation-cn"; server = "local"; }
      ];
      strategy = "ipv4_only";
    };
    inbounds = [
      { type = "mixed"; tag = "mixed-in"; listen = "127.0.0.1"; listen_port = 7890; set_system_proxy = true; }
      {
        type = "tun";
        tag = "tun-in";
        interface_name = "utun99";
        address = ["172.18.0.1/30"];
        mtu = 9000;
        auto_route = true;
        route_exclude_address = ["192.168.0.0/16", "172.168.0.0/16", "fc00::/7"];
        strict_route = true;
        stack = "gvisor";
      }
    ];
    outbounds = [ { type = "direct"; tag = "direct"; } { type = "dns"; tag = "dns-out"; } ];
    route = {
      rules = [
        { protocol = "dns"; outbound = "dns-out"; }
        { ip_is_private = true; outbound = "direct"; }
        { rule_set = [ "geosite-geolocation-cn" ]; outbound = "direct"; }
      ];
      rule_set = [
        { type = "remote"; tag = "geosite-geolocation-cn"; format = "binary"; url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-cn.srs"; }
        { type = "remote"; tag = "geosite-category-ads-all"; format = "binary"; url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/refs/heads/rule-set/geosite-category-ads-all.srs"; }
      ];
      auto_detect_interface = true;
      final = "proxy";
    };
  };

  launchd.daemons.sing-box = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.sing-box}/bin/sing-box"
        "-D" "/var/lib/sing-box"
        "-C" "/etc/sing-box"
        "run"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/sing-box/info.log";
      StandardErrorPath = "/var/log/sing-box/error.log";
    };
  };
}
