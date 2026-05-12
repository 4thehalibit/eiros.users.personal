{ lib, ... }:
{
  config.eiros.users.vwestberg.extra_groups = lib.mkDefault [
    "wheel"
    "networkmanager"
    "libvirtd"
    "docker"
    "input"
    "dialout"
  ];
}
