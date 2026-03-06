let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHIB9gJxYTUgrC25g6iRw5L1CBzBnpkigigJzHbKb8B";
in
{
  "hosts/04-valheim/asset/valheim-env.age".publicKeys = [ key ];
  "hosts/03-jarvis/asset/transmission-env.age".publicKeys = [ key ];
  "hosts/03-jarvis/asset/cloudflare-api.age".publicKeys = [ key ];
}
