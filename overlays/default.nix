{ inputs }:

[
  (final: prev:
    let
      isLinux = prev.stdenv.hostPlatform.isLinux;
      localPkgs = import ../pkgs prev;

      # Linux 专属包和重载
      linuxOverlays = {
        ags = if inputs.ags.packages ? ${prev.stdenv.hostPlatform.system}
              then inputs.ags.packages.${prev.stdenv.hostPlatform.system}.default
              else prev.ags or null;
        inherit (localPkgs) lunar-javascript wechat tproxy;
        joker = prev.joker.overrideAttrs (oldAttrs: {
          proxyVendor = true;
          vendorHash = "sha256-4wPiuX3SsLAkvKevptgVAKdg7MR2QdouqiB+FKqdZPM=";
        });
      };

      # 跨平台通用包和重载
      commonOverlays = {
        inherit (localPkgs) t;
        jetbrains = prev.jetbrains // {
          idea = prev.jetbrains.idea.overrideAttrs (oldAttrs: rec {
            version = "2024.2.6";
            src = prev.fetchurl (
              let
                system = prev.stdenv.hostPlatform.system;
                urls = {
                  x86_64-linux = {
                    url = "https://download.jetbrains.com/idea/ideaIU-${version}.tar.gz";
                    sha256 = "018cbeaa80ef9269f6de76671ba46ca02abb96cb01a45eb33042235a4db4dffb";
                  };
                  aarch64-linux = {
                    url = "https://download.jetbrains.com/idea/ideaIU-${version}-aarch64.tar.gz";
                    sha256 = "4008197c847581e24bdfa166e6b48d76d1db2a50da367d0b1342d568454361ee";
                  };
                  x86_64-darwin = {
                    url = "https://download.jetbrains.com/idea/ideaIU-${version}.dmg";
                    sha256 = "0d15e3f1b65cbf20ad91b9e883efd0bbc081ce34467861b6943b05e6b7768989";
                  };
                  aarch64-darwin = {
                    url = "https://download.jetbrains.com/idea/ideaIU-${version}-aarch64.dmg";
                    sha256 = "7388bc673bec6920f85c59ef984fce71f19610c98aaf5703d3ae26cbe56b2e10";
                  };
                };
              in
              urls.${system} or (throw "Unsupported system: ${system}")
            );
          });
        };
      };
    in
    commonOverlays // (if isLinux then linuxOverlays else {})
  )
]
