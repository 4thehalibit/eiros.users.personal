{ pkgs, ... }:
{
  config.environment.systemPackages = [ pkgs.ferdium ];
}
