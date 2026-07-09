# Local-only CardDAV server (Radicale) used to sync the Vonage phone directory
# into Linphone. Served over TLS on 127.0.0.1 because Linphone/belle-sip refuses
# to send HTTP Basic credentials over plaintext HTTP.
#
# A self-signed cert (SAN IP:127.0.0.1) is generated on first boot by the
# radicale-tls service. It also writes ${tlsDir}/linphone-rootca.pem = the system
# CA bundle + this cert; point liblinphone's root_ca at that file (in linphonerc)
# so Linphone trusts this server while keeping normal SIP TLS verification intact.
#
# Auth is "none" (localhost bind, non-secret directory); Linphone still needs a
# username (vwestberg) + any non-empty password so it authenticates over TLS.
{ pkgs, ... }:
let
  tlsDir = "/var/lib/radicale/tls";
  cert = "${tlsDir}/cert.pem";
  key = "${tlsDir}/key.pem";
in
{
  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "127.0.0.1:5232" ];
      server.ssl = true;
      server.certificate = cert;
      server.key = key;
      auth.type = "none";
      storage.filesystem_folder = "/var/lib/radicale/collections";
      logging.level = "warning";
    };
  };

  systemd.services.radicale-tls = {
    description = "Generate self-signed TLS cert + CA bundle for local Radicale";
    before = [ "radicale.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.openssl
      pkgs.coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      mkdir -p ${tlsDir}
      chmod 755 ${tlsDir}
      if [ ! -s ${cert} ] || [ ! -s ${key} ]; then
        openssl req -x509 -newkey rsa:2048 -nodes \
          -keyout ${key} -out ${cert} -days 3650 \
          -subj "/CN=127.0.0.1" \
          -addext "subjectAltName=IP:127.0.0.1,DNS:localhost" \
          -addext "basicConstraints=critical,CA:TRUE"
      fi
      # bundle liblinphone can trust: public CAs (keeps SIP TLS working) + our cert
      cat /etc/ssl/certs/ca-certificates.crt ${cert} > ${tlsDir}/linphone-rootca.pem
      chmod 644 ${cert} ${tlsDir}/linphone-rootca.pem
      chgrp radicale ${key}
      chmod 640 ${key}
    '';
  };

  systemd.services.radicale = {
    after = [ "radicale-tls.service" ];
    requires = [ "radicale-tls.service" ];
    # the service is sandboxed (ProtectHome, etc.); let it read the cert dir
    serviceConfig.ReadOnlyPaths = [ tlsDir ];
  };
}
