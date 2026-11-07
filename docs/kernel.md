# Kernel

Como esta montada la maquina para trabajar en el kernel de Linux: que instala
`--dev`, como se prepara un arbol para que el editor lo entienda, y que hay
dentro de Neovim para no salir de el.

El envio de parches por correo (SMTP, `git send-email`, `b4`) no esta aqui:
vive en [packaging.md](packaging.md), porque es el mismo flujo para el kernel
que para cualquier otro upstream que trabaje por lista.

## Requisitos

```bash
./setup.sh --dev       # kit de packaging, deps del kernel, neovim y su config
./setup.sh --doctor    # comprueba que todo eso sigue en pie
```

`--dev` deja instalado lo de `packages/kernel.txt`: flex, bison, las cabeceras
de ncurses/elf/ssl, `bc`, `pahole` (sin el, `CONFIG_DEBUG_INFO_BTF` no
enlaza), `sparse` y `coccinelle` para el analisis estatico, y clang/llvm/lld
por si construyes con `LLVM=1`.

## El arbol

```bash
git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
```

Para un parche, clona el arbol del subsistema que vayas a tocar, no el de
Linus: los mantenedores recogen contra su rama y un parche que no aplica ahi
vuelve. `./scripts/get_maintainer.pl` dice cual es (`T:` en la entrada de
`MAINTAINERS`).

Evita `--depth=1` si vas a mandar algo: `git format-patch --base=auto` y `b4`
necesitan historial para calcular contra que se aplica la serie.

## Construir

```bash
make defconfig            # configuracion generica de la arquitectura
make localmodconfig       # o solo lo que carga tu maquina ahora mismo: mas rapido
make -j"$(nproc)"
```

`ccache` ya esta delante en el `PATH` (lo pone el `.zshrc` del repo), asi que
la segunda compilacion del mismo arbol vuela. `--doctor` avisa si se sale.

Si construyes paquetes del kernel con sbuild, comenta el
`$unshare_tmpdir_template` de `~/.config/sbuild/config.pl`: apunta a
`/dev/shm` y un kernel entero no cabe en RAM. Esta explicado en
[packaging.md](packaging.md).

## compile_commands.json

Esto es lo que separa un editor que entiende el kernel de uno que no.

Cada fichero del arbol se compila con un juego distinto de `-D` y `-I` segun
la configuracion activa. Sin la base de datos, clangd adivina, y adivina mal:
`#include <linux/module.h>` sin resolver, medio arbol en rojo y ningun salto a
definicion que funcione.

```vim
:CompileCommands     " ejecuta scripts/clang-tools/gen_compile_commands.py
:LspRestart          " clangd lee la base de datos al arrancar, no despues
```

El generador saca las banderas de los ficheros `.*.cmd` que deja la
construccion, asi que **hay que compilar el arbol antes**. Si no, avisa de
eso. Y hay que regenerarlo cuando cambies la configuracion de forma seria
(otra arquitectura, activar un subsistema que estaba fuera).

Para los drivers en Rust el equivalente es un target del propio kernel:

```bash
make rust-analyzer       # genera rust-project.json (necesita CONFIG_RUST)
```

## El editor

Neovim no viene de apt. Debian 13 congela la 0.10.4 y aqui hace falta 0.11 o
mas por la API de LSP (`vim.lsp.config`), asi que `modules/editor.sh` instala
el tarball oficial en `~/.local/nvim` y lo enlaza en `~/.local/bin/nvim`. La
version esta fijada en el modulo; `--update` la revisa.

La configuracion vive en `config/nvim/` y esta enlazada entera a
`~/.config/nvim`. Como el directorio es el del repo, `lazy-lock.json` cae
dentro y las versiones exactas de los plugins quedan versionadas: dos maquinas
con el mismo commit tienen el mismo editor.

### Comandos del kernel

Solo funcionan dentro de un arbol del kernel; fuera avisan y no hacen nada. La
deteccion busca `Kbuild`, `MAINTAINERS` y `scripts/checkpatch.pl` en los
directorios padre.

| Comando | Atajo | Que hace |
|---------|-------|----------|
| `:Checkpatch` | `<leader>kc` | checkpatch sobre el fichero actual, al quickfix |
| `:Checkpatch HEAD` | `<leader>kg` | checkpatch sobre un commit o rango (`--git`) |
| `:Maintainers` | `<leader>km` | get_maintainer del fichero; copia la lista limpia al portapapeles |
| `:CompileCommands` | `<leader>kj` | genera `compile_commands.json` |
| `:KernelRoot` | `<leader>kr` | dice que arbol ha detectado |

`:Checkpatch` deja el foco en el codigo, no en el quickfix. Se recorre con
`]q` y `[q`.

`:Maintainers` deja en el portapapeles la lista sin los roles, en el formato
que quiere `git send-email --to=`.

### Navegacion

| Atajo | Que hace |
|-------|----------|
| `<leader>ff` | buscar ficheros |
| `<leader>fg` | buscar texto en todo el arbol (ripgrep) |
| `<leader>fw` | buscar la palabra bajo el cursor |
| `<leader>ss` / `<leader>sS` | simbolos del fichero / del proyecto |
| `gd` `gr` `gi` `K` | definicion, referencias, implementaciones, documentacion |
| `]h` `[h` | saltar entre cambios de git |
| `]d` `[d` | saltar entre diagnosticos |

El buscador filtra `*.o`, `*.ko`, `*.cmd`, `*.mod.c` y demas artefactos: en un
arbol construido son mas ficheros que codigo.

`:grep` tambien esta enganchado a ripgrep y cae en el quickfix, que es lo
comodo cuando ya sabes el patron exacto.

### Estilo

En ficheros C se aplica solo lo que dice
`Documentation/process/coding-style.rst`: tabs de 8, `cinoptions=:0,l1,t0,g0,(0`
y dos marcas de columna, en 80 (el limite de estilo) y en 100 (el que hace
fallar a checkpatch desde 5.7). Neovim ademas lee el `.editorconfig` que trae
el propio arbol.

No hay formateo al guardar, y es deliberado: pasar `clang-format` a un fichero
del kernel convierte un parche de tres lineas en uno de trescientas. Si lo
quieres, es `<leader>cf`, a mano y sobre lo que tu decidas.

### Resaltado

No hay `nvim-treesitter`. Su rama `main` exige `tree-sitter-cli` 0.26.1 o
superior y Debian 13 trae 0.22.6: el plugin se instalaria y fallaria al
compilar cada parser. Neovim 0.12 ya trae de serie el parser de C, que es el
95% del arbol, y kconfig, dts, diff y gitcommit caen en la sintaxis clasica
del runtime, que para leer parches sobra.

Si algun dia hay un `tree-sitter-cli` reciente en la maquina, anadirlo son
diez lineas en `config/nvim/lua/plugins/`. El porque esta escrito en
`config/nvim/lua/sintaxis.lua`.

## Antes de mandar nada

```bash
# El estilo, sobre la serie entera y no solo sobre el ultimo commit
./scripts/checkpatch.pl --strict --git origin/master..HEAD

# Que no rompes la compilacion de lo que tocas
make -j"$(nproc)" drivers/tu/subsistema/

# Analisis estatico del fichero que has tocado
make C=1 M=drivers/tu/subsistema/
```

Y a partir de ahi, el flujo de correo de [packaging.md](packaging.md):
`git format-patch --base=auto`, `git send-email --dry-run` para mirar la
cabecera, y `b4` para recoger series ajenas.
