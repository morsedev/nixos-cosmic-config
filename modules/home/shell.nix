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
    # El shell de login de esta máquina es bash (no zsh), así que también
    # activamos el prompt ahí. Si algún día cambias el shell a zsh, sigue igual.
    enableBashIntegration = true;

    settings = {
      # -------------------------------------------------------------------
      # PALETA TOKYO NIGHT
      # -------------------------------------------------------------------
      # Definimos nombres de color y luego los usamos como "fg:blue", etc.
      palettes.tokyo-night = {
        blue = "#7aa2f7";
        purple = "#bb9af7";
        cyan = "#7dcfff";
        green = "#9ece6a";
        yellow = "#e0af68";
        red = "#f7768e";
        fg = "#c0caf5";
        comment = "#565f89";
      };
      palette = "tokyo-night";
      add_newline = true;

      # -------------------------------------------------------------------
      # FORMATO DEL PROMPT (dos líneas)
      # -------------------------------------------------------------------
      # Primera línea: carpeta, rama de git, estado, entorno Nix... y la hora
      # pegada a la derecha ($fill rellena el hueco).
      # Segunda línea: el símbolo ❯ donde escribes.
      #
      # `lib.concatStrings [ ... ]` junta todos los trozos en un solo texto.
      format = lib.concatStrings [
        "$directory"
        "$git_branch"
        "$git_status"
        "$nix_shell"
        "$cmd_duration"
        "$fill"
        "$time"
        "$line_break"
        "$character"
      ];

      # Carpeta actual (azul, en negrita)
      directory = {
        style = "fg:blue bold";
        format = "[$path]($style)";
        truncation_length = 3;     # recorta rutas muy largas
        truncate_to_repo = true;   # dentro de un repo muestra desde la raíz
      };

      # Rama de git (morado) y estado (amarillo)
      git_branch = {
        style = "fg:purple";
        format = "[ $branch]($style)";
      };
      git_status = {
        style = "fg:yellow";
        format = "([$all_status$ahead_behind]($style) )";
      };

      # Entorno de Nix (cian) cuando estás dentro de un `nix develop`
      nix_shell = {
        style = "fg:cyan";
        format = "[ $state]($style)";
      };

      # Duración del último comando (solo si tarda más de 2s)
      cmd_duration = {
        min_time = 2000;
        style = "fg:comment";
        format = "[ $duration]($style)";
      };

      # Hora a la derecha de la primera línea (gris discreto)
      time = {
        disabled = false;
        time_format = "%H:%M";
        style = "fg:comment";
        format = "[$time]($style)";
      };

      # Espacios que se estiran hasta el borde derecho
      fill.symbol = " ";

      # El símbolo final: verde si todo fue bien, rojo si el comando falló
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold purple)";
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
