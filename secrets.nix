let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHIB9gJxYTUgrC25g6iRw5L1CBzBnpkigigJzHbKb8B";
in
{
  "hosts/valheim/asset/valheim-env.age".publicKeys = [ key ];
}
