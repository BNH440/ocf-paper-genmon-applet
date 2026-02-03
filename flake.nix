{
  description = "OCF Paper Genmon Applet for COSMIC";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, crane }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        craneLib = crane.mkLib pkgs;

        runtimeLibs = with pkgs; [
          libGL
          libxkbcommon
          wayland
          vulkan-loader
        ];

        commonArgs = {
          src = pkgs.lib.cleanSourceWith {
            src = ./.;
            filter = path: type:
              (craneLib.filterCargoSources path type) ||
              (builtins.match ".*\.desktop$" path != null);
          }; 
          strictDeps = true;
          nativeBuildInputs = with pkgs; [ pkg-config copyDesktopItems ];
          buildInputs = runtimeLibs;
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        myApplet = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
          pname = "ocf-paper-genmon-applet";
          version = "0.1.0";

          # 1. Install the desktop file normally
          postInstall = ''
            install -Dm644 ocf-paper-genmon-applet.desktop $out/share/applications/ocf-paper-genmon-applet.desktop
            
            # 2. Replace the placeholder @EXEC_PATH@ with the actual binary path
            sed -i "s|@EXEC_PATH@|$out/bin/ocf-paper-genmon-applet|g" $out/share/applications/ocf-paper-genmon-applet.desktop
          '';

          postFixup = ''
            patchelf --add-rpath "${pkgs.lib.makeLibraryPath runtimeLibs}" $out/bin/ocf-paper-genmon-applet
          '';
        });
      in
      {
        packages.default = myApplet;
        
        apps.default = flake-utils.lib.mkApp {
          drv = myApplet;
        };

        devShells.default = craneLib.devShell {
          inputsFrom = [ myApplet ];
          packages = with pkgs; [ cargo rustc rust-analyzer clippy rustfmt ];
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath runtimeLibs;
        };
      }
    );
}
