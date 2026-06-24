{
  description = "Your new nix config";

   nixConfig = {
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      # "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-2605.url = "github:nixos/nixpkgs/nixos-26.05";

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-2605 = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-2605";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin-2605 = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-2605";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    # 统一管理所有的 Overlay
    overlays = [
      (final: prev:
        let
          isLinux = prev.stdenv.hostPlatform.isLinux;
          localPkgs = import ./pkgs prev;

          # Linux 专属包和重载
          linuxOverlays = {
            ags = if inputs.ags.packages ? ${prev.stdenv.hostPlatform.system}
                  then inputs.ags.packages.${prev.stdenv.hostPlatform.system}.default
                  else prev.ags or null;
            inherit (localPkgs) lunar-javascript wechat tproxy;
            joker = prev.joker.overrideAttrs (oldAttrs: {
              # 强制 Go 使用代理下载依赖，而不是信任本地 vendor 目录
              proxyVendor = true;
              vendorHash = "sha256-4wPiuX3SsLAkvKevptgVAKdg7MR2QdouqiB+FKqdZPM=";
            });
          };

          # 跨平台通用包和重载
          commonOverlays = {
            inherit (localPkgs) t;
          };
        in
        commonOverlays // (if isLinux then linuxOverlays else {})
      )
    ];
  in
  {
    # 命令行直接使用的包 (nix build .#xxx)
    packages = {};

    nixosConfigurations = {
      inspiron-lin = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./platforms/nixos/configuration.nix

          # 直接引用上面定义的统一 Overlay
          { nixpkgs.overlays = overlays; }

          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.lin = {
              imports = [
                ./home/nixos
                inputs.catppuccin.homeModules.catppuccin
                inputs.ags.homeManagerModules.default
              ];
            };
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };

    darwinConfigurations = {
      fcdeMac-mini = inputs.darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [

          ./platforms/darwin/configuration.nix
          ./hosts/fcdeMac-mini

          # 直接引用上面定义的统一 Overlay
          { nixpkgs.overlays = overlays; }

          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "before-nix";
            home-manager.users.lin = {
              imports = [
                ./home/darwin
                inputs.catppuccin.homeModules.catppuccin
              ];
            };
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
      lindeMacBook-Pro = inputs.darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./platforms/darwin/configuration.nix
          ./hosts/lindeMacBook-Pro

          # 直接引用上面定义的统一 Overlay
          { nixpkgs.overlays = overlays; }

          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "before-nix";
            home-manager.users.lin = {
              imports = [
                ./home/darwin
                ./hosts/lindeMacBook-Pro/home.nix
                inputs.catppuccin.homeModules.catppuccin
              ];
            };
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };

      lins-iMac = inputs.darwin-2605.lib.darwinSystem {
        specialArgs = {
          inputs = inputs // {
            nixpkgs = inputs.nixpkgs-2605;
            home-manager = inputs.home-manager-2605;
            darwin = inputs.darwin-2605;
          };
        };
        modules = [
          ({ lib, ... }: {
            _module.args.pkgs = lib.mkForce (import inputs.nixpkgs-2605 {
              system = "x86_64-darwin";
              config.allowUnfree = true;
              overlays = overlays;
            });
          })
          ./platforms/darwin/configuration.nix
          ./hosts/lins-iMac

          # 直接引用上面定义的统一 Overlay
          { nixpkgs.overlays = overlays; }

          inputs.home-manager-2605.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "before-nix";
            home-manager.users.lin = {
              imports = [
                ./home/darwin
                inputs.catppuccin.homeModules.catppuccin
              ];
            };
            home-manager.extraSpecialArgs = {
              inputs = inputs // {
                nixpkgs = inputs.nixpkgs-2605;
                home-manager = inputs.home-manager-2605;
                darwin = inputs.darwin-2605;
              };
            };
          }
        ];
      };

    };
  };
}
