# Debian 13 Workstation

Setup automatizado de un entorno i3 sobre Debian 13 (Trixie) orientado a bug bounty, CTF y desarrollo. El script es idempotente, modular y gestiona los dotfiles por symlinks, de forma que un solo comando reconstruye la maquina desde cero.

No es un volcado de dotfiles: es un instalador con modulos, listas de paquetes declarativas y gestion de configuracion versionada, pensado para correr en varias maquinas sin romperse.

## Caracteristicas

* Instalacion idempotente: seguro de re-ejecutar, solo hace lo que falta.
* Modular por flags: instala solo lo necesario (`--desktop`, `--security`, `--all`).
* Dotfiles por symlink: los configs viven en el repo; editarlos edita la fuente, sin divergencia.
* Tolerante a fallos: un paquete inexistente o una herramienta que no compila se reportan y se omiten, sin abortar la instalacion.
* Portable: pensado para clonar y desplegar en cualquier Debian 13.

## Entorno de escritorio

i3 con identidad visual propia: **aureola**, una paleta muestreada del wallpaper (`config/wallpapers/angel.jpg`) — base violeta-noche, acentos hielo y rosa. Detalle completo en `docs/tema.md`.

| Componente      | Herramienta                                          |
|-----------------|------------------------------------------------------|
| Window manager  | i3                                                   |
| Barra           | polybar (multi-monitor, indicador VPN, acceso arandr)|
| Compositor      | picom (blur, esquinas redondeadas, animaciones con curva propia) |
| Terminal        | kitty                                                |
| Lanzador        | rofi                                                 |
| Notificaciones  | dunst                                                |
| Shell           | zsh (prompt de dos lineas, autosuggestions, highlighting) |
| Apps GTK        | Adwaita-dark + Papirus-Dark con los colores de la paleta |
| Login           | lightdm-gtk-greeter con el mismo fondo y fuente      |
| Fuentes         | Comfortaa (interfaz) + Maple Mono NF (mono, ligaduras e iconos) |
| Multi-monitor   | autorandr (perfiles y fallback automatico)           |
| Extras          | scratchpad, greenclip, wallpaper (feh), Firefox      |

Los atajos de gestion de ventanas estan en `docs/i3.md`, y `Super+F1` los abre en rofi sin salir del escritorio. La paleta, la tipografia y los glifos de cada workspace estan en `docs/tema.md`.

## Herramientas de seguridad

Set curado, instalado desde cuatro fuentes segun lo optimo para cada herramienta:

* apt: nmap, masscan, sqlmap, nikto, whatweb, gobuster, ffuf, wfuzz, hydra, john, hashcat, binwalk, steghide, foremost, gdb, checksec, socat, proxychains4, smbclient, tmux, openvpn.
* Go (ProjectDiscovery y afines): subfinder, httpx, nuclei, naabu, dnsx, katana, gau, waybackurls, anew, gf, qsreplace, assetfinder, dalfox, amass, gowitness, interactsh-client, greenclip.
* pipx: arjun, dirsearch, wafw00f, uro, enum4linux-ng, pwntools, NetExec.
* Docker: motor mas Kali desechable para el arsenal pesado bajo demanda.

Ademas de los binarios, `--security` instala lo que necesitan para servir: los patrones de `gf` (sin ellos el binario no hace nada), SecLists y `rockyou.txt` extraido en `/usr/share/wordlists/`.

`bb` es el helper de engagement: `bb new acme` crea la estructura del objetivo, y `bb recon`, `bb urls` y `bb scan` encadenan el pipeline filtrando **todo** contra el `scope.txt` del programa. Ver `docs/recon.md`.

Ver `docs/arsenal.md` para el listado completo por fase y `docs/cheatsheet.md` para comandos de uso.

## Desarrollo y packaging Debian

El modulo `--dev` deja la maquina lista para arreglar bugs en paquetes del archivo:

* Kit de packaging: devscripts, debhelper, dh-make, quilt, lintian, licensecheck, sbuild, git-buildpackage, pristine-tar, dgit, patchutils, wdiff, piuparts, autopkgtest, dput-ng, reportbug, how-can-i-help.
* `deb-src` habilitado tanto en el `sources.list` clasico como en las fuentes deb822, sin el cual `apt source` no funciona.
* Dotfiles por symlink: `~/.config/sbuild/config.pl`, `~/.quiltrc-dpkg`, `~/.devscripts`, `~/.gitconfig` y `~/.gbp.conf`.
* Chroot de sbuild de unstable, creado con `mmdebstrap` sobre el backend unshare.
* Identidad derivada de tu clave GPG: `DEBFULLNAME` y `DEBEMAIL` a `~/.zshrc.local`, y nombre, correo y `user.signingkey` a `~/.gitconfig.local`.
* Parches por correo: `git-email` y `b4`, para mandar arreglos upstream y al kernel.
* Toolchain de Rust via rustup, mas las dependencias nativas de compilacion habituales.

