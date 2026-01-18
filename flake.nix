{
  description = "A devShell example";

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        # rustToolchain = pkgs.rust-bin.beta.latest.default.override {
        rustToolchain = pkgs.rust-bin.nightly.latest.default.override {
          extensions = [ "rust-src" "rustfmt" "clippy" ];
        };
      in
      {
        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = "ev-cmd";
          version = "0.1.0";
          
          src = ./.;
          
          cargoLock = {
            lockFile = ./Cargo.lock;
          };
          
          nativeBuildInputs = with pkgs; [
            pkg-config
          ];
          
          meta = with pkgs.lib; {
            description = "evdev command tool";
            homepage = "https://github.com/danhab99/ev-cmd";
            license = licenses.mit;
            maintainers = [{
              name = "Dan Habot";
              email = "dan.habot@gmail.com";
            }];
          };
        };

        devShells.default = with pkgs; mkShell {
          buildInputs = [
            pkg-config
            rustToolchain
            pkgs.rust-analyzer
            rustup
            gdb
          ];

          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        };
      }
    );
}
