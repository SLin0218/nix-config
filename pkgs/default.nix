pkgs: {
  lunar-javascript = import ./lunar-javascript.nix { inherit pkgs; };
  wechat = import ./wechat { inherit pkgs; };
  tproxy = import ./tproxy.nix { inherit pkgs; };
  t = import ./translate { inherit pkgs; };
  jar-launcher = import ./jar-launcher { inherit pkgs; };
}
