{
  description = "Flake for developing ocf paper genmon applet for COSMIC";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          libPath = with pkgs; lib.makeLibraryPath [
      	      libGL
              libxkbcommon
              wayland
          ];
        in
        {
          default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              cargo
              rustc
              clippy
              rustfmt
              rust-analyzer
              pkg-config
            ];

            buildInputs = with pkgs; [
              libGL
              libxkbcommon
              wayland
            ];

            RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
	    LD_LIBRARY_PATH = libPath;

            shellHook = ''
              export CARGO_HOME="$PWD/.cargo"
              export PATH="$CARGO_HOME/bin:$PATH"
            '';
          };
        }
      );
    };
}
