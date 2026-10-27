# =============================================================================
# modules/home/shell.nix  —  Shell (zsh), prompt y comodidades
# =============================================================================
#
# Aquí se configura la terminal "de verdad": el intérprete de comandos (zsh),
# el prompt (starship) y utilidades que mejoran la experiencia.
# =============================================================================

{ config, pkgs, lib, ... }:

{
  # ---------------------------------------------------------------------------
  # ZSH
  # ---------------------------------------------------------------------------
  # zsh es un shell más potente que bash.
  programs.zsh = {
    enable = true;
    enableCompletion = true;         # autocompletado al pulsar Tab
    autosuggestion.enable = true;    # sugiere comandos mientras escribes
    syntaxHighlighting.enable = true;# colorea los comandos mientras escribes
  };

  # ---------------------------------------------------------------------------
  # STARSHIP (prompt)
  # ---------------------------------------------------------------------------
  # El "prompt" es la línea donde escribes, con info (carpeta, rama git...).
  programs.starship = {
    enable = true;
    enableZshIntegration = true;     # se activa dentro de zsh

    settings = {
      # `lib.concatStrings [ ... ]` junta varios textos en uno.
      # Cada `$algo` es un "módulo" de starship:
      #   $directory    → carpeta actual
      #   $git_branch   → rama de git
      #   $git_status   → estado de git
      #   $nix_shell    → si estás en un shell de Nix
      #   $cmd_duration → cuánto tardó el último comando
      #   $line_break   → salto de línea
      #   $character    → el símbolo del prompt
      format = lib.concatStrings [
        "$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character"
      ];

      character = {
        success_symbol = "[❯](bold green)";  # prompt normal (verde)
        error_symbol = "[❯](bold red)";      # prompt si el comando falló (rojo)
      };
    };
  };

  # ---------------------------------------------------------------------------
  # DIRENV
  # ---------------------------------------------------------------------------
  # Carga automáticamente entornos por carpeta (por ejemplo, un proyecto Nix
  # con sus dependencias) al entrar en la carpeta.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;        # integración óptima con Nix
    enableZshIntegration = true;
  };

  # ---------------------------------------------------------------------------
  # ZOXIDE
  # ---------------------------------------------------------------------------
  # `z nombre-carpeta` te lleva a una carpeta que ya visitaste antes
  # (recuerda tus destinos frecuentes), sin escribir la ruta completa.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # ---------------------------------------------------------------------------
  # ALIASES (atajos de comandos)
  # ---------------------------------------------------------------------------
  # `home.shellAliases` = "cuando escriba X, ejecuta Y".
  home.shellAliases = {
    ls = "eza --icons";          # ls con iconos
    ll = "eza --icons -l";       # ls en lista larga
    la = "eza --icons -la";      # ls incluyendo ocultos
    cat = "bat --paging=never";  # cat con colores y sin paginar
    grep = "rg";                 # grep → ripgrep (más rápido)
    find = "fd";                 # find → fd (más rápido)
    vim = "nvim";                # vim → neovim
    vi = "nvim";
    g = "git";                   # atajo de git
    lg = "lazygit";              # atajo de lazygit
  };
}
