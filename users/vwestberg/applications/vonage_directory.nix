{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vonage-directory-popup" ''
      csv=$(ls -1 "$HOME"/vonage-directory/*.csv 2>/dev/null | head -n1)
      if [ -z "$csv" ]; then
        printf '\n  No CSV found in ~/vonage-directory/\n\n' | \
          ${pkgs.fzf}/bin/fzf --ansi --layout=reverse --no-info --no-preview \
            --header="  Vonage Directory  (drop a .csv in ~/vonage-directory/)" \
            --header-first --bind="esc:abort,enter:abort"
        exit 0
      fi
      ${pkgs.python3}/bin/python3 -c "
import csv, sys
ESC = chr(27)
R   = ESC + '[0m'
B   = ESC + '[1m'
HDR = ESC + '[1;96m'
with open(sys.argv[1], newline=str()) as f:
    rows = [r for r in csv.reader(f) if any(c.strip() for c in r)]
if not rows:
    sys.exit(0)
ncol   = max(len(r) for r in rows)
rows   = [r + [str()] * (ncol - len(r)) for r in rows]
widths = [max(len(r[i]) for r in rows) for i in range(ncol)]
def fmt(r, color=str()):
    return '  ' + '  '.join(color + r[i].ljust(widths[i]) + R for i in range(ncol))
print(fmt(rows[0], HDR + B))
for r in rows[1:]:
    print(fmt(r))
      " "$csv" | ${pkgs.fzf}/bin/fzf --ansi --no-sort --layout=reverse --header-lines=1 \
            --header="  Vonage Directory  (type to search, Esc to close)" \
            --header-first --no-info --no-preview --bind="esc:abort,enter:abort"
    '')
  ];
}
