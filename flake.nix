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
        zephyrDepsHash = "sha256-cLXBrzTd5dy3LF8DNk0AsyHjaJmTVmmZtBklHccoUC0="; # Keep empty to force hash recalculation on your first run
        meta = {
          description = "ZMK firmware for Eyelash Sofle & Dongle";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      # ---------------------------------------------------------
      # TARGET 1 & 2: THE KEYBOARD (What you will use right now)
      # ---------------------------------------------------------

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


      # ---------------------------------------------------------
      # TARGET 3 & 4: THE DONGLE GUESSES (For when it arrives)
      # ---------------------------------------------------------
      # We define Seller A's custom matrix shield, but map it to 
      # the two microcontrollers Seller B most likely used.

      dongle-nano = builder (commonArgs // {
        name = "dongle-nano-firmware";
        board = "eyelash_sofle_central_dongle";
        shield = ""; 
      });

      dongle-xiao = builder (commonArgs // {
        name = "dongle-xiao-firmware";
        board = "seeeduino_xiao_ble";
        shield = "eyelash_sofle_central_dongle"; 
      });

      # all of em

      all = nixpkgs.legacyPackages.${system}.linkFarm "all-firmwares" [
        { name = "left"; path = left; }
        { name = "right"; path = right; }
        # { name = "dongle-nano"; path = dongle-nano; }
        # { name = "dongle-xiao"; path = dongle-xiao; }
      ];

      # Set 'all' as the default package
      default = all;

    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
