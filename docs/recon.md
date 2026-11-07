# Recon

Flujo de bug bounty con `bb`, el helper que instala `--security` en `~/.local/bin/bb`.

Regla mental: el alcance no se recuerda, se escribe. Todo lo que `bb` produce pasa por `scope.txt`; lo que no encaja se descarta antes de que ninguna herramienta lo toque.

## Ciclo de trabajo

```bash
bb new acme            # crea ~/bounty/acme/{recon,nuclei,notes,loot} y scope.txt
$EDITOR ~/bounty/acme/scope.txt
bb recon acme          # subdominios -> resolucion -> hosts vivos
bb urls acme           # URLs historicas y crawling
bb scan acme           # nuclei sobre los hosts vivos
bb list                # resumen de todos los objetivos
```

Cada paso escribe en `~/bounty/<objetivo>/recon/` y usa `anew`, asi que reejecutarlo solo anade lo nuevo: puedes correr `bb recon` a diario sobre el mismo objetivo y ver que aparecio.

## El fichero de alcance

Una linea por dominio. El comodin es opcional y se ignora al consultar las fuentes:

```
acme.com
*.acme-cdn.net
```

El filtro acepta un host si es exactamente un dominio del alcance o termina en `.dominio`. Eso descarta los tres casos que se cuelan solos:

| Host | Con `acme.com` en el alcance |
|------|------------------------------|
| `www.acme.com` | dentro |
| `acme.com` | dentro |
| `notacme.com` | fuera |
| `acme.com.evil.net` | fuera |

Si el programa restringe por rangos de IP y no por dominio, `scope.txt` no basta: filtra tambien la salida de `bb recon` contra la lista de rangos antes de escanear.

## API keys de subfinder

Sin claves, subfinder solo usa fuentes abiertas y pierde la mayor parte de la cobertura. Las claves van en `~/.config/subfinder/provider-config.yaml`, que no esta versionado y no debe estarlo.

```yaml
chaos:
  - clave
securitytrails:
  - clave
github:
  - token
```

Proveedores con nivel gratuito que suelen rendir mas: `chaos` (ProjectDiscovery), `securitytrails`, `virustotal`, `github`, `shodan`, `censys`, `bevigil`, `fullhunt`, `netlas`, `leakix`, `binaryedge`, `intelx`. Los limites cambian a menudo; comprueba el actual antes de apoyarte en uno.

`github` merece atencion aparte: no busca DNS sino codigo publico, y saca subdominios que ninguna fuente pasiva tiene. Un token clasico sin permisos sirve.

Comprueba cuantas tienes configuradas con:

```bash
./setup.sh --doctor
```

## Filtrado con gf

`--security` instala los patrones en `~/.gf`. Sobre las URLs recogidas:

```bash
gf xss    < ~/bounty/acme/recon/urls.txt | qsreplace '"><svg onload=alert(1)>'
gf sqli   < ~/bounty/acme/recon/urls.txt
gf ssrf   < ~/bounty/acme/recon/urls.txt
gf -list                                    # patrones disponibles
```

`uro` antes de cualquier fuzzing quita URLs equivalentes y recorta el trabajo a la mitad:

```bash
uro < recon/urls.txt | anew recon/urls-unicas.txt
```

## Notificaciones

`notify` manda los hallazgos a Slack, Discord o Telegram segun `~/.config/notify/provider-config.yaml`:

```bash
bb scan acme && notify -data ~/bounty/acme/nuclei/hallazgos.txt -bulk
```

## Mantenimiento

Las plantillas de nuclei y las herramientas de Go envejecen rapido: un nuclei de hace un mes no trae los CVE del mes.

```bash
./setup.sh --update    # herramientas de Go, pipx, plantillas, patrones, SecLists
./setup.sh --doctor    # avisa cuando las plantillas pasan de 7 dias
```

## Higiene

* No hay caso en que un escaneo activo sobre algo fuera del alcance sea aceptable, ni siquiera "para comprobar". Si el programa no lo lista, no existe.
* `nuclei` y `ffuf` a rate por defecto tumban servicios pequenos. Usa `-rate-limit` y `-t` bajos hasta saber que aguanta el objetivo.
* Guarda la evidencia segun la generas en `notes/`: reconstruir un hallazgo tres dias despues cuesta mas que anotarlo en el momento.
