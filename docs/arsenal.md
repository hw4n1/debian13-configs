# Arsenal

Referencia de herramientas de pentest, bug bounty y CTF, organizada por fase de ataque. Cada herramienta indica su fuente de instalacion para saber por que patron entra en el setup.

Fuentes: APT (repos Debian), GO (binario via go install), PIPX (Python aislado), SCRIPT (binario o script de GitHub), DOCKER (contenedor).

Rutas: binarios Go en `~/go/bin`, pipx en `~/.local/bin`, scripts sueltos en `~/tools`. Todos deben estar en el PATH.

## Fase 1. Reconocimiento

### Descubrimiento de subdominios y activos (bug bounty)

| Tool | Fuente | Que hace |
|------|--------|----------|
| subfinder | GO | Subdominios pasivos, rapido. `subfinder -d dominio.com -all -silent` |
| amass | GO | Enumeracion profunda pasiva y activa. `amass enum -d dominio.com` |
| assetfinder | GO | Subdominios de varias fuentes. `assetfinder dominio.com` |
| httpx | GO | Filtra hosts vivos, titulo, tech, status. `cat subs.txt \| httpx -silent -title -tech-detect` |
| dnsx | GO | Resolucion DNS masiva y filtrado. `dnsx -l subs.txt -silent` |
| gau | GO | URLs historicas (wayback, otx). `gau dominio.com` |
| waybackurls | GO | m/tomnomnom/assetfinder@latest
httpx       -> github.com/projectdiscovery/httpx/cmd/httpx@latest
dnsx        -> github.com/projectdiscovery/dnsx/cmd/dnsx@latest
gau         -> github.com/lc/gau/v2/cmd/gau@latest
waybackurls -> github.com/tomnomnom/waybackurls@latest
katana      -> github.com/projectdiscovery/katana/cmd/katana@latest
gowitness   -> github.com/sensepost/gowitness@latest
```

### Escaneo de red y puertos (CTF)

| Tool | Fuente | Que hace |
|------|--------|----------|
| nmap | APT | Escaner de puertos y servicios de referencia. `nmap -sC -sV -p- IP` |
| masscan | APT | Escaneo de puertos ultrarrapido. `sudo masscan -p1-65535 IP --rate 10000` |
| naabu | GO | Escaner de puertos rapido y scriptable. `naabu -host IP -top-ports 1000` |
| rustscan | SCRIPT | Puertos veloz e integra nmap (release de GitHub). |

## Fase 2. Enumeracion

### Fuzzing web y directorios

| Tool | Fuente | Que hace |
|------|--------|----------|
| ffuf | APT o GO | Fuzzer web rapido (dirs, params, vhosts). `ffuf -u URL/FUZZ -w lista.txt` |
| gobuster | APT | Fuzzing de dirs, dns, vhost. `gobuster dir -u URL -w lista -x php,txt` |
| wfuzz | APT | Fuzzer web flexible. `wfuzz -w lista URL/FUZZ` |
| feroxbuster | SCRIPT | Fuzzer recursivo en Rust, muy rapido. |
| dirsearch | PIPX | Fuzzing de rutas con buenas listas. `dirsearch -u URL` |

### Fingerprinting y deteccion

| Tool | Fuente | Que hace |
|------|--------|----------|
| whatweb | APT | Identifica tecnologias web. `whatweb URL` |
| wafw00f | PIPX | Detecta WAF y firewalls. `wafw00f URL` |
| nikto | APT | Escaner web clasico de misconfigs. `nikto -h URL` |
| wpscan | APT | Auditoria especifica de WordPress. `wpscan --url URL` |

### Enumeracion de servicios (SMB y otros)

| Tool | Fuente | Que hace |
|------|--------|----------|
| enum4linux-ng | SCRIPT | Enumeracion SMB y Windows mejorada. `enum4linux-ng IP` (via git+ en pipx) |
| smbclient | APT | Cliente SMB para listar y acceder shares. `smbclient -L //IP` |
| snmpwalk | APT | Enumeracion SNMP (paquete snmp). |

### Parametros ocultos

| Tool | Fuente | Que hace |
|------|--------|----------|
| arjun | PIPX | Descubre parametros HTTP ocultos. `arjun -u URL` |
| gf | GO | Filtra URLs sospechosas por patron (xss, ssrf, sqli). `cat urls \| gf xss` |
| qsreplace | GO | Reemplaza valores de query en masa. `cat urls \| qsreplace payload` |

## Fase 3. Busqueda de vulnerabilidades

| Tool | Fuente | Que hace |
|------|--------|----------|
| nuclei | GO | Escaner por plantillas (vulns y CVEs). `nuclei -u URL -severity high,critical` |
| sqlmap | APT | Detecta y explota SQLi automaticamente. `sqlmap -u "URL?id=1" --batch --dbs` |
| dalfox | GO | Escaner de XSS potente. `dalfox url URL` |
| XSStrike | PIPX | Deteccion avanzada de XSS. `xsstrike -u URL` |
| commix | PIPX | Inyeccion de comandos automatizada. `commix -u URL` |
| interactsh-client | GO | Detecta vulns ciegas OOB (SSRF, RCE). `interactsh-client` |

Modulos Go:

```
nuclei            -> github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
dalfox            -> github.com/hahwul/dalfox/v2@latest
interactsh-client -> github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest
gf                -> github.com/tomnomnom/gf@latest
qsreplace         -> github.com/tomnomnom/qsreplace@latest
```

## Fase 4. Credenciales y hashes

