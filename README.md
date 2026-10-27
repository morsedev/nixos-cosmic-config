# NixOS para MacBook Air M2 (Apple Silicon)

Configuración **custom** de NixOS para Apple Silicon, empaquetada **como módulos
al estilo nixarchy**. Incluye:

- **COSMIC** (escritorio Rust/Wayland) con **tiling** integrado (`Super+T`)
- **Neovim (NixVim)** como IDE, estilo *kickstart*:
  - LSP: Rust, Nix, Flutter/Dart, Python, TypeScript, Lua, C/C++
  - **DAP UI** con breakpoints (`F5/F10/F11/F12`, `<leader>b`)
  - Telescope (buscar archivos/texto), Neo-tree (árbol), cmp (autocompletado)
- **Theming homogéneo** con **Stylix** + **Tokyo Night**
- **Zen Browser**, **Ghostty**, **Yazi** + **Nautilus**
- Toolchain: Rust, Flutter/Dart, Python, Node/TS, C/C++, Docker...
- **GitHub Action** que valida que todo evalúa (y compila, bajo demanda) en ARM64

> 📚 **¿No sabes Nix?** Lee [`NIX-PRIMER.md`](NIX-PRIMER.md): explica la sintaxis,
> qué es un módulo, un flake, `mkDefault`, etc. Y **todos los archivos están
> comentados** línea a línea para principiantes.

---

## Usarlo como módulo (como nixarchy) — la forma recomendada

> ⚠️ **REQUISITO IMPORTANTE (Apple Silicon):** el kernel `linux-asahi` y
> `uboot-asahi` se compilan con **el nixpkgs de tu flake**. Debe coincidir con
> la release de `nixos-apple-silicon`. Con `nixos-unstable` actual (dtc 1.8.1)
> U-Boot falla con `unrecognized check name node_name_not_empty`.
> Por eso, en **tu** `/etc/nixos/flake.nix` fija:
> ```nix
> nixpkgs.url = "github:nixos/nixpkgs/e2587caef70cea85dd97d7daab492899902dbf5d";
> ```
> (es el mismo rev que tu ISO y que la release de Asahi). Luego:
> `sudo nix flake update nixpkgs`.

Tu `/etc/nixos/flake.nix` (el que ya tienes) solo cambia **una línea**:

```nix
inputs.nixarchy.url = "github:morsedev/nixos-cosmic-config";
```

Y el resto se queda igual:

```nix
modules = [
  ./configuration.nix                      # tu hardware, apple-silicon, red...
  nixarchy.nixosModules.nixarchy           # ← módulo de sistema (COSMIC, dev, stylix)
  home-manager.nixosModules.home-manager
  {
    hooks... = ...;
    home-manager.users.macnix = {
      imports = [ nixarchy.homeModules.nixarchy ];   # ← módulo de usuario
      programs.nixarchy.enable = true;
    };
  }
];
```

> El módulo de Home Manager también está expuesto como
> `nixarchy.homeManagerModules.nixarchy` por compatibilidad.

**Tu `configuration.nix` debe seguir aportando** lo específico de la máquina:
`hardware.asahi.enable`, `boot.loader`, el usuario, `networking.networkmanager`
y la importación del soporte Apple Silicon (`./apple-silicon-support` o el input).

Luego:

```bash
cd /etc/nixos
sudo nixos-rebuild switch --flake .#tu-hostname
```

### Qué aporta cada módulo

| Módulo | Contenido |
|---|---|
| `nixosModules.nixarchy` | Stylix, COSMIC + greeter, audio/bluetooth/fuentes, herramientas de desarrollo |
| `homeModules.nixarchy` | NixVim, Ghostty, Yazi, Zen, zsh/starship/zoxide/direnv, cursores |

---

## Usarlo como configuración completa

Si prefieres el sistema entero de este repo (incluye Apple Silicon, red,
usuario...), usa la salida `nixosConfigurations.macnix`:

```bash
sudo git clone https://github.com/morsedev/nixos-cosmic-config.git ~/nixos-cosmic-config
# Copia flake.nix, configuration.nix y modules/ a /etc/nixos
# ⚠️ CONSERVA tu hardware-configuration.nix real y tu carpeta vendorfw/
cd /etc/nixos
sudo nixos-rebuild switch --flake .#macnix
```

---

## Estructura

```
flake.nix                   # inputs + outputs (módulos y nixosConfigurations.macnix)
configuration.nix           # lo específico de la máquina (Apple Silicon, boot, red, usuario)
modules/
  nixos.nix                 # nixosModules.nixarchy (perfil de sistema)
  home.nix                  # homeModules.nixarchy (perfil de usuario)
  system-profile.nix        # audio, bluetooth, fuentes, portales (mkDefault)
  cosmic.nix                # escritorio COSMIC + apps GUI
  development.nix           # toolchains y utilidades de dev
  stylix.nix                # tema Tokyo Night
  home/
    nvim.nix                # NixVim (IDE kickstart-style)
    terminal.nix            # Ghostty + Yazi
    shell.nix               # zsh + starship + zoxide + direnv
    browser.nix             # Zen Browser
    files.nix               # Nautilus
    themes.nix              # cursores
hardware-configuration.nix  # stub SOLO para CI (no usar en el Mac)
NIX-PRIMER.md               # explicación de Nix de cero
```

---

## Cachés binarias (no recompilar) y respaldo

### Ya activadas (automático)

El módulo añade estas cachés, así que descarga hechos:

- `cache.nixos.org` → la mayoría de paquetes
- `nix-community.cachix.org` → NixVim, Stylix, Home Manager...
- `cosmic.cachix.org` → escritorio COSMIC

### Lo que NO tiene caché: el kernel/U-Boot de Asahi

El proyecto `nixos-apple-silicon` **no tiene caché binaria oficial** (sus
builders no funcionan). Por eso `linux-asahi` y `uboot-asahi` se compilan en
tu máquina. **La única forma de no recompilarlos es tu propia caché.**

### Tu caché personal (Cachix) — respaldo de todo lo que compilas

1. Crea una caché en <https://app.cachix.org> (ej. `macnix`) y copia su
   **public key**.
2. Autentica el token **como root** (el hook corre como root):
   ```bash
   sudo cachix authtoken <TU_TOKEN>
   ```
3. En `configuration.nix`, descomenta el bloque *CACHÉ PERSONAL* y pon tu
   caché y su clave pública.
4. `sudo nixos-rebuild switch --flake .#TU_HOST`

A partir de ahí, **cada cosa que compile se sube sola** a tu caché. En un
rebuild futuro (o tras limpiar el store), se descarga en vez de compilarse.

**Subir manualmente lo ya compilado** (p. ej. el kernel actual):
```bash
sudo cachix push macnix $(nix-store -qR /run/current-system)
```

> ⚠️ El plan gratuito de Cachix tiene límite de almacenamiento. El kernel +
> U-Boot ocupan del orden de 1–2 GB. Si necesitas más, alternativas sin límite:
> **attic** o **harmonia** autoalojados (p. ej. en tu PC Linux), o simplemente
> **no ejecutar `nix-collect-garbage -d`** para conservar el store.

> 📌 **Nunca** hagas `nix-collect-garbage -d` sin haber subido antes el kernel
> a tu caché: lo perderías y tocaría recompilarlo.

## Swift

`pkgs.swift` está marcado *broken* en `aarch64-linux` en nixpkgs. Instala el
toolchain oficial de [swift.org](https://www.swift.org/install/linux/) (tarball
ARM64) y añade `sourcekit` a NixVim apuntando a ese binario.

---

## CI (GitHub Actions)

- **En cada push**: job `eval` → `nix build --dry-run` (valida la evaluación).
- **Manual** (`Actions → Run workflow`): job `build` → compila el sistema.

Runner: `ubuntu-24.04-arm` (ARM64 nativo).

---

## Actualizar

```bash
cd /etc/nixos
sudo nix flake update
sudo nixos-rebuild switch --flake .#tu-hostname
```
