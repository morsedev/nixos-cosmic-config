{ config, pkgs, lib, inputs, ... }:

{
  home-manager.users.macnix = { pkgs, ... }: {
    imports = [
      # NOTA: Stylix integra su módulo HM automáticamente desde el módulo NixOS
      # (homeManagerIntegration), así que NO lo importamos aquí manualmente.
      ./home/nvim.nix
      ./home/terminal.nix
      ./home/browser.nix
      ./home/files.nix
      ./home/shell.nix
      ./home/themes.nix
    ];

    home = {
      username = "macnix";
      homeDirectory = "/home/macnix";
      stateVersion = "26.11";
    };

    # Paquetes de usuario (todo lo que no necesita ser del sistema)
    home.packages = with pkgs; [
      # CLI moderna
      ripgrep
      fd
      fzf
      zoxide
      bat
      eza
      starship
      btop
      htop
      tree
      jq
      yq
      dust
      procs
      delta           # git diffs bonitos
      tealdeer        # tldr
      glow            # markdown en terminal
      navi            # cheatsheets

      # Dev
      gh
      lazygit
      lazyjj
      direnv
      nix-direnv
      cargo
      rustc
      rust-analyzer

      # Multimedia
      mpv
      imv
      zathura
      obs-studio

      # Utilidades
      wl-clipboard      # portapapeles Wayland
      wf-recorder       # grabar pantalla
      grim              # screenshots
      slurp
      satty            # editor de screenshots
      brightnessctl
      playerctl
      pavucontrol
      networkmanagerapplet
    ];
  };
}
