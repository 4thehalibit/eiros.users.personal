{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vonage-vcard" ''
      csv=$(ls -1 "$HOME"/Vonage/*.csv 2>/dev/null | head -n1)
      if [ -z "$csv" ]; then
        echo "vonage-vcard: no CSV found in ~/Vonage/" >&2
        exit 1
      fi
      out="$HOME/Vonage/vonage-contacts.vcf"
      ${pkgs.python3}/bin/python3 -c "
import csv, sys
src, dst = sys.argv[1], sys.argv[2]
def esc(v):
    bs = chr(92)
    v = v.replace(bs, bs + bs)
    v = v.replace(';', bs + ';')
    v = v.replace(',', bs + ',')
    v = v.replace(chr(10), bs + 'n')
    return v
def split_name(full):
    parts = full.split()
    if not parts:
        return str(), str()
    if len(parts) == 1:
        return parts[0], str()
    return parts[-1], ' '.join(parts[:-1])
written = skipped = 0
with open(src, newline=str()) as f, open(dst, 'w', newline='\r\n') as out:
    reader = csv.DictReader(f)
    for row in reader:
        name  = (row.get('User') or str()).strip()
        ext   = (row.get('Extension') or str()).strip()
        phone = (row.get('Phone Number') or str()).strip()
        email = (row.get('Email') or str()).strip()
        group = (row.get('Groups') or str()).strip()
        if not name or not (ext or phone):
            skipped += 1
            continue
        family, given = split_name(name)
        lines = ['BEGIN:VCARD', 'VERSION:3.0']
        lines.append('N:%s;%s;;;' % (esc(family), esc(given)))
        lines.append('FN:%s' % esc(name))
        if ext:
            lines.append('TEL;TYPE=work,pref:%s' % esc(ext))
        if phone:
            lines.append('TEL;TYPE=voice:%s' % esc(phone))
        if email:
            lines.append('EMAIL;TYPE=internet:%s' % esc(email))
        if group:
            lines.append('ORG:%s' % esc(group))
        lines.append('END:VCARD')
        out.write('\n'.join(lines) + '\n')
        written += 1
print('vonage-vcard: wrote %d contacts to %s (skipped %d with no name or number)' % (written, dst, skipped))
      " "$csv" "$out"
    '')
  ];
}
