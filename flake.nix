{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
  in {
    packages = forAllSystems (system: rec {
      
      builder = zmk-nix.legacyPackages.${system}.buildKeyboard;

      # Common arguments shared across all pieces
      commonArgs = {
        src = nixpkgs.lib.sourceFilesBySuffices self [ ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi" ".json" ".keymap" ".overlay" ".shield" ".yml" "_defconfig" ];
        zephyrDepsHash = "sha256-gsqiTDJLAihVyBXVFlgXwqRmlREcFJctKpl4tEWmVlY="; # Keep empty to force hash recalculation on your first run
        meta = {
          description = "ZMK firmware for Eyelash Sofle & Dongle";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      # Left Half (Acts as Central brain by default)
      left = builder (commonArgs // {
        name = "left-firmware";
        board = "eyelash_sofle_left";
        shield = "nice_view_adapter nice_view";
      });

      # Right Half (Always acts as a peripheral)
      right = builder (commonArgs // {
        name = "right-firmware";
        board = "eyelash_sofle_right";
        shield = "nice_view_adapter nice_view";
      });

      dongle-nano = builder (commonArgs // {
        name = "dongle-firmware";
        board = "nice_nano_v2";
        shield = "dongle dongle_display"; 
      });

      settings-reset = builder (commonArgs // {
        name = "settings-reset-firmware";
        board = "nice_nano_v2";
        shield = "settings_reset";
      });

      all = nixpkgs.legacyPackages.${system}.linkFarm "all-firmwares" [
        { name = "left"; path = left; }
        { name = "right"; path = right; }
        { name = "dongle-nano"; path = dongle-nano; }
        { name = "settings-reset"; path = settings-reset; }
      ];

      # Set 'all' as the default package
      default = all;

    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
