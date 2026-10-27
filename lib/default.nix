{ inputs }:
let
  inherit (inputs.nixpkgs) lib;
  vars = import ./vars.nix;
in
{
  inherit vars;

  mkHost =
    {
      hostname,
      system,
      extraModules ? [ ],
    }:
    lib.nixosSystem {
      specialArgs = { inherit inputs vars hostname; };
      modules = [
        { nixpkgs.hostPlatform = system; }
        ../modules/nixos
        ../hosts/${hostname}
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = import ../overlays { inherit inputs; };

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-bak";
            extraSpecialArgs = { inherit inputs vars hostname; };
            users.${vars.username} = import ../users/${vars.username}/home.nix;
          };
        }
      ]
      ++ extraModules;
    };
}
