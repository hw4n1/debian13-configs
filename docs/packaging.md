# Packaging

Flujo para arreglar un bug en un paquete que ya esta en el archivo de Debian, organizado por fase. No cubre paquetes nuevos (ITP): eso es otro camino.

Regla mental: no toques nada hasta reproducir el bug. Un parche que no sabes que arregla algo es ruido para el mantenedor.

Estado del archivo (agosto 2026): stable = trixie (13.6), testing = forky, unstable = sid. Sin fechas de freeze anunciadas para forky. Los parches van a unstable salvo que sea un fallo de seguridad o RC.

Requisitos: `./setup.sh --dev` deja instalado el kit, habilitado `deb-src`, creado el chroot de sbuild y escrita la identidad. `./setup.sh --doctor` verifica que todo eso sigue en pie.

`DEBFULLNAME` y `DEBEMAIL` se derivan de tu clave GPG y se escriben en `~/.zshrc.local`. Tienen que coincidir con el uid de la clave con la que firmas: si el changelog dice un nombre y la firma dice otro, el sponsor lo devuelve.

El alias `dquilt` ya viene en el `.zshrc` del repo. Sin el, quilt escribe en `./patches/` y el paquete ignora tu parche:

```bash
alias dquilt='quilt --quiltrc=$HOME/.quiltrc-dpkg'
```

## Como esta montada la construccion

`~/.sbuildrc` (enlazado desde el repo) fija tres cosas que conviene conocer:

* **Backend `unshare`.** Construye sin root y sin schroot que configurar. Va explicito porque en trixie el default sigue siendo schroot.
* **`/dev/shm` como directorio de trabajo.** La construccion va en RAM y vuela. Para paquetes enormes (kernel, chromium, libreoffice) comenta `$unshare_tmpdir_template` o te quedas sin memoria.
* **ccache montado en `/build/ccache`.** El chroot trae el paquete `ccache` y `$path` antepone `/usr/lib/ccache`, asi que gcc pasa por la cache sola. El directorio del host es `~/.cache/sbuild-ccache` y **tiene que existir**: si falta, sbuild aborta al montar el bind.

Un chroot creado antes de esto no trae `ccache` dentro y la cache no se usa aunque el bind funcione. Recrealo:

```bash
./setup.sh --update
```

El chroot es de sid y envejece: pasadas un par de semanas empiezan los desfases de build-deps que no se explican solos. `--doctor` avisa a los 14 dias.

## Fase 0. Elegir el bug

```bash
# Bugs marcados por el mantenedor como buenos para empezar (etiqueta oficial del BTS)
xdg-open 'https://bugs.debian.org/tag:newcomer'

# Bugs regalados por su mantenedor, ordenados por popcon (los mas usados primero).
# gift es el usertag historico y es el parametro real de la busqueda de UDD;
# newcomer=only no existe y devuelve cero en silencio.
xdg-open 'https://udd.debian.org/bugs/?gift=1&release=any&merged=ign&done=ign&ctags=1&cpopcon=1&sortby=popcon&sorto=desc'

# Que esta roto en paquetes que ya tienes instalados
how-can-i-help

# Bugs de un paquete concreto
bts show --mbox src:paquete
xdg-open https://bugs.debian.org/src:paquete
```

Criterio: empieza por bugs con reproduccion clara, sin discusion upstream abierta y en paquetes que usas. Evita los RC de paquetes con muchas reverse dependencies hasta tener soltura.

## Fase 1. Obtener el fuente

```bash
# Fuente de la version en unstable (necesita deb-src habilitado)
apt source paquete
cd paquete-1.2.3

# Version concreta si la de unstable no es la del bug
apt source paquete=1.2.3-4

# Alternativa con git: la mayoria de paquetes estan en salsa.debian.org
gbp clone https://salsa.debian.org/equipo/paquete.git
cd paquete && gbp pull

# ~/.gbp.conf ya deja gbp construyendo con sbuild y pristine-tar activo
gbp buildpackage

# Quien lo mantiene y en que estado esta
apt show paquete
grep -E '^(Maintainer|Uploaders|Vcs-Git)' debian/control
```

Mira siempre `debian/control`: si hay `Vcs-Git` a salsa, el mantenedor espera merge requests, no parches sueltos.

## Fase 2. Reproducir

```bash
# Dependencias de construccion, sin ensuciar el sistema (mk-build-deps usa equivs)
sudo mk-build-deps -i -r debian/control

# Construccion rapida en el arbol para tener el binario del bug
debuild -b

# Construccion limpia y aislada (esto es lo que vale como prueba)
sbuild -d unstable

# Historia del paquete: a veces el bug ya esta comentado
zless /usr/share/doc/paquete/changelog.Debian.gz
```

Si no reproduces, dilo en el bug antes de invertir mas tiempo. Un "no reproduce en 1.2.3-4, adjunto los pasos" ya es una contribucion.

## Fase 3. Parchear

Nunca edites los fuentes upstream a mano: todo cambio va como parche quilt en `debian/patches/`.

```bash
# Nuevo parche y ficheros que va a tocar
dquilt new 12_arregla-segfault-en-parseo.patch
dquilt add src/parser.c

# Edita src/parser.c y luego congela el parche
dquilt refresh

# Estado
dquilt series        # parches de la serie
dquilt applied       # cuales estan aplicados
dquilt pop -a        # desaplica todo antes de construir en limpio
```

Cabeceras DEP-3 en la cabeza del parche. `Description` es obligatoria; `Origin` es obligatoria si no hay `Author`. Opcionales: `Bug-Debian`, `Bug`, `Forwarded`, `Last-Update`, `Applied-Upstream`.

