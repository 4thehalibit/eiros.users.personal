{
  description = "Reusable NixOS user configurations";
  outputs =
    {
      nixpkgs,
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
      };
    };
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/master";
    };
    ninjaone = {
      url = "github:4thehalibit/ninjaone-nixos";
    };
  };
}