| Tool | Fuente | Que hace |
|------|--------|----------|
| hydra | APT | Fuerza bruta de servicios (ssh, http, ftp). `hydra -l user -P rockyou IP ssh` |
| john | APT | Cracker de hashes versatil. `john --wordlist=rockyou hash.txt` |
| hashcat | APT | Cracker por GPU, muy rapido. `hashcat -m 0 hash.txt rockyou` |
| hashid | APT | Identifica el tipo de hash. `hashid '<hash>'` |
| crackmapexec | PIPX | Pentesting de redes AD y SMB en masa. `crackmapexec smb IP -u user -p pass` |

## Fase 5. Forense, stego y archivos (CTF)

| Tool | Fuente | Que hace |
|------|--------|----------|
| exiftool | APT | Metadatos de archivos. `exiftool file` (paquete libimage-exiftool-perl) |
| binwalk | APT | Analiza y extrae archivos embebidos. `binwalk -e file` |
| foremost | APT | Carving de archivos por firma. `foremost -i img -o out/` |
| steghide | APT | Oculta y extrae datos en imagenes. `steghide extract -sf img.jpg` |
| zsteg | SCRIPT | Stego en PNG y BMP (gema Ruby). `zsteg file.png` |
| stegseek | SCRIPT | Fuerza bruta de steghide, muy rapido. `stegseek file.jpg rockyou` |

## Fase 6. Reversing y pwn (CTF)

| Tool | Fuente | Que hace |
|------|--------|----------|
| rizin | APT | Framework de reversing (fork de radare2). `rizin -A binario` |
| gdb | APT | Debugger (mejora con GEF o pwndbg). `gdb ./binario` |
| ltrace, strace | APT | Trazado de librerias y syscalls. `strace ./binario` |
| pwntools | PIPX | Framework Python para explotacion de binarios. `from pwn import *` |
| checksec | PIPX | Muestra protecciones de un binario (viene con pwntools). |
| ghidra | SCRIPT | Desensamblador y decompilador (GUI, requiere Java). |

## Fase 7. Post-explotacion, privesc y pivoting

| Tool | Fuente | Que hace |
|------|--------|----------|
| linpeas | SCRIPT | Busca vias de privesc en Linux automaticamente. |
| winpeas | SCRIPT | Igual para Windows. |
| pspy | SCRIPT | Espia procesos y cron sin ser root. |
| chisel | SCRIPT | Tuneles y pivoting sobre HTTP. |
| ligolo-ng | SCRIPT | Pivoting moderno via interfaz TUN. |
| proxychains4 | APT | Encadena trafico por proxies o tunel. `proxychains nmap ...` |

Los SCRIPT se descargan de GitHub releases a `~/tools`. Fuente de PEASS: github.com/peass-ng/PEASS-ng.

## Proxies e interceptacion web

| Tool | Fuente | Que hace |
|------|--------|----------|
| Burp Suite | SCRIPT | Proxy de interceptacion web (JAR mas Java). |
| mitmproxy | PIPX | Proxy interactivo por terminal. `mitmproxy` |
| ZAP | APT o SCRIPT | Alternativa libre a Burp (OWASP). |

## Utilidades

| Tool | Fuente | Que hace |
|------|--------|----------|
| tmux | APT | Sesiones persistentes (escaneos largos sobreviven). |
| rlwrap | APT | Mejora reverse shells (historial y edicion). `rlwrap nc -lvnp 4444` |
| netcat | APT | Navaja suiza de red y listeners (paquete netcat-openbsd). |
| socat | APT | Relay de red avanzado, shells estables. |
| jq | APT | Procesa JSON en terminal. `curl API \| jq` |
| anew | GO | Anade lineas nuevas sin duplicar (recon). `cat new \| anew all.txt` |
| openvpn | APT | Cliente VPN para labs (HTB, THM). `sudo openvpn lab.ovpn` |

## Wordlists

| Recurso | Fuente | Nota |
|---------|--------|------|
| SecLists | git | Coleccion estandar en /usr/share/seclists. Si no esta en apt: git clone github.com/danielmiessler/SecLists |
| rockyou | incluida | En /usr/share/wordlists/rockyou.txt (descomprimir el .gz) |
| assetnote | git | Listas grandes para fuzzing serio. |

## Docker y Kali (arsenal pesado bajo demanda)

```bash
# Kali desechable (base minima, instala lo que necesites dentro)
docker run -it --rm -v "$PWD":/work kalilinux/kali-rolling
#   dentro: apt update && apt install -y <tool>
#   arsenal completo CLI: apt install -y kali-linux-headless

# Kali persistente (crea una vez con arsenal; luego docker start -ai kali-arsenal)
docker run -it --name kali-arsenal -v "$HOME/htb":/root/htb kalilinux/kali-rolling
```

## Estado del setup

Actualiza esta tabla conforme avances.

| Fuente | Ya instalado | Pendiente |
|--------|--------------|-----------|
| APT | nmap, masscan, sqlmap, nikto, whatweb, gobuster, ffuf, wfuzz, hydra, john, hashcat, hashid, exiftool, binwalk, foremost, steghide, rizin, gdb, ltrace, strace, netcat, tcpdump, dnsutils, whois, jq, tmux, rlwrap, openvpn, smbclient | proxychains4, wpscan |
| GO | subfinder, httpx, nuclei, naabu, dnsx, katana, gau, anew, gf, dalfox, amass, gowitness, waybackurls | interactsh-client |
| PIPX | arjun, dirsearch, wafw00f, uro, pwntools, enum4linux-ng | crackmapexec |
| SCRIPT | pendiente | linpeas, winpeas, pspy, chisel, Burp |
| DOCKER | Kali (desechable) | listo |