```
Description: Arregla segfault al parsear una entrada vacia
 El bucle no comprobaba el final del buffer y leia una posicion de mas
 cuando el fichero terminaba sin salto de linea.
Author: Nombre Apellido <tu@correo>
Bug-Debian: https://bugs.debian.org/1090123
Forwarded: https://github.com/upstream/proyecto/pull/456
Last-Update: 2026-08-05
```

`Forwarded: no` si aun no lo mandaste upstream, pero mandalo: Debian prefiere que el arreglo viva upstream.

```bash
# Entrada de changelog (no la escribas a mano)
dch --nmu           # si no eres el mantenedor
dch -i              # si mantienes el paquete
```

En la entrada, `Closes: #1090123` cierra el bug al subir.

## Fase 4. Validar

```bash
# Construccion limpia en el chroot unshare, con lintian al final
sbuild -d unstable

# Lintian a fondo sobre el .changes
lintian -i -I --pedantic ../paquete_1.2.3-4.1_amd64.changes

# El parche aplica y revierte limpio
dquilt push -a && dquilt pop -a

# Diferencias contra el paquete original (debdiff usa wdiff en control)
debdiff ../paquete_1.2.3-4.dsc ../paquete_1.2.3-4.1.dsc

# Instalacion, actualizacion y purga limpias
sudo piuparts ../paquete_1.2.3-4.1_amd64.deb

# Tests del propio paquete
autopkgtest ../paquete_1.2.3-4.1_amd64.changes -- unshare --release unstable

# Licencias, si tocaste ficheros nuevos
licensecheck -r src/
```

No mandes nada con lintian en rojo por tu culpa. Los avisos que ya venian del paquete no son tuyos: no los arregles en el mismo parche.

## Fase 5. Enviar

```bash
# Adjunta el parche al bug. Ojo: bts no tiene --attach; el parche se adjunta
# desde tu cliente de correo, escribiendo a NNNNNN@bugs.debian.org
bts show 1090123
```

En el cuerpo del correo, las lineas `Control:` al inicio se ejecutan como comandos del BTS:

```
Control: tags -1 + patch
Control: tags -1 + upstream

Adjunto un parche contra 1.2.3-4 que arregla el segfault.
Construido y probado con sbuild en unstable, lintian limpio.
```

```bash
# Si el paquete esta en salsa, un merge request es mejor que un parche por correo
git checkout -b arregla-segfault-1090123
gbp buildpackage --git-tag  # solo si mantienes el paquete
# push a tu fork y MR en salsa.debian.org

# Reportar un bug nuevo que encontraste por el camino
reportbug paquete

# Subir (solo con derechos de subida o via sponsor)
dput ftp-master ../paquete_1.2.3-4.1_source.changes
```

Si no eres DD ni DM necesitas un sponsor: manda el paquete a `debian-mentors@lists.debian.org` con `reportbug --no-bug-script sponsorship-requests` y espera revision.

## Ruta a Debian Maintainer

1. Parches aceptados en varios paquetes, con historial en el BTS.
2. Subidas patrocinadas por un DD (RFS en debian-mentors) hasta que el sponsor confie en tu trabajo.
3. Clave GPG firmada por un DD en un keysigning.
4. Solicitud de DM en nm.debian.org con el aval de los sponsors.

## Referencia rapida

| Que | Comando |
|-----|---------|
| Bajar fuente | `apt source paquete` |
| Build-deps | `sudo mk-build-deps -i -r debian/control` |
| Build rapido | `debuild -b` |
| Build limpio | `sbuild -d unstable` |
| Nuevo parche | `dquilt new NN_nombre.patch` |
| Congelar parche | `dquilt refresh` |
| Changelog | `dch --nmu` |
| Lintian | `lintian -i -I --pedantic ../*.changes` |
| Comparar | `debdiff viejo.dsc nuevo.dsc` |
| Ver bug | `bts show NNNNNN` |
| Reportar bug | `reportbug paquete` |
| Buscar trabajo | `how-can-i-help` |
| Verificar el entorno | `./setup.sh --doctor` |
| Refrescar el chroot | `./setup.sh --update` |

## Parches por correo (upstream y kernel)

Debian prefiere que el arreglo viva upstream, y buena parte de upstream (kernel, util-linux, coreutils) trabaja por lista de correo. `git-email` y `b4` vienen con `--dev`.

Antes de nada, el SMTP va en `~/.gitconfig.local`, que no esta versionado:

```ini
[sendemail]
	smtpServer = smtp.tu-proveedor.tld
	smtpServerPort = 587
	smtpEncryption = tls
	smtpUser = tu@correo.tld
```

La contrasena no se escribe ahi: dejala fuera y git la pedira, o guardala en el keyring.

```bash
# Preparar la serie (format.signOff y --base ya vienen del gitconfig del repo)
git format-patch --base=auto -o /tmp/serie origin/master

# Revisar antes de mandar: esto es lo que ve la lista
git send-email --dry-run --to=lista@vger.kernel.org /tmp/serie

# A quien hay que mandarselo en el kernel
./scripts/get_maintainer.pl -f drivers/net/algo.c

# Recoger una serie ajena desde la lista y aplicarla
b4 am 20260801.123456.abcdef@ejemplo.tld
b4 shazam -M   # aplica directamente sobre la rama actual
```

`sendemail.confirm = always` esta puesto a proposito: obliga a mirar la cabecera antes de que salga. Un parche mal dirigido a una lista publica no se puede recoger.
