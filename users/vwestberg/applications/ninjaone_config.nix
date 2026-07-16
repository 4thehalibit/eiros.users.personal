{ ... }:
{
  programs.ninjaone = {
    enable = true;
    deb_path = /nix/store/giby5b82bkrs5z6n4zpj3pb2x4hhv1qq-ninjarmm-ncplayer_amd64.deb;
    update_alias.enable = true;
    reset_browser_alias.enable = true;
  };
}
