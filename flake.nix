{
  description = "Rust development template";

  inputs = {
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
    ...
  }:
    utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = import nixpkgs {inherit system;};
        toolchain = pkgs.rustPlatform;
      in rec
      {
        # Executed by `nix build`
        packages.default = toolchain.buildRustPackage {
          pname = "template";
          version = "0.1.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;

          # For other makeRustPlatform features see:
          # https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md#cargo-features-cargo-features
        };

        # Executed by `nix run`
        apps.default = utils.lib.mkApp {drv = packages.default;};

        # Used by `nix develop`
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            (with toolchain; [
              cargo
              rustc
              rustLibSrc
            ])
            # wayland protocols
            wayland
            wayland-protocols

            # gdb debug
            gdb

            # c lib
            clippy
            rustfmt
            pkg-config
            systemd
            seatd
            libdisplay-info
            libinput
            libxkbcommon
            libgbm
            mesa

            # OpenGL/EGL
            libGL
            libglvnd
          ];

          # Specify the rust-src path (many editors rely on this)
          RUST_SRC_PATH = "${toolchain.rustLibSrc}";

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
            wayland
            libGL
            libglvnd
          ]);

          env = {
            XDG_CONFIG_HOME = "${builtins.getEnv "HOME"}/.config";
          };
        };
      }
    );
}
