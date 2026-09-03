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
  };

  outputs = inputs: {
    nixosConfigurations =
      let
        hostname = "ivhs";
        system = "x86_64-linux";
        stateVersion = "26.05";
        username = "admin";
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        ivhs = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit
              stateVersion
              system
              pkgs
              hostname
              username
              inputs
              ;
          };

          modules = [
            inputs.home-manager.nixosModules.home-manager
            ./ivhs
            ./hardware-configuration.nix
            ./configuration.nix
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home.nix;
              home-manager.extraSpecialArgs = {
                inherit
                  pkgs
                  stateVersion
                  inputs
                  username
                  ;
              };
            }
          ];
        };
      };
    nixosModules = {
      ivhs = import ./ivhs;
    };
  };
}
