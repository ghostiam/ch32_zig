{
  description = "A flake for Zig";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # For upgrade use `nix flake update zig zigscient-src`
    zig = {
      url = "github:mitchellh/zig-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    zls-src = {
      url = "github:zigtools/zls/0.15.0";
      flake = false;
    };

    # https://github.com/llogick/zigscient
    zigscient-src = {
      url = "github:llogick/zigscient/0.14.x";
      flake = false;
    };

    # https://github.com/ghostiam/minichlink-ocd
    minichlink-ocd = {
      url = "github:ghostiam/minichlink-ocd";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        zig.follows = "zig";
      };
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      overlays = [
        (
          _final: prev: with prev; rec {
            zig = inputs.zig.packages.${system}."0.15.1";
            zls = stdenvNoCC.mkDerivation {
              pname = "zls";
              version = "${inputs.zls-src.shortRev}-${inputs.zls-src.lastModifiedDate}";
              meta.mainProgram = "zls";
              src = "${inputs.zls-src}";
              nativeBuildInputs = [ zig ];
              phases = [
                "unpackPhase"
                "buildPhase"
                "checkPhase"
              ];
              buildPhase = ''
                mkdir -p .cache
                zig build install --cache-dir $(pwd)/.zig-cache --global-cache-dir $(pwd)/.cache -Dcpu=baseline -Doptimize=ReleaseSafe --prefix $out
              '';
              checkPhase = ''
                zig build test --cache-dir $(pwd)/.zig-cache --global-cache-dir $(pwd)/.cache -Dcpu=baseline
              '';
            };
            zigscient = stdenvNoCC.mkDerivation {
              pname = "zigscient";
              version = "${inputs.zigscient-src.shortRev}-${inputs.zigscient-src.lastModifiedDate}";
              meta.mainProgram = "zigscient";
              src = "${inputs.zigscient-src}";
              nativeBuildInputs = [ zig ];
              phases = [
                "unpackPhase"
                "patchPhase"
                "buildPhase"
                "checkPhase"
              ];
              patchPhase = ''
                sed -i 's/version = "0.14.1"/version = "0.14.0"/g' build.zig.zon
                sed -i 's/patch = 1/patch = 0/g' build.zig
              '';
              buildPhase = ''
                mkdir -p .cache
                zig build install --cache-dir $(pwd)/.zig-cache --global-cache-dir $(pwd)/.cache -Dcpu=baseline -Doptimize=ReleaseSafe --prefix $out
              '';
              checkPhase = ''
                zig build test --cache-dir $(pwd)/.zig-cache --global-cache-dir $(pwd)/.cache -Dcpu=baseline
              '';
            };
            minichlink-ocd = inputs.minichlink-ocd.packages.${system}.default;
          }
        )
      ];
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit overlays system; };
        # Eval the treefmt modules from ./treefmt.nix
        treefmtEval = inputs.treefmt.lib.evalModule pkgs ./treefmt.nix;
        inherit (pkgs) zig;
        inherit (pkgs) minichlink-ocd;

        # zlsBinName = "zigscient";
        zlsBinName = "zls";
        zls = pkgs.zls;

        buildInputs =
          with pkgs;
          [
            zig
            zls
            # zigscient # Disabled because it does not work with Zig 0.15.1
            xmlstarlet
            coreutils
            bash
            jq
            git
            clang
            minichlink-ocd
          ]
          ++ lib.optionals stdenv.isDarwin [
            apple-sdk_14
          ];

        baseShellHook = ''
          export FLAKE_ROOT="$(nix flake metadata | grep 'Resolved URL' | awk '{print $3}' | sed 's/^path://' | sed 's/^git+file:\/\///')"
        '';
      in
      {
        # run: `nix develop`
        devShells = {
          default = pkgs.mkShell {
            inherit buildInputs;

            shellHook =
              baseShellHook
              + ''
                export HISTFILE="$FLAKE_ROOT/.nix_bash_history"
                sed -i 's/^: [0-9]\{10\}:[0-9];//' $HISTFILE > /dev/null 2>&1
                sed -i '/^#/d' $HISTFILE > /dev/null 2>&1

                export PROJECT_ROOT="$FLAKE_ROOT"
              ''
              + pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin ''
                export NIX_CFLAGS_COMPILE="-iframework $SDKROOT/System/Library/Frameworks -isystem $SDKROOT/usr/include $NIX_CFLAGS_COMPILE"
                export NIX_LDFLAGS="-L$SDKROOT/usr/lib $NIX_LDFLAGS"
              '';
          };

          # Update IDEA paths. Use only if nix installed in whole system.
          # run: `nix develop \#idea`
          idea = pkgs.mkShell {
            inherit buildInputs;

            shellHook = pkgs.lib.concatLines [
              baseShellHook
              ''
                cd "$FLAKE_ROOT"

                if [[ -d "$HOME/Library/Application Support/JetBrains" ]]; then
                  JETBRAINS_PATH="$HOME/Library/Application Support/JetBrains"
                else
                  JETBRAINS_PATH="$HOME/.config/JetBrains"
                fi

                # Find CLion latest path
                IDE_PATH=$(ls -d "$JETBRAINS_PATH"/* | grep -E 'CLion[0-9]+\.[0-9]+' | tail -1)
                echo "IDE_PATH: $IDE_PATH"

                if [[ -f ".idea/zigbrains.xml" ]]; then
                    xmlstarlet ed -L -u '//project/component[@name="ZLSSettings"]/option[@name="zlsPath"]/@value' -v '${zls}/bin/${zlsBinName}' ".idea/zigbrains.xml"
                    xmlstarlet ed -L -u '//project/component[@name="ZigProjectSettings"]/option[@name="toolchainPath"]/@value' -v '${zig}/bin' ".idea/zigbrains.xml"
                    xmlstarlet ed -L -u '//project/component[@name="ZigProjectSettings"]/option[@name="explicitPathToStd"]/@value' -v '${zig}/lib/std' ".idea/zigbrains.xml"
                  else
                    echo "Failed replace paths. File '.idea/zigbrains.xml' not found"
                fi

                if [[ -f "$IDE_PATH/options/mac/embedded-support.xml" ]]; then
                    echo "Replace openocd path"
                    xmlstarlet ed -L -u '//application/component[@name="EmbeddedDevelopment"]/option[@name="openOcdLocation"]/@value' -v '${minichlink-ocd}/bin/minichlink-ocd' "$IDE_PATH/options/mac/embedded-support.xml"
                  else
                    echo "Failed replace openocd path. File '$IDE_PATH/options/mac/embedded-support.xml' not found"
                fi

                exit 0
              ''
            ];
          };

          dsview = pkgs.mkShell {
            shellHook =
              pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
                open ${pkgs.dsview}/Applications/DSView.app
              ''
              + pkgs.lib.optionalString pkgs.stdenv.isLinux ''
                ${pkgs.dsview}/bin/dsview
              ''
              + ''
                exit 0
              '';
          };
        };

        # run: `nix fmt`
        formatter = treefmtEval.config.build.wrapper;
      }
    );
}