Ver `docs/packaging.md` para el flujo completo por fases: elegir el bug, obtener el fuente, reproducir, parchear, validar y enviar.

## Kernel de Linux

El mismo `--dev` deja la maquina lista para construir y parchear el kernel:

* Dependencias de construccion (`packages/kernel.txt`): flex, bison, cabeceras de ncurses/elf/ssl, `bc`, `pahole` (sin el, `CONFIG_DEBUG_INFO_BTF` no enlaza), y clang/llvm/lld para construir con `LLVM=1`.
* Analisis estatico: `sparse` (`make C=1`) y `coccinelle` (`make coccicheck`).
* Neovim con clangd sobre `compile_commands.json`, y `checkpatch.pl` y `get_maintainer.pl` integrados como comandos del editor.

Ver `docs/kernel.md` para el flujo: clonar el arbol correcto, construirlo, generar la base de datos que clangd necesita y revisar el parche antes de mandarlo.

## Editor

Neovim, configurado para leer C del kernel y preparar parches.

* No viene de apt a proposito: Debian 13 congela la 0.10.4 y la configuracion necesita 0.11 o mas por `vim.lsp.config`. `modules/editor.sh` instala el tarball oficial en `~/.local`, con la version fijada en el modulo.
* LSP con la API nativa de Neovim, sin `nvim-lspconfig`: clangd afinado para el kernel (sin insercion de includes, sin clang-tidy, con `--query-driver`), mas lua_ls, bashls y rust-analyzer si estan presentes.
* Comandos propios: `:Checkpatch`, `:Maintainers`, `:CompileCommands`, `:KernelRoot`.
* Estilo del kernel automatico en ficheros C (tabs de 8, `cinoptions` del `coding-style.rst`, marcas en 80 y 100), y ningun formateo al guardar.
* Ocho plugins, fijados por `lazy-lock.json`, que vive en el repo porque `~/.config/nvim` es un enlace al propio repo: mismo commit, mismo editor.
* Tema **aureola**: la paleta del escritorio tambien en el editor.

## Uso

```bash
git clone https://github.com/hw4n1/debian13-configs.git ~/setup
cd ~/setup

./setup.sh --help          # opciones
./setup.sh --desktop       # solo el entorno i3
./setup.sh --security      # solo herramientas de seguridad
./setup.sh --dev           # packaging Debian, kernel, editor y chroot sbuild
./setup.sh --ai            # Claude Desktop y Claude Code
./setup.sh --hardware      # asusctl (portatiles ASUS ROG)
./setup.sh --all           # todo

./setup.sh --doctor        # revisa el estado de la maquina, sin modificar nada
./setup.sh --update        # actualiza herramientas, plantillas y el chroot
```

`--doctor` es la contraparte de la idempotencia: el instalador garantiza que algo quedo hecho, `--doctor` comprueba que sigue hecho. Detecta lo que se degrada solo (plantillas de nuclei viejas, chroot de sid caducado) y lo que instalas pero luego no sirve de nada (el binario de `gf` sin sus patrones). Sale con codigo 1 si encuentra fallos.

No ejecutar como root. El script pide `sudo` solo cuando lo necesita (apt, servicios). Los dotfiles y binarios de usuario se mantienen bajo el usuario normal.

Un paso que falla se reporta y se omite; al terminar, el script lista los pasos omitidos y sale con codigo 1 si hubo alguno.

Tras `--desktop`, cerrar sesion y volver a entrar para aplicar zsh como shell por defecto y el grupo `docker`, y seleccionar la sesion i3 en el login.

La identidad de packaging (`DEBFULLNAME`, `DEBEMAIL`) no esta versionada: `--dev` la deriva de tu clave GPG y la escribe en `~/.zshrc.local`. Si no tienes clave, copia `config/zsh/zshrc.local.example` y rellenala a mano.

## Estructura

