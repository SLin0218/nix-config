pkgs: {
  lunar-javascript = import ./lunar-javascript.nix { inherit pkgs; };
  wechat = import ./wechat { inherit pkgs; };
  # update-singbox-sub = import ./update-singbox-sub.nix { inherit pkgs; };
  tproxy = import ./tproxy.nix { inherit pkgs; };
  t = import ./translate { inherit pkgs; };
}
