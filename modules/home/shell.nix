{ config, pkgs, lib, ... }:

{
  # ============ ZSH ============
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  # ============ STARSHIP (prompt Tokyo Night) ============
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = lib.concatStrings [
        "$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character"
      ];
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  # ============ DIRENV ============
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  # ============ ZOXIDE (cd inteligente) ============
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # ============ ALIASES ============
  home.shellAliases = {
    ls = "eza --icons";
    ll = "eza --icons -l";
    la = "eza --icons -la";
    cat = "bat --paging=never";
    grep = "rg";
    find = "fd";
    vim = "nvim";
    vi = "nvim";
    g = "git";
    lg = "lazygit";
  };
}
