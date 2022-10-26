{
  description = "NixOS Configuration";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nixos-generators }: flake-utils.lib.eachDefaultSystem (system:

    let

      pkgs = import nixpkgs {
        inherit system;
      };

    in
    {

      packages.default = nixos-generators.nixosGenerate {
        system = system;
        modules = [
          ./configuration.nix
        ];
        format = "iso";
      };

      packages.nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./modules/filesystems.nix
          ./configuration.nix
        ];
      };
    }
  );
}
