# aureola — identidad visual

Todo el escritorio sale del mismo sitio: `config/wallpapers/angel.jpg`.
Los colores no son un tema de internet, están muestreados del propio fondo.

## Paleta

Fuente de verdad: [`config/theme/aureola.conf`](../config/theme/aureola.conf).
Los dotfiles llevan el hex literal porque ni polybar ni rofi ni kitty saben
importar variables: si cambias un color, cámbialo ahí y propágalo.

| rol | hex | de dónde sale |
| --- | --- | --- |
| `crypt` | `#0e0e15` | sombra más profunda |
| `mantle` | `#12121c` | fondo de barra y tooltips |
| `base` | `#171622` | fondo principal |
| `surface0` | `#232232` | tarjetas, inputs |
| `surface1` | `#302f43` | hover, workspace activo |
| `overlay` | `#565575` | separadores, texto apagado |
| `subtext` | `#9fb0cf` | periwinkle del fondo del wallpaper |
| `text` | `#dee5f3` | luz del halo |
| `halo` | `#b9d4f0` | acento frío: selección, rutas |
| `ice` | `#8fbce6` | azul hielo: enlaces, disco |
| `azur` | `#5d93c9` | acero de la espada |
| `rose` | `#f2a8c0` | acento cálido: foco, cursor, prompt |
| `blush` | `#ef8fa8` | urgente, error, batería baja |
| `lavanda` | `#c4b6f2` | rama de git, fecha, modos de i3 |
| `menta` | `#9fe0cf` | ok, vpn, batería sana |
| `oro` | `#f0dcae` | avisos, cambios sin commitear |

Regla de uso: **rosa = dónde estás** (ventana con foco, cursor, workspace
activo), **hielo/halo = qué hay** (texto, rutas, selección), **menta / oro /
blush = cómo va** (bien, ojo, mal). Nada más lleva color.

## Tipografía

- **Comfortaa** — texto de interfaz: barra, menús, notificaciones, títulos de
  ventana, apps GTK y login. Geométrica y muy redonda; es la que pone el acento
  kawaii. Viene por apt (`fonts-comfortaa`).
- **Maple Mono NF** — todo lo monoespaciado: terminal, prompt e iconos.
  Redondeada, con ligaduras (`!=` → `≠`, `=>` → `⇒`, `->` → `→`) y cursiva de
  verdad para comentarios. Se baja de su propio repo (`subframe7536/maple-font`,
  variante `MapleMono-NF.zip`), no de nerd-fonts.

Ambas las instala `./setup.sh --desktop`.

**Los glifos van por nombre, no por dibujo.** Los iconos son Nerd Fonts
(Material Design, plano privado): no dependen de que haya emoji en el sistema,
pero conviene comprobar cada punto de código antes de usarlo — varios nombres
que uno da por hechos no son lo que parecen (`f0ec1` no es una estrella, es un
wifi tachado). Para verificar uno:

```sh
python3 - <<'EOF'
import json, urllib.request
from fontTools.ttLib import TTFont
g = json.load(urllib.request.urlopen(
    "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json"))
cmap = TTFont("~/.local/share/fonts/MapleMono/MapleMono-NF-Regular.ttf").getBestCmap()
print(hex(int(g["md-butterfly"]["code"], 16)), int(g["md-butterfly"]["code"], 16) in cmap)
EOF
```

## Geometría

- Ventanas con esquinas de 14 px (picom) y borde de 2 px (i3).
- `gaps inner 10`, `outer 4`, `top 8`; con una sola ventana el borde se esconde
  (`hide_edge_borders smart`) para que el fondo respire.
- Barra flotante: 34 px de alto, radio 14, separada 12 px de los bordes y
  translúcida al 80 %.
- Terminal al 90 % de opacidad sobre el blur `dual_kawase` del compositor.

## Movimiento

Nada aparece de golpe. Todo usa la misma idea: entrar rápido y posarse despacio.

