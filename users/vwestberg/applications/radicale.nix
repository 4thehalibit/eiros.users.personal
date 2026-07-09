# Local-only CardDAV server (Radicale) used to sync the Vonage phone directory
# into Linphone, which in v6 can only bulk-import contacts over CardDAV.
# Bound to 127.0.0.1 with no auth: reachable only from this machine, and the
# data is a non-secret company directory. Seed it with `vonage-carddav-sync`.
{ ... }:
{
  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "127.0.0.1:5232" ];
      auth.type = "none";
      storage.filesystem_folder = "/var/lib/radicale/collections";
      logging.level = "warning";
    };
  };
}
