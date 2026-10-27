# =====================================================================
# MÓDULO Home Manager (homeManagerModules.nixarchy / homeModules.nixarchy)
# Se importa en el usuario:
#   home-manager.users.<tu-usuario> = {
#     imports = [ nixarchy.homeModules.nixarchy ];
#     programs.nixarchy.enable = true;
#   };
# =====================================================================
inputs:
{ config, lib, pkgs, ... }:

{
  imports = [
    (import ./home/nvim.nix { inherit inputs; })
    (import ./home/browser.nix { inherit inputs; })
    ./home/terminal.nix
    ./home/files.nix
    ./home/shell.nix
    ./home/themes.nix
  ];

  options.programs.nixarchy.enable = lib.mkEnableOption "perfil Home Manager (IDE, terminal, apps)";
}
