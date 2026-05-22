{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.wlr-randr ];

  programs.zsh.shellAliases = {
    dms = "dms-settings";
    fixhdmi = "output=$(wlr-randr | grep 'VX3211-4K' | awk '{print $1}') && [ -n \"$output\" ] && wlr-randr --output \"$output\" --off && sleep 2 && wlr-randr --output \"$output\" --on || echo 'ViewSonic not detected'";
    claude = "cd ~/claude && command claude";
    freshworks = "distrobox enter freshworks-dev";
  };

  programs.zsh.interactiveShellInit = ''
    rebuild() { { [ -d /tmp/eiros ] || gh repo clone lcleveland/eiros /tmp/eiros; cd /tmp/eiros && git pull; } && sudo nixos-rebuild switch --impure --flake '/tmp/eiros#default' --override-input eiros_users '/home/vwestberg/eiros-config' --override-input eiros_hardware 'github:4thehalibit/eiros.hardware.framework16'; }
    deploy() { cd ~/eiros-config && git add -A && (git diff --cached --quiet || git commit -m "''${1:-update config}") && git push && rebuild; }
  '';
}
