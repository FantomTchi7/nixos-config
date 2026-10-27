{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  nixConfig = {
    extra-substituters = [ "https://cache.lantian.pub/lantian" ];
    extra-trusted-public-keys = [ "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=" ];
  };

  outputs =
    inputs:
    let
      myLib = import ./lib { inherit inputs; };
    in
    {
      nixosConfigurations."YUV-PC" = myLib.mkHost {
        hostname = "YUV-PC";
        system = "x86_64-linux";
      };

      formatter.x86_64-linux = inputs.nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
