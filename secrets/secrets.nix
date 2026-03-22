let
  lin1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQc4Ee4JCORNkLSER9OiCoAvRwEYKafjEQdfGf0jxpe lin@inspiron-lin";
  root = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAYXENc2QFQkZ4+eWD+/40t0bGWBcCGxxaXyVbtaSky3 root@inspiron-lin";
  nixos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBpK4E3961f8GI1tRFLhGz63AMqPYdboF/3BDamAPri0 root@nixos";
in
{
  "update-subscription.age".publicKeys = [ lin1 root nixos ];
}
