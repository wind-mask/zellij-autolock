{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      rust-overlay,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        buildTarget = "wasm32-wasip1";
        packageName = "zellij-autolock";

        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default 
          ];
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [ buildTarget ];
        };

        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustToolchain;
          rustc = rustToolchain;
        };
      in
      {
        packages.default = rustPlatform.buildRustPackage {
          name = packageName;
          src = ./.;
          depsBuildBuild = [ pkgs.openssl pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl pkgs.pkg-config ];
          cargoLock.lockFile = ./Cargo.lock;
          CARGO_BUILD_TARGET = buildTarget;
          buildPhase = ''
            runHook preBuild
            cargo build --release -p ${packageName} --target=${buildTarget}
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/lib
            cp target/${buildTarget}/release/*.wasm $out/lib/
            runHook postInstall
          '';

          # Disable checks if they only work for WASM
          doCheck = false;
        };
      }
    );
}
