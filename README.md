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

i3 con configuracion coherente en tema Catppuccin Mocha.

| Componente      | Herramienta                                          |
|-----------------|------------------------------------------------------|
| Window manager  | i3                                                   |
| Barra           | polybar (multi-monitor, indicador VPN, acceso arandr)|
| Compositor      | picom (transparencias, blur, esquinas redondeadas)   |
| Terminal        | kitty                                                |
| Lanzador        | rofi                                                 |
| Notificaciones  | dunst                                                |
| Shell           | zsh (prompt propio, autosuggestions, highlighting)   |
| Fuente          | JetBrainsMono Nerd Font                              |
| Multi-monitor   | autorandr (perfiles y fallback automatico)           |
| Extras          | scratchpad, greenclip, wallpaper (feh), Firefox      |

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
* Dotfiles por symlink: `~/.sbuildrc`, `~/.quiltrc-dpkg`, `~/.devscripts`, `~/.gitconfig` y `~/.gbp.conf`.
* Chroot de sbuild de unstable con `ccache` dentro, creado con `mmdebstrap` sobre el backend unshare.
* Identidad derivada de tu clave GPG: `DEBFULLNAME` y `DEBEMAIL` a `~/.zshrc.local`, y nombre, correo y `user.signingkey` a `~/.gitconfig.local`.
* Parches por correo: `git-email` y `b4`, para mandar arreglos upstream y al kernel.
* Toolchain de Rust via rustup, mas las dependencias nativas de compilacion habituales.

Ver `docs/packaging.md` para el flujo completo por fases: elegir el bug, obtener el fuente, reproducir, parchear, validar y enviar.

## Uso

```bash
git clone https://github.com/hw4n1/debian13-configs.git ~/setup
cd ~/setup

./setup.sh --help          # opciones
./setup.sh --desktop       # solo el entorno i3
./setup.sh --security      # solo herramientas de seguridad
./setup.sh --dev           # packaging Debian, chroot sbuild y toolchains
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
|   |-- dev.sh            # packaging Debian, chroot sbuild y toolchains
|   |-- ai.sh             # Claude Desktop y Claude Code
|   |-- hardware.sh       # asusctl (ASUS ROG)
|   |-- doctor.sh         # verificacion del estado (--doctor)
|   `-- update.sh         # actualizacion de lo que envejece (--update)
|-- packages/
|   |-- shell.txt         # zsh y plugins
|   |-- desktop.txt       # paquetes del escritorio
|   |-- security.txt      # paquetes de seguridad
|   `-- dev.txt           # paquetes de desarrollo
|-- config/               # dotfiles reales (enlazados por symlink)
|   |-- bin/bb            # helper de engagement de bug bounty
|   |-- devscripts/       # sbuildrc, quiltrc-dpkg, devscripts (packaging)
|   |-- git/ gbp/         # gitconfig y gbp.conf
|   `-- i3/ polybar/ picom/ kitty/ rofi/ dunst/ zsh/ autorandr/ wallpapers/
`-- docs/                 # arsenal.md, cheatsheet.md, packaging.md, recon.md
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

El modulo `--dev` ya cubre el flujo de packaging de Debian, los parches por correo y la toolchain de Rust via rustup. Falta anadir:

* The Tor Project: C tor (autotools) y Arti (Rust).
* Linux kernel: dependencias de build y configuracion de `get_maintainer.pl`.

## Roadmap

* [x] Escritorio i3 completo (Catppuccin)
* [x] Refactor modular (lib, modules, packages)
* [x] Capa de seguridad (apt, Go, pipx, Docker)
* [x] Modulo de desarrollo (`--dev`)
* [x] Modulos `--ai` y `--hardware`
* [x] Verificacion del estado (`--doctor`) y actualizacion (`--update`)
* [x] Helper de engagement con control de alcance (`bb`)
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
* `--dev` usa el backend `unshare` de sbuild (construccion sin root, sin schroot que configurar). Va explicito en `~/.sbuildrc` porque en trixie el default sigue siendo schroot.
* `--dev` crea el chroot de unstable en `~/.cache/sbuild` la primera vez; son unos minutos de descarga. Si ya existe el tarball, el paso no hace nada; `--update` lo recrea.
* `~/.sbuildrc` monta `~/.cache/sbuild-ccache` dentro del chroot. Ese directorio tiene que existir o sbuild aborta al montar el bind; `--dev` lo crea.
* `--dev` enlaza `~/.gitconfig`, respaldando el que hubiera. Tu identidad se preserva: se escribe antes en `~/.gitconfig.local`, que el del repo incluye.
* Las API keys de subfinder no estan versionadas y no deben estarlo. Ver `docs/recon.md`.

## Licencia

MIT. Ver el archivo LICENSE.