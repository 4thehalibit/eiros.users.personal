# baresip SIP softphone. Chosen over Linphone because it loads the whole Vonage
# directory from a plain-text contacts file (see baresip-contacts) and, with the
# gtk module, shows incoming-call popups. The account (with password) lives in
# ~/.baresip/accounts, kept out of this public repo.
{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.baresip

    # regenerate ~/.baresip/contacts from whatever CSV is in ~/Vonage/
    (pkgs.writeShellScriptBin "baresip-contacts" ''
      csv=$(ls -1 "$HOME"/Vonage/*.csv 2>/dev/null | head -1)
      if [ -z "$csv" ]; then
        echo "baresip-contacts: no CSV found in ~/Vonage/" >&2
        exit 1
      fi
      mkdir -p "$HOME/.baresip"
      ${pkgs.python3}/bin/python3 -c "
import csv, sys, re
DOMAIN = 'edge6-tlssbc3va.prod.vonedge.com'
Q = chr(34)
out = ['#', '# Vonage phone directory (generated from ~/Vonage CSV)', '#', str()]
w = 0
with open(sys.argv[1], newline=str()) as f:
    for row in csv.DictReader(f):
        name = (row.get('User') or str()).strip()
        ext = (row.get('Extension') or str()).strip()
        phone = re.sub(r'\D', str(), (row.get('Phone Number') or str()))
        target = ext or phone
        if not name or not target:
            continue
        out.append(Q + name.replace(Q, chr(39)) + Q + ' <sip:' + target + '@' + DOMAIN + '>')
        w += 1
open(sys.argv[2], 'w').write(chr(10).join(out) + chr(10))
print('baresip-contacts: wrote %d contacts to ~/.baresip/contacts' % w)
      " "$csv" "$HOME/.baresip/contacts"
    '')
  ];
}
