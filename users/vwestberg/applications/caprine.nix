{ pkgs, ... }:
{
  config.environment.systemPackages = [ pkgs.caprine-bin ];
}
