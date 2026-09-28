{
  description = "Personal website for Morten Brun";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems =
        function: nixpkgs.lib.genAttrs systems (system: function (import nixpkgs { inherit system; }));
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          quartoVersion = "1.10.18";

          quartoPlatform =
            if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then
              {
                archive = "linux-amd64";
                toolArch = "x86_64";
                hash = "sha256-r60HG1vSLALy0wBpV0MYnTZQ4FN6Uwc+ZUtjDP8rDHM=";
              }
            else if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then
              {
                archive = "linux-arm64";
                toolArch = "aarch64";
                hash = "sha256-9qB99o4lMwtd809l099mvKYFrM47gwxZOljpGITUz2w=";
              }
            else if pkgs.stdenv.hostPlatform.system == "x86_64-darwin" then
              {
                archive = "macos";
                toolArch = "x86_64";
                hash = "sha256-3danGp4ESKsV+2VbxYnhHLZYmiSOw1zNf39EE3UxaI4=";
              }
            else if pkgs.stdenv.hostPlatform.system == "aarch64-darwin" then
              {
                archive = "macos";
                toolArch = "aarch64";
                hash = "sha256-3danGp4ESKsV+2VbxYnhHLZYmiSOw1zNf39EE3UxaI4=";
              }
            else
              throw "Unsupported system for the pinned Quarto bundle: ${pkgs.stdenv.hostPlatform.system}";

          quartoUpstream = pkgs.stdenv.mkDerivation {
            pname = "quarto-upstream";
            version = quartoVersion;

            src = pkgs.fetchurl {
              url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${quartoVersion}/quarto-${quartoVersion}-${quartoPlatform.archive}.tar.gz";
              inherit (quartoPlatform) hash;
            };

            sourceRoot =
              if pkgs.stdenv.hostPlatform.isDarwin
              then "."
              else "quarto-${quartoVersion}";

            nativeBuildInputs =
              [
                pkgs.makeWrapper
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                pkgs.autoPatchelfHook
              ];

            buildInputs =
              [
                pkgs.bashNonInteractive
              ]
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                pkgs.stdenv.cc.cc.libgcc
              ];

            dontConfigure = true;
            dontBuild = true;
            dontStrip = true;

            installPhase = ''
              runHook preInstall

              mkdir -p "$out"
              cp -R bin share "$out/"

              ln -s "$out/bin/tools/${quartoPlatform.toolArch}/pandoc" "$out/bin/pandoc"

              wrapProgram "$out/bin/quarto" \
                --suffix PATH : ${
                  pkgs.lib.makeBinPath [
                    pkgs.coreutils
                    pkgs.which
                  ]
                }

              runHook postInstall
            '';
          };
        in
        {
          default = pkgs.mkShell {
            packages = [
              quartoUpstream
            ];
          };
        }
      );
    };
}
