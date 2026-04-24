let
  lin1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQc4Ee4JCORNkLSER9OiCoAvRwEYKafjEQdfGf0jxpe lin@inspiron-lin";
  root = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAYXENc2QFQkZ4+eWD+/40t0bGWBcCGxxaXyVbtaSky3 root@inspiron-lin";
  nixos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpK4E3961f8GI1tRFLhGz63AMqPYdboF/3BDamAPri0 root@nixos";
  fcdeMac-mini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1G1PXp3bbePi2il3+iV/6L/3yVkPyen6n5DkZrtI4f lin@fcdeMac-mini";
in
{
  "update-subscription.age".publicKeys = [ lin1 root nixos fcdeMac-mini ];
}
