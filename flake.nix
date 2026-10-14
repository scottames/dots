{
  description = "Scotty's Darwin system flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
  };

  outputs =
    { ... }@inputs:
      with inputs;
      let
        configuration =
          { pkgs, ... }:
          {
            nix.settings.experimental-features = "nix-command flakes";
            system.configurationRevision = self.rev or self.dirtyRev or null;
            system.stateVersion = 6;
            nixpkgs.hostPlatform = "aarch64-darwin";
          };

        machines = {
          zmbp = {
            username = "scta";
          };
          safmbp = {
            username = "scott";
            manageHomebrew = false;
          };
        };
      in
      {
        darwinConfigurations = nixpkgs.lib.mapAttrs
          (hostname: { username, manageHomebrew ? true }: nix-darwin.lib.darwinSystem {
            modules = [
              configuration
              ./nix/darwin.nix
              ./nix/homebrew.nix
              ./nix/pkgs.nix
            ];
            specialArgs = {
              inherit
                homebrew-bundle
                homebrew-core
                homebrew-cask
                hostname
                manageHomebrew
                nix-homebrew
                username
                ;
            };
          })
          machines;
      }
      // flake-utils.lib.eachDefaultSystem (system: {
        apps.install = {
          type = "app";
          program = toString (
            nixpkgs.legacyPackages.${system}.writeShellScript "install" ''
              # Set defaults from system
              HOSTNAME=$(hostname | cut -d. -f1)

              # Optionally override with command line arguments
              if [[ $# -gt 0 ]]; then
                case $1 in
                  --hostname=*)
                    HOSTNAME="''${1#*=}"
                    shift
                    ;;
                esac
              fi

              sudo \
                ${nix-darwin.packages.${system}.darwin-rebuild}/bin/darwin-rebuild \
                switch --flake .#"$HOSTNAME"
            ''
          );
        };
      });
}
