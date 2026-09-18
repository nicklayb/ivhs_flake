{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    astronvim-config = {
      url = "github:nicklayb/astronvim/v6";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ivhs-broker = {
      url = "github:nicklayb/ivhs_broker";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ivhs-companion = {
      url = "github:nicklayb/ivhs_companion";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:nixos/nixos-hardware";

      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;

      stateVersion = "26.05";
      username = "ivhs";
      hostname = "ivhs";

      x86Pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations = {
        development = lib.nixosSystem {
          system = "x86_64-linux";

          specialArgs = {
            inherit
              stateVersion
              username
              hostname
              inputs
              ;

            pkgs = x86Pkgs;
          };

          modules = [
            inputs.home-manager.nixosModules.home-manager
            inputs.ivhs-companion.nixosModules.default
            inputs.ivhs-broker.nixosModules.default
            ./ivhs
            ./hardware-configuration.nix
            ./configuration.nix

            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users.${username} = import ./home.nix;

              home-manager.extraSpecialArgs = {
                inherit
                  stateVersion
                  inputs
                  username
                  ;

                pkgs = x86Pkgs;
              };
            }
          ];
        };
        rpi = lib.nixosSystem {
          system = "aarch64-linux";

          specialArgs = {
            inherit stateVersion username inputs;
            hostname = "ivhs-pi";
          };

          modules = [
            inputs.ivhs-companion.nixosModules.default
            inputs.ivhs-broker.nixosModules.default
            "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ./ivhs
            ./rpi.nix
          ];
        };
      };

      nixosModules.ivhs = import ./ivhs;
    };
}
