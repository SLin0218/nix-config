{ lib }:

{
  mkSettings = { inbounds ? [ ] }: {
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
      disable_cache = false;
    };
    inbounds = inbounds;
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
          inbound = "basic-in";
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
          ip_cidr = [ "172.16.90.0/24" ];
          outbound = "tw";
        }
        {
          ip_is_private = true;
          outbound = "direct";
        }
        {
          domain_keyword = [ "google" ];
          outbound = "proxy";
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
}
