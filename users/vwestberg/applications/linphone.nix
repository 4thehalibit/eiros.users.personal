{ pkgs, ... }:
{
  config.environment.systemPackages = [
    pkgs.linphone
  ];
}
