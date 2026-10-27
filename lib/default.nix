{ inputs }:
let
  inherit (inputs.nixpkgs) lib;
  env = import ./env.nix { inherit lib; };
in
{
  inherit env;

  mkHost =
    {
      hostname,
      system,
      extraModules ? [ ],
    }:
    lib.nixosSystem {
      specialArgs = {
        inherit
          inputs
          env
          hostname
          ;
      };
      modules = [
        { nixpkgs.hostPlatform = system; }
        ../modules/nixos
        ../hosts/${hostname}
        inputs.home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = import ../overlays { inherit inputs; };

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-bak";
            extraSpecialArgs = { inherit inputs env hostname; };
            users.${env.USERNAME} = import ../users/${env.USERNAME}/home.nix;
          };
        }
      ]
      ++ extraModules;
    };
}
