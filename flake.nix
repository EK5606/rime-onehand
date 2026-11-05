{
  description = "Rime 单手笔顺输入法（rime-onehand）";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs systems
          (system: f nixpkgs.legacyPackages.${system});

      version = "3.1-${self.shortRev or "dirty"}";
    in
    {
      packages = forAllSystems (pkgs:
        let
          rime-onehand = pkgs.callPackage ./nix/package.nix {
            inherit version;
          };
        in
        {
          inherit rime-onehand;
          default = rime-onehand;
        });

      overlays.default = final: prev: {
        rime-onehand = final.callPackage ./nix/package.nix {
          inherit version;
        };
      };
    };
}
