# Nix / NixOS desde cero (para leer esta configuración)

Este archivo no es configuración: es una **chuleta** para que entiendas lo que
lees en los demás archivos aunque nunca hayas visto Nix.

---

## 1. Lo más básico: la sintaxis

Nix es un **lenguaje de programación** (funcional, declarativo). Estos son los
únicos elementos que necesitas reconocer:

### Atributos y conjuntos (attribute sets)
```nix
{
  nombre = "valor";
  numero = 42;
  activo = true;
}
```
Un `{ ... }` es un **conjunto de pares `clave = valor;`** (como un diccionario).
Ojo: **cada línea termina en `;`** (punto y coma), y los pares van separados por
ese `;`.

### Listas
```nix
[ "uno" "dos" "tres" ]
```
Van entre `[ ]` y **sin comas**. Cada elemento va separado por espacio o salto de
línea.

### Cadenas de texto
```nix
"hola"
''
  texto
  de varias líneas
''
```
- `"..."` es una cadena normal (una línea).
- `''...''` es una cadena de **varias líneas** (se usa mucho para scripts).
- Dentro de una cadena, `${algo}` **inserta** el valor de `algo`. Ejemplo:
  `"mi usuario es ${usuario}"`.

> ⚠️ Si quieres escribir `${` **literal** (sin que Nix lo interprete), en una
> cadena `''...''` se escribe `''${`. Verás esto en la config de Lua de Neovim.

### Comentarios
```nix
# Esto es un comentario de una línea

/* Esto es un comentario
   de varias líneas */
```

### `with`
```nix
with pkgs; [ firefox git ]
```
`with pkgs;` significa: "busca los nombres que vengan después dentro de `pkgs`".
Así `firefox` se convierte en `pkgs.firefox`.

---

## 2. Qué es un "módulo"

Casi todos los archivos de esta config son **módulos**. Un módulo es un archivo
que empieza así:

```nix
{ config, pkgs, lib, ... }:
{
  # ... ajustes ...
}
```

Léelo así:

- `{ config, pkgs, lib, ... }:` → "este módulo **recibe** cuatro cosas y
  devuelve el bloque de abajo".
  - `config`: el estado **actual** de la configuración (lo que ya está definido).
  - `pkgs`: el **catálogo de paquetes** de NixOS (aquí vive `firefox`, `git`,
    `vscode`...).
  - `lib`: **utilidades** para escribir configuración (`lib.mkDefault`,
    `lib.mkIf`, etc.).
  - `...`: "puede recibir más cosas que no uso".

Dentro del bloque de abajo escribes **opciones** (cosas que quieres configurar).
Por ejemplo:

```nix
{ config, pkgs, lib, ... }:
{
  services.desktopManager.cosmic.enable = true;   # activa el escritorio COSMIC
  environment.systemPackages = [ pkgs.firefox ];  # instala Firefox
}
```

La gracia de NixOS: **tú describes el estado final** ("quiero COSMIC y
Firefox"), y NixOS calcula *cómo* llegar ahí. No hay pasos manuales.

---

## 3. Opciones importantes de `lib`

NixOS tiene miles de opciones ya definidas. Algunas utilidades al configurarlas:

### `lib.mkDefault`
```nix
services.pipewire.enable = lib.mkDefault true;
```
Significa: "ponlo a `true` **por defecto**, pero si otro archivo (tu
configuración principal) lo pone a otra cosa, gana el otro". Se usa en módulos
que se importan dentro de configuraciones ajenas, para **no pisar** decisiones
del usuario.

### `lib.mkIf`
```nix
config = lib.mkIf config.programs.nixarchy.enable {
  # solo se aplica si programs.nixarchy.enable es true
};
```

### `lib.mkEnableOption`
```nix
options.programs.mi-programa.enable = lib.mkEnableOption "mi programa";
```
Crea una opción `enable` (true/false) que por defecto es `false`. Es la forma
estándar de hacer que un módulo se pueda activar/desactivar.

### `lib.mkOption`
Define una opción nueva con su **tipo** y su **valor por defecto**:
```nix
options.programs.nixarchy.flake = lib.mkOption {
  type = lib.types.str;      # es un texto
  default = "/etc/nixos";    # valor si nadie lo cambia
};
```

### `lib.optional`
```nix
lib.optional condicion ./archivo.nix
```
Devuelve `[ ./archivo.nix ]` si la condición es true, o `[ ]` (lista vacía) si
es false. Sirve para **importar algo solo a veces**.

---

## 4. `imports`: componer módulos

Un módulo puede **incluir otros módulos**:
```nix
{
  imports = [
    ./otro-archivo.nix
    ./y-otro-mas.nix
  ];
}
```
Es como hacer un "include": todas esas piezas se suman.

---

## 5. Qué es un "flake"

Un **flake** es un archivo `flake.nix` que define **de dónde salen las cosas**
(inputs) y **qué se construye** (outputs). Es lo que permite que tu
configuración sea 100% reproducible: fija versiones exactas.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.mi-maquina = ...;
    nixosModules.algo = ...;
  };
}
```

- **inputs**: repositorios (nixpkgs, home-manager, etc.). `inputs.nixpkgs.follows
  = "nixpkgs"` significa "usa la MISMA versión de nixpkgs que el flake padre"
  (evita descargar dos copias).
- **outputs**: lo que este flake ofrece a otros. Aquí ofrecemos **módulos**
  (`nixosModules.nixarchy`) para que otra configuración los importe, igual que
  hace nixarchy.

---

## 6. NixOS vs Home Manager

- **NixOS** configura el **sistema**: kernel, escritorio, servicios, drivers.
- **Home Manager (HM)** configura tu **usuario**: programas, dotfiles
  (`~/.config/...`), shell, editor...

En esta config:

- `modules/nixos.nix` → cosas del sistema (COSMIC, drivers, dev tools).
- `modules/home.nix` → cosas de tu usuario (Neovim, Ghostty, Zen...).

---

## 7. ¿Cómo se "aplica" todo esto?

```bash
sudo nixos-rebuild switch --flake /etc/nixos#macnix
```

- `nixos-rebuild switch`: construye y activa la configuración.
- `--flake /etc/nixos#macnix`: usa el flake de `/etc/nixos`, salida `macnix`.

Si algo falla, `nixos-rebuild --rollback` vuelve a la generación anterior.
