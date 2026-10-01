{
  description = "Ona dotfiles: standalone home-manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim-cfg.url = "github:javier-varez/nixvim-cfg";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixvim-cfg,
      ...
    }:
    let
      mkHome =
        {
          system,
          username,
          homeDirectory,
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = {
            nixvim = nixvim-cfg.packages.${system}.default;
          };
          modules = [
            ./home.nix
            {
              home = { inherit username homeDirectory; };
            }
          ];
        };

      getEnvOr =
        name: fallback:
        let
          value = builtins.getEnv name;
        in
        if value == "" then fallback else value;
    in
    {
      # home-manager CLI matching the pinned release, used by install.sh.
      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: {
        home-manager = home-manager.packages.${system}.home-manager;
      });

      # The user/home of an Ona environment isn't known ahead of time, so the
      # default configuration is resolved from the environment. Requires
      # `--impure`, e.g.:
      #   home-manager switch --flake ~/dotfiles#default --impure
      homeConfigurations.default = mkHome {
        system = builtins.currentSystem;
        username = getEnvOr "USER" (throw "USER must be set (evaluate with --impure)");
        homeDirectory = getEnvOr "HOME" (throw "HOME must be set (evaluate with --impure)");
      };
    };
}
