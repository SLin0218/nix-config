{ config, pkgs, lib, ... }:

let
  sing-box-common = import ../../sing-box-common.nix { inherit lib; };
in
{
  environment.etc."sing-box/config.json".text = builtins.toJSON (sing-box-common.mkSettings {
    inbounds = [
      {
        "type" = "mixed";
        "tag" = "mixed-in";
        "listen_port" = 7890;
      }
      {
        "type" = "tun";
        "tag" = "tun-in";
        "interface_name" = "utun99";
        "address" = [ "172.18.0.1/30" ];
        "mtu" = 9000;
        "auto_route" = true;
        "route_exclude_address" = [ "192.168.0.0/16" "172.168.0.0/16" "fc00::/7" ];
        "strict_route" = true;
        "stack" = "gvisor";
      }
    ];
  });

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
