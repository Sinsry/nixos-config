{
  description = "Configuration NixOS de maousse";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
  };
};
  outputs = { self, nixpkgs, home-manager, plasma-manager }: {
    nixosConfigurations.maousse = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.sinsry = {

            imports = [ plasma-manager.homeModules.plasma-manager ];

            home.stateVersion = "25.11";
            home.file.".face.icon".source = ./asset/sinsry/Gruul.png;
            home.file.".config/MangoHud/MangoHud.conf".source = ./asset/sinsry/MangoHud.conf;
            home.file.".inputrc".text = ''
            # Complétion insensible à la casse
            set completion-ignore-case on

            # Affiche toutes les possibilités si ambiguë
            set show-all-if-ambiguous on

            # Complétion partielle insensible à la casse
            set completion-map-case on
            '';

            programs.bash = {
              enable = true;
              initExtra = ''
              fastfetch
             '';
                };

            programs.plasma = {
              enable = true;
              input.keyboard.numlockOnStartup = "on";
              workspace = {
                lookAndFeel = "org.kde.breezedark.desktop";
                colorScheme = "BreezeDark";
                theme = "breeze-dark";
                iconTheme = "Papirus-Dark";
                cursor.theme = "breeze_cursors";
                wallpaper = "/etc/nixos/asset/sinsry/diabloIII.png";


              };

              # Désactiver le retour de lancement
              configFile = {
                "klaunchrc"."BusyCursorSettings"."Bouncing" = false;
                "klaunchrc"."FeedbackStyle"."BusyCursor" = false;
              };
              };
            };
          }
        ];
     };
   };
}
