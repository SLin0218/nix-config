let
  inspiron-lin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGQc4Ee4JCORNkLSER9OiCoAvRwEYKafjEQdfGf0jxpe lin@inspiron-lin";
  fcdeMac-mini = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1G1PXp3bbePi2il3+iV/6L/3yVkPyen6n5DkZrtI4f lin@fcdeMac-mini";
in
{
  "update-subscription.age".publicKeys = [ inspiron-lin fcdeMac-mini ];
}
