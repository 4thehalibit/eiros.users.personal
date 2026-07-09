{ pkgs, ... }:
{
  # Classic Linphone 5.x (pinned via nixpkgs_linphone overlay) — has the vCard
  # import UI that 6.x removed. See flake.nix for the pin.
  environment.systemPackages = [ pkgs.linphone_5 ];
}
