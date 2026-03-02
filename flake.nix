{
  description = "Bifrost – rune (issue) management system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Shared vendor hash for the Go workspace dependencies.
        # Update by setting to lib.fakeHash, building, and using the correct hash from the error.
        workspaceVendorHash = "sha256-IWpy8r2EO+267Dm+Ne7CaUu45wprEUrOKR3S0HrkhAE=";

        # Helper to build a Go workspace package.
        buildWorkspacePackage = { pname, subPackages, ldflags ? [ "-s" "-w" ], ... }@args:
          pkgs.buildGoModule (builtins.removeAttrs args [ ] // {
            inherit pname subPackages ldflags;
            version = "0.0.0-dev";
            src = ./.;
            vendorHash = workspaceVendorHash;

            overrideModAttrs = _prev: {
              # Replace the entire build phase to use `go work vendor`
              # instead of `go mod vendor` for Go workspace support.
              buildPhase = ''
                runHook preBuild
                go work vendor
                mkdir -p vendor
                runHook postBuild
              '';
            };

            # Ensure the build phase uses GOWORK.
            preBuild = ''
              export GOWORK="$PWD/go.work"
            '';
          });
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            go
            gopls
            gotools
            delve
            golangci-lint
            gcc
            gnumake
          ];

          shellHook = ''
            export GOWORK="$PWD/go.work"
          '';
        };

        packages = rec {
          bifrost-server = buildWorkspacePackage {
            pname = "bifrost-server";
            subPackages = [ "server/cmd" ];

            postInstall = ''
              mv $out/bin/cmd $out/bin/bifrost-server
            '';
          };

          bf = buildWorkspacePackage {
            pname = "bf";
            subPackages = [ "cli/cmd/bf" ];

            postInstall = ''
              ln -s $out/bin/bf $out/bin/bifrost
            '';
          };

          default = bf;
        };
      });
}