| qué | dónde | cómo |
| --- | --- | --- |
| Abrir ventana | picom | crece del 94 % al 100 % anclada a su centro, 0,30 s con `cubic-bezier(0.16, 1, 0.30, 1)` (ease-out-expo) |
| Cerrar ventana | picom | encoge al 96 % y se desvanece en 0,22 s, con curva de entrada (`0.32, 0, 0.67, 0`) |
| Mover / redimensionar | picom | preset `geometry-change` a 0,26 s: la ventana persigue su hueco al retilar |
| Cambiar de foco | picom | la opacidad de kitty (92 % ↔ 84 %) cruza en 0,18 s en vez de saltar |
| Cambiar de workspace | picom | i3 mapea y desmapea ventanas, así que reusa las curvas de abrir y cerrar |
| Cursor de la terminal | kitty | `cursor_trail`: estela que sigue los saltos grandes, decaimiento 0,08–0,35 s |
| Parpadeo del cursor | kitty | `cursor_blink_interval 0.6 ease-in-out`: se funde, no da saltos |
| Repintado | kitty | `sync_to_monitor` + `repaint_delay 8` + `input_delay 1` |

Las curvas son las mismas dos en todo el escritorio, y ahí está el truco: si
cada cosa se moviera con su propio tiempo, se notaría el remiendo.

## Qué toca cada fichero

| fichero | qué aporta |
| --- | --- |
| `config/theme/aureola.conf` | la paleta, comentada con su origen |
| `config/i3/config` | colores de ventana, gaps, workspaces con glifos |
| `config/polybar/config.ini` | barra flotante, iconos y colores por módulo |
| `config/kitty/kitty.conf` | ANSI pastel, opacidad, cursor rosa |
| `config/rofi/config.rasi` | lanzador de cristal con acento rosa |
| `config/dunst/dunstrc` | notificaciones redondeadas por urgencia |
| `config/picom/picom.conf` | blur, sombras frías, animaciones |
| `config/zsh/.zshrc` | prompt de dos líneas, resaltado y `man` a juego |
| `modules/desktop.sh` | `FUENTES_ZIP`: fuentes que no vienen por apt |
| `config/gtk/*` | apps GTK 2/3/4 con la misma base y acento |
| `config/lightdm/*` | pantalla de login con el mismo fondo y fuente |

## Workspaces

| ws | glifo | nombre Nerd Font | ws | glifo | nombre Nerd Font |
| --- | --- | --- | --- | --- | --- |
| 1 | 󰋑 corazón | `md-heart` | 6 | 󰅣 nube | `md-cloud_outline` |
| 2 | 󰓎 estrella | `md-star` | 7 | 󱖉 mariposa | `md-butterfly` |
| 3 | 󰉊 flor | `md-flower` | 8 | 󱕅 destello | `md-shimmer` |
| 4 | 󰜗 copo | `md-snowflake` | 9 | 󰧱 tulipán | `md-flower_tulip` |
| 5 | 󰖔 luna | `md-weather_night` | 10 | 󰄛 gato | `md-cat` |

Los atajos siguen siendo `$mod+número`: el nombre es `"1:󰋑"` y polybar recorta
el número con `strip-wsnumbers`.

## Prompt

```
╭─ 󰋑 mudx2 󰫢 ~/setup 󰫢  feat/dev-packaging 󰏫
╰─ 󰫢
```

El corazón y el usuario en rosa, la ruta en halo, la rama en lavanda, el lápiz
(`md-pencil`) en oro si hay cambios sin commitear. El destello de abajo
(`md-star_four_points`) es menta si el último comando salió bien y blush si
falló; a la derecha, el código de salida y la hora.

## Aplicar cambios sin reiniciar

```sh
i3-msg reload                  # colores, gaps, bordes
~/.config/polybar/launch.sh    # barra
killall -q picom; picom --config ~/.config/picom/picom.conf &
killall dunst                  # vuelve solo con la primera notificación (dbus)
pkill -USR1 -x kitty           # recarga kitty en caliente
exec zsh                       # prompt
```

Dos avisos:

- `i3-msg reload` **no renombra los workspaces que ya existen**: el glifo solo
  aparece en los que se crean después. Para los abiertos:
  `i3-msg 'rename workspace "1" to "1:󰋑"'`.
- Una terminal abierta desde `i3-sensible-terminal` corre como
  `x-terminal-emulator`, así que `pkill -USR1 -x kitty` no la alcanza. Por eso
  `$mod+Return` lanza `kitty` directamente.

El greeter necesita `sudo systemctl restart lightdm` (cierra la sesión).
