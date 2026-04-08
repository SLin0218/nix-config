{
  description = "Your new nix config";

   nixConfig = {
    # override the default substituters
    substituters = [
      # "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      # "https://mirrors.cernet.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
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
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    catppuccin,
    agenix,
    ags,
    ...
  } @ inputs: let
    inherit (self) packages;
    systems = [
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    # 统一管理所有的 Overlay
    overlays = [
      (final: prev: {
        # 1. 注入最新的 AGS
        ags = inputs.ags.packages.${prev.stdenv.hostPlatform.system}.default;
      } // (import ./pkgs prev)) # 2. 注入本地自定义包
    ];
  in
  {
    # 命令行直接使用的包 (nix build .#xxx)
    packages = forAllSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system overlays; # 这里应用统一的 Overlay
          config.allowUnfree = true;
        };
      in
      # 导出本地包 + AGS，让命令行也能直接 build
      (import ./pkgs pkgs) // { inherit (pkgs) ags; }
    );

    nixosConfigurations = {
      inspiron-lin = nixpkgs.lib.nixosSystem {

        specialArgs = {inherit inputs;};
        modules = [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
          catppuccin.nixosModules.catppuccin
          agenix.nixosModules.default
          ./nixos/configuration.nix

          # 直接引用上面定义的统一 Overlay
          { nixpkgs.overlays = overlays; }

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.lin = {
              imports = [
                ./home/home.nix
                catppuccin.homeModules.catppuccin
                inputs.walker.homeManagerModules.default
                ags.homeManagerModules.default
              ];
            };
            home-manager.extraSpecialArgs = { inherit inputs; };
          }
        ];
      };
    };
  };
}
