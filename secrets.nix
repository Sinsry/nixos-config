let
  sinsry = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHIB9gJxYTUgrC25g6iRw5L1CBzBnpkigigJzHbKb8B Sinsry@users.noreply.github.com";
in
{
  "hosts/valheim/asset/valheim-env.age".publicKeys = [ sinsry ];
}