```
.
|-- setup.sh              # orquestador: parseo de flags y dispatch
|-- lib/
|   `-- common.sh         # helpers reusables (apt_install, link_config, apt sources)
|-- modules/
|   |-- base.sh           # preparacion del sistema (repos, zona horaria)
|   |-- desktop.sh        # entorno i3, dotfiles, fuente, zsh
|   |-- security.sh       # herramientas de pentest
|   |-- dev.sh            # packaging Debian, kernel, chroot sbuild y toolchains
|   |-- editor.sh         # neovim (tarball upstream) y sus plugins
|   |-- ai.sh             # Claude Desktop y Claude Code
|   |-- hardware.sh       # asusctl (ASUS ROG)
|   |-- doctor.sh         # verificacion del estado (--doctor)
|   `-- update.sh         # actualizacion de lo que envejece (--update)
|-- packages/
|   |-- shell.txt         # zsh y plugins
|   |-- desktop.txt       # paquetes del escritorio
|   |-- security.txt      # paquetes de seguridad
|   |-- dev.txt           # paquetes de desarrollo
|   |-- kernel.txt        # dependencias de build del kernel
|   `-- nvim.txt          # lo que necesita el editor (clangd, ripgrep)
|-- config/               # dotfiles reales (enlazados por symlink)
|   |-- bin/bb            # helper de engagement de bug bounty
|   |-- bin/i3-help       # chuleta de atajos de i3 (Super+F1)
|   |-- sbuild/config.pl  # configuracion de sbuild (Perl)
|   |-- devscripts/       # quiltrc-dpkg, devscripts (packaging)
|   |-- git/ gbp/         # gitconfig y gbp.conf
|   |-- nvim/             # config de neovim + lazy-lock.json (enlazado entero)
|   `-- i3/ polybar/ picom/ kitty/ rofi/ dunst/ zsh/ autorandr/ wallpapers/
`-- docs/                 # arsenal.md, cheatsheet.md, i3.md, kernel.md, packaging.md, recon.md
```

Separacion de responsabilidades: `lib/` reusable, `modules/` logica por area, `packages/` datos, `config/` contenido, y `setup.sh` decide que corre.

## Principios de diseno

* Idempotencia primero. Cada accion comprueba si ya esta hecha antes de ejecutar (via dpkg, grep, fc-list, symlinks, getent).
* Datos fuera del codigo. Las listas de paquetes son archivos `.txt`, no arrays embebidos; anadir uno no toca bash.
* Configuracion versionada por symlink. Editar `~/.config/i3/config` edita el archivo del repo, sin copias que divergen.
* Fallo aislado. Una pieza que falla avisa y se omite, no arrastra al resto.
* Instalar no es terminar. Una herramienta sin sus datos no sirve (`gf` sin patrones, `nuclei` sin plantillas), y lo que se instala envejece. De ahi `--doctor` y `--update`.
* Secretos y identidad fuera del repo. Lo versionado es el comportamiento; el nombre, el correo, la clave de firma y las API keys viven en `~/.zshrc.local`, `~/.gitconfig.local` y `~/.config/subfinder/`.

## En progreso

El modulo `--dev` ya cubre el packaging de Debian, el kernel, el editor y la toolchain de Rust. Falta anadir:

* The Tor Project: C tor (autotools) y Arti (Rust).
* Un `tree-sitter-cli` reciente, para poder anadir `nvim-treesitter` (el de Debian 13 se queda corto; ver `docs/kernel.md`).

## Roadmap

* [x] Escritorio i3 completo (Catppuccin)
* [x] Refactor modular (lib, modules, packages)
* [x] Capa de seguridad (apt, Go, pipx, Docker)
* [x] Modulo de desarrollo (`--dev`)
* [x] Modulos `--ai` y `--hardware`
* [x] Verificacion del estado (`--doctor`) y actualizacion (`--update`)
* [x] Helper de engagement con control de alcance (`bb`)
* [x] Kernel de Linux: dependencias de build y editor (`--dev`)
* [ ] Funcion para binarios de GitHub (linpeas, chisel, Burp)
* [ ] Perfiles de autorandr versionados

## Notas

* Probado en Debian 13 (Trixie). Otras versiones pueden requerir ajustes en nombres de paquetes.
* Algunas herramientas no estan en repos Debian y se instalan por otras vias (SecLists por git clone, enum4linux-ng y NetExec por pipx desde GitHub, greenclip por `go install`).
* `rizin` y `wpscan` no estan en Debian 13; usar la imagen de Kali para esos casos.
* La imagen de Kali (Docker) se descarga bajo demanda la primera vez que se usa, no durante la instalacion.
* El teclado se fija a `latam` en el arranque de i3; cambialo en `config/i3/config` si usas otra distribucion de teclas.
* `--security` anade tu usuario al grupo `docker`, lo que equivale a acceso root en la maquina.
* `--ai` y `--hardware` instalan via `curl | sh` desde claude.ai y sh.rustup.rs.
* `--dev` usa el backend `unshare` de sbuild (construccion sin root, sin schroot que configurar). Va explicito en `~/.config/sbuild/config.pl` porque en trixie el default sigue siendo schroot.
* `--dev` crea el chroot de unstable en `~/.cache/sbuild` la primera vez; son unos minutos de descarga. Si ya existe el tarball, el paso no hace nada; `--update` lo recrea.
* sbuild prefiere `~/.config/sbuild/config.pl` sobre `~/.sbuildrc` y, si existen los dos, ignora el segundo en silencio. `--dev` retira el viejo y `--doctor` avisa si reaparece.
* Neovim no sale de apt: Debian 13 trae 0.10.4 y la configuracion necesita 0.11 por `vim.lsp.config`. Se instala el tarball oficial en `~/.local/nvim`, con la version fijada en `modules/editor.sh`; `--update` la revisa y `--doctor` avisa si el `nvim` del PATH no es ese.
* `--dev` enlaza `~/.gitconfig`, respaldando el que hubiera. Tu identidad se preserva: se escribe antes en `~/.gitconfig.local`, que el del repo incluye.
* Las API keys de subfinder no estan versionadas y no deben estarlo. Ver `docs/recon.md`.

## Licencia

MIT. Ver el archivo LICENSE.