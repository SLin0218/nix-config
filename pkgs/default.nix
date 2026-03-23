pkgs: {
  lunar-javascript = import ./lunar-javascript.nix { inherit pkgs; };
  wechat = import ./wechat { inherit pkgs; lib = pkgs.lib; };
}
