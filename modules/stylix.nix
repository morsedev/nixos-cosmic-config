{ config, pkgs, lib, ... }:

{
  # ============ STYLIX — THEMING HOMOGÉNEO ============
  # Un solo esquema de color (Tokyo Night) aplicado a: GTK, Qt, terminal,
  # navegador, nvim, consola, etc.
  stylix = {
    enable = true;

    # Esquema base16 Tokyo Night
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
    polarity = "dark";

    # Fuentes del sistema
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.override { fonts = [ "JetBrainsMono" ]; };
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = 13;
        applications = 11;
        desktop = 11;
        popups = 11;
      };
    };

    # Targets: qué apps temar automáticamente
    targets = {
      gtk.enable = true;
      qt.enable = true;
      # Ghostty y Zen se teman vía sus módulos HM (siguen el esquema de Stylix)
    };
  };
}
