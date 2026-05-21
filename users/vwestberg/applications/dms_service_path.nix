{ pkgs, ... }:
{
  config.systemd.user.services.dms.path = [ pkgs.quickshell ];
}
