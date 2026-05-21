{ pkgs, lib, ... }:
{
  config.systemd.user.services.dms.serviceConfig.Environment = [
    "PATH=${lib.makeBinPath [ pkgs.quickshell ]}:/run/current-system/sw/bin"
  ];
}
