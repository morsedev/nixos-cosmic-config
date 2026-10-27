# NixOS para MacBook Air M2 (Apple Silicon)

Configuración **custom** de NixOS para Apple Silicon con:

- **COSMIC** (escritorio Rust/Wayland) con **tiling** integrado (Super+T alterna tiling↔floating)
- **Neovim (NixVim)** como IDE completo, estilo *kickstart*:
  - LSP: Rust, Nix, Flutter/Dart, Python, TypeScript, Lua, C/C++
  - **DAP UI** con breakpoints (F5/F10/F11/F12, `<leader>b`)
  - Telescope (buscar archivos/texto), Neo-tree (árbol de archivos), cmp (autocompletado)
  - Formateo con `<leader>f`
- **Theming homogéneo** con **Stylix** + **Tokyo Night** (GTK, Qt, terminal, navegador, fuentes, cursores)
- **Zen Browser**, **Ghostty** (terminal), **Yazi** (TUI) + **Nautilus** (GUI)
- Toolchain de desarrollo: Rust, Flutter/Dart, Python, Node/TS, C/C++, Docker, git, etc.
- **GitHub Action** que valida que todo evalúa (y compila, bajo demanda) en un runner ARM64

> ⚠️ **Swift**: `pkgs.swift` está marcado *broken* en `aarch64-linux` en nixpkgs.
> Para Swift, instala el toolchain oficial de [swift.org](https://www.swift.org/install/linux/)
> (tarball ARM64) o usa un contenedor. Ver [Swift](#swift).

---

## Requisitos

- MacBook Air M2 (o similar) con el **entorno UEFI de Asahi ya instalado**
  (pasos previos: instalador de Asahi → UEFI only → modo permissive).
- NixOS ya instalado y funcionando.

## Cómo usarlo en tu Mac

El repo es la configuración *excepto* los archivos propios de tu máquina:
`hardware-configuration.nix` y `vendorfw/`.

### 1. Clona el repo

```bash
sudo git clone https://github.com/morsedev/nixos-cosmic-config.git ~/nixos-cosmic-config
```

### 2. Copia la configuración a `/etc/nixos` **sin pisar** tus archivos de máquina

```bash
# Haz backup de tu config actual
sudo cp -r /etc/nixos /etc/nixos.bak

# Copia flake + configuración + módulos
sudo cp ~/nixos-cosmic-config/flake.nix        /etc/nixos/
sudo cp ~/nixos-cosmic-config/configuration.nix /etc/nixos/
sudo rm -rf /etc/nixos/modules
sudo cp -r ~/nixos-cosmic-config/modules       /etc/nixos/
```

**IMPORTANTE**: **NO** copies `hardware-configuration.nix` del repo (es un stub
para CI). Debes **conservar el tuyo**, generado por el instalador. Tampoco borres
tu carpeta `vendorfw/` (firmware del ESP).

### 3. Ajusta tus datos

En `configuration.nix` / `modules/system.nix`:
- `networking.hostName` (por defecto `macnix`)
- `users.users.macnix` (cambia el usuario si quieres)
- Zona horaria (`time.timeZone`) y locale
- Red WiFi en `modules/system.nix` (descomenta y pon tu SSID/contraseña)

### 4. Build

```bash
cd /etc/nixos
sudo nixos-rebuild switch --flake .#macnix
```

> La primera vez tarda bastante (compila COSMIC, nixvim, etc.). Si tienes 8 GB
> de RAM, ya hay `max-jobs = 1` y `zramSwap` para evitar OOM.

### 5. Reinicia y elige COSMIC

```bash
sudo reboot
```

En el greeter elige la sesión **COSMIC**.

---

## Estructura

```
flake.nix                 # inputs: nixpkgs, home-manager, stylix, zen-browser, nixvim, apple-silicon
configuration.nix         # sistema: Apple Silicon, boot, red, nix, swap, memoria
modules/
  system.nix              # red, audio (pipewire), bluetooth, usuarios, locale
  cosmic.nix              # COSMIC + tiling + fuentes + apps GUI
  development.nix         # toolchains (rust, flutter/dart, python, node, c/c++, docker...)
  users.nix               # Home Manager del usuario
  stylix.nix              # theming Tokyo Night
  home/
    nvim.nix              # NixVim (IDE kickstart-style)
    terminal.nix          # Ghostty + Yazi
    shell.nix             # zsh + starship + zoxide + direnv + aliases
    browser.nix           # Zen Browser
    files.nix             # Nautilus
    themes.nix            # cursor
hardware-configuration.nix  # stub SOLO para CI (no usar en el Mac)
```

---

## Swift

`pkgs.swift` no evalúa en `aarch64-linux` (marcado *broken* en nixpkgs). Opciones:

1. **Toolchain oficial** (recomendado):
   ```bash
   # Descarga el tarball ARM64 de swift.org, descomprime en ~/swift
   export PATH="$HOME/swift/usr/bin:$PATH"
   # SourceKit-LSP viene incluido: ~/swift/usr/bin/sourcekit-lsp
   ```
   Luego añade `sourcekit` a NixVim:
   ```nix
   plugins.lsp.servers.sourcekit = {
     enable = true;
     package = null;          # usar el del PATH
   };
   ```

2. **Contenedor**: usa un `distrobox`/`podman` con la imagen oficial de Swift.

---

## CI (GitHub Actions)

- **En cada push**: job `eval` → `nix build --dry-run` (valida que todo evalúa para aarch64-linux).
- **Manual** (`Actions → Run workflow`): job `build` → compila el sistema completo.

Esto verifica antes de tocar el Mac. El runner es `ubuntu-24.04-arm` (ARM64 nativo).

---

## Actualizar

```bash
cd /etc/nixos
sudo nix flake update
sudo nixos-rebuild switch --flake .#macnix
```
