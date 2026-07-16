{ ... }:
{
  # vesktop pins electron_40 (40.10.5), which nixpkgs marks insecure past EOL.
  # Allowlisted so the system can still build. Remove once vesktop moves to a
  # newer electron in nixpkgs (check: `nix eval` vesktop's electron dep).
  nixpkgs.config.permittedInsecurePackages = [ "electron-40.10.5" ];
}
