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

* apt: nmap, masscan, sqlmap, nikto, gobuster, ffuf, wfuzz, hydra, john, hashcat, binwalk, steghide, rizin, smbclient, tmux, openvpn.
* Go (ProjectDiscovery y afines): subfinder, httpx, nuclei, naabu, dnsx, katana, gau, dalfox, amass, gowitness, gf.
* pipx: arjun, dirsearch, wafw00f, uro, pwntools.
* Docker: motor mas Kali desechable para el arsenal pesado bajo demanda.

Ver `docs/arsenal.md` para el listado completo por fase y `docs/cheatsheet.md` para comandos de uso.

## Uso

```bash
git clone https://github.com/hw4n1/debian13-configs.git ~/setup
cd ~/setup

./setup.sh --help          # opciones
./setup.sh --desktop       # solo el entorno i3
./setup.sh --security      # solo herramientas de seguridad
./setup.sh --all           # todo
```

No ejecutar como root. El script pide `sudo` solo cuando lo necesita (apt, servicios). Los dotfiles y binarios de usuario se mantienen bajo el usuario normal.

Tras `--desktop`, cerrar sesion y volver a entrar para aplicar zsh como shell por defecto y el grupo `docker`, y seleccionar la sesion i3 en el login.

## Estructura

```
.
|-- setup.sh              # orquestador: parseo de flags y dispatch
|-- lib/
|   `-- common.sh         # helpers reusables (apt_install, link_config)
|-- modules/
|   |-- base.sh           # preparacion del sistema (repos)
|   |-- desktop.sh        # entorno i3, dotfiles, fuente, zsh
|   `-- security.sh       # herramientas de pentest
|-- packages/
|   |-- desktop.txt       # paquetes del escritorio
|   `-- security.txt      # paquetes de seguridad
|-- config/               # dotfiles reales (enlazados por symlink)
|   `-- i3/ polybar/ picom/ kitty/ rofi/ dunst/ zsh/
`-- docs/                 # arsenal.md, cheatsheet.md
```

Separacion de responsabilidades: `lib/` reusable, `modules/` logica por area, `packages/` datos, `config/` contenido, y `setup.sh` decide que corre.

## Principios de diseno

* Idempotencia primero. Cada accion comprueba si ya esta hecha antes de ejecutar (via dpkg, grep, fc-list, symlinks, getent).
* Datos fuera del codigo. Las listas de paquetes son archivos `.txt`, no arrays embebidos; anadir uno no toca bash.
* Configuracion versionada por symlink. Editar `~/.config/i3/config` edita el archivo del repo, sin copias que divergen.
* Fallo aislado. Una pieza que falla avisa y se omite, no arrastra al resto.

## En progreso

Modulo de desarrollo (`--dev`) con toolchains para contribuir a proyectos upstream:

* The Tor Project: C tor (autotools) y Arti (Rust).
* Debian: packaging (devscripts, sbuild, lintian, git-buildpackage).
* Linux kernel: build y `b4` para el flujo de parches por email.

## Roadmap

* [x] Escritorio i3 completo (Catppuccin)
* [x] Refactor modular (lib, modules, packages)
* [x] Capa de seguridad (apt, Go, pipx, Docker)
* [ ] Modulo de desarrollo (`--dev`)
* [ ] Funcion para binarios de GitHub (linpeas, chisel, Burp)
* [ ] Perfiles de autorandr versionados

## Notas

* Probado en Debian 13 (Trixie). Otras versiones pueden requerir ajustes en nombres de paquetes.
* Algunas herramientas no estan en repos Debian y se instalan por otras vias (SecLists por git clone, enum4linux-ng desde GitHub).
* La imagen de Kali (Docker) se descarga bajo demanda la primera vez que se usa, no durante la instalacion.

## Licencia

MIT. Ver el archivo LICENSE.