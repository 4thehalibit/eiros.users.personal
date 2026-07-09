# Regenerates the Vonage vCard and pushes every contact into the local Radicale
# CardDAV address book (see radicale.nix). Idempotent: contacts are keyed by UID,
# so re-running updates in place instead of duplicating. Point Linphone at
#   http://127.0.0.1:5232/<user>/vonage
{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vonage-carddav-sync" ''
      set -eu
      # Radicale is TLS on localhost with a self-signed cert; -k is fine here.
      curl="${pkgs.curl}/bin/curl -k"
      base="https://127.0.0.1:5232"
      book="$base/$USER/vonage"
      vcf="$HOME/Vonage/vonage-contacts.vcf"

      if ! $curl -s -o /dev/null --max-time 3 "$base/"; then
        echo "vonage-carddav-sync: Radicale not reachable at $base (is the service running?)" >&2
        exit 1
      fi

      # regenerate the vCard from the latest CSV in ~/Vonage/
      vonage-vcard

      # ensure the address book exists (ignore error if it already does)
      $curl -s -o /dev/null -u "$USER:x" -X MKCOL "$book/" \
        -H "Content-Type: application/xml" \
        --data '<?xml version="1.0" encoding="utf-8"?><D:mkcol xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:carddav"><D:set><D:prop><D:resourcetype><D:collection/><C:addressbook/></D:resourcetype><D:displayname>Vonage</D:displayname></D:prop></D:set></D:mkcol>' || true

      # split the combined vCard into one file per contact, named by UID
      tmp=$(mktemp -d)
      trap 'rm -rf "$tmp"' EXIT
      ${pkgs.python3}/bin/python3 -c "
import sys, os, re
data = open(sys.argv[1], encoding='utf-8').read()
n = 0
for chunk in data.split('END:VCARD'):
    if 'BEGIN:VCARD' not in chunk:
        continue
    card = chunk[chunk.index('BEGIN:VCARD'):] + 'END:VCARD' + chr(13) + chr(10)
    m = re.search('UID:(.+)', card)
    uid = m.group(1).strip() if m else ('card-%d' % n)
    uid = re.sub('[^A-Za-z0-9._-]', '-', uid)
    open(os.path.join(sys.argv[2], uid + '.vcf'), 'w', encoding='utf-8', newline=str()).write(card)
    n += 1
" "$vcf" "$tmp"

      ok=0
      fail=0
      for f in "$tmp"/*.vcf; do
        code=$($curl -s -o /dev/null -w "%{http_code}" -u "$USER:x" \
          -X PUT "$book/$(basename "$f")" \
          -H "Content-Type: text/vcard; charset=utf-8" --data-binary @"$f")
        case "$code" in
          2*) ok=$((ok + 1)) ;;
          *) fail=$((fail + 1)); echo "  ! $(basename "$f") -> HTTP $code" >&2 ;;
        esac
      done
      echo "vonage-carddav-sync: uploaded $ok contacts to $book (failed $fail)"
    '')
  ];
}
