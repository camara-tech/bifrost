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
          bifrost-server = pkgs.buildGoModule {
            pname = "bifrost-server";
            version = "0.0.0-dev";
            src = ./.;
            subPackages = [ "server/cmd" ];
            vendorHash = null;
            pwd = ./.;

            ldflags = [ "-s" "-w" ];

            postInstall = ''
              mv $out/bin/cmd $out/bin/bifrost-server
            '';
          };

          bf = pkgs.buildGoModule {
            pname = "bf";
            version = "0.0.0-dev";
            src = ./.;
            subPackages = [ "cli/cmd/bf" ];
            vendorHash = null;
            pwd = ./.;

            ldflags = [ "-s" "-w" ];

            postInstall = ''
              ln -s $out/bin/bf $out/bin/bifrost
            '';
          };

          default = bf;
        };
      });
}
