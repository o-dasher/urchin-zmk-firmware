{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, systems, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;
      perSystem =
        { pkgs, inputs', ... }:
        let
          zmk = inputs'.zmk-nix.legacyPackages;
        in
        {
          packages = rec {
            default = firmware;

            firmware = zmk.buildSplitKeyboard {
              name = "urchin-firmware";

              src = pkgs.lib.sourceFilesBySuffices inputs.self [
                ".board"
                ".cmake"
                ".conf"
                ".defconfig"
                ".dts"
                ".dtsi"
                ".json"
                ".keymap"
                ".overlay"
                ".shield"
                ".yml"
                "_defconfig"
              ];

              board = "nice_nano_v2";
              shield = "urchin_%PART%";

              enableZmkStudio = true;

              zephyrDepsHash = "sha256-9+v4qQmpoEdxILkrMl4pA/FaTqwRIAawyZctCzlGDAI=";

              meta = {
                description = "ZMK firmware for Urchin split keyboard";
                license = pkgs.lib.licenses.mit;
                platforms = pkgs.lib.platforms.all;
              };
            };

            flash = inputs'.zmk-nix.packages.flash.override { inherit firmware; };
            update = inputs'.zmk-nix.packages.update;
          };

          devShells.default = inputs'.zmk-nix.devShells.default.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs or [ ] ++ [ pkgs.nixfmt];
          });
        };
    };
}
