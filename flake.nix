{
  description = "Reusable NixOS user configurations";
  outputs =
    {
      nixpkgs,
      nixpkgs_linphone,
      ninjaone,
      self,
    }@inputs:
    let
      import_modules = import ./resources/nix/import_modules.nix;
    in
    {
      nixosModules.default = {
        imports = (import_modules ./users) ++ [
          ninjaone.nixosModules.default
        ];
        # Linphone 6.x dropped vCard import; pin the classic 5.x from 24.05 so the
        # Vonage directory can be imported from a .vcf. Exposed as pkgs.linphone_5.
        nixpkgs.overlays = [
          (final: prev: {
            linphone_5 =
              (import nixpkgs_linphone {
                inherit (prev) system;
                config.allowUnfree = true;
              }).linphone;
          })
        ];
      };
    };
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/master";
    };
    nixpkgs_linphone = {
      url = "github:nixos/nixpkgs/nixos-24.05";
    };
    ninjaone = {
      url = "github:4thehalibit/ninjaone-nixos";
    };
  };
}
