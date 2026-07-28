# Cheatsheet

Comandos de pentest, bug bounty y CTF organizados por fase. Primero identifica en que fase estas y el comando cae solo.

Regla mental: el output de una fase es el input de la siguiente. Nunca mires el vacio preguntandote que hacer, procesa lo que la fase anterior te dio.

Variables usadas: `$IP` (objetivo), `$DOMAIN` (dominio), `$URL`.
Wordlists: se asume SecLists en /usr/share/seclists. Si no esta: `sudo git clone --depth 1 https://github.com/danielmiessler/SecLists /usr/share/seclists`.

## Fase 0. Contexto

```bash
# IP de la VPN (tun0)
ip -4 addr show tun0 | grep -oP 'inet \K[\d.]+'

# Servidor web rapido para transferir archivos al objetivo
python3 -m http.server 80

# Listener para reverse shells
nc -lvnp 4444
```

## Fase 1. Reconocimiento (que hay aqui)

### Red y maquina (CTF)

```bash
# Descubrimiento rapido de TODOS los puertos
nmap -p- --min-rate 10000 -T4 $IP -oN nmap/allports.txt

# Escaneo detallado solo de los puertos abiertos encontrados
nmap -sC -sV -p22,80,443 $IP -oA nmap/detailed

# Alternativa ultrarrapida de puertos
sudo masscan -p1-65535 $IP --rate 10000
```

### Dominio y superficie web (bug bounty)

```bash
# Subdominios
subfinder -d $DOMAIN -all -silent

# Cuales estan vivos (mas titulo, tecnologia, codigo de estado)
subfinder -d $DOMAIN -all -silent | httpx -silent -title -tech-detect -status-code

# Puertos de un host (top 1000)
naabu -host $DOMAIN -top-ports 1000 -silent

# URLs historicas conocidas
gau $DOMAIN | anew urls.txt

# Crawling activo del sitio
katana -u $URL -d 3 -silent
```

### Pipeline de recon (el clasico de bug bounty)

```bash
subfinder -d $DOMAIN -all -silent \
  | httpx -silent \
  | nuclei -severity low,medium,high,critical
```

## Fase 2. Enumeracion (que es cada cosa)

### Mapa rapido: servicio a que hacer

| Puerto o hallazgo | Que enumerar | Herramienta |
|-------------------|--------------|-------------|
| 21 FTP | login anonimo, version | nmap --script ftp-* |
| 22 SSH | version (rara vez es la via) | anotar y seguir |
| 80/443 HTTP | directorios, tech, vulns | ffuf, whatweb, nuclei |
| 139/445 SMB | shares, usuarios | smbclient -L, enum4linux-ng |
| 3306 MySQL o 5432 PG | credenciales por defecto | cliente mas wordlist |
| Parametro ?id= | inyecciones (SQLi y otras) | sqlmap, manual |
| Formulario login | fuerza bruta, SQLi | hydra, sqlmap |

### Web

```bash
# Fingerprinting de tecnologias
whatweb $URL

# Hay un WAF delante
wafw00f $URL

# Fuzzing de directorios y archivos
ffuf -u $URL/FUZZ -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-medium.txt \
     -mc 200,204,301,302,307,401,403 -o ffuf.json

# Fuzzing con extensiones
gobuster dir -u $URL -w /usr/share/seclists/Discovery/Web-Content/common.txt -x php,html,txt,bak

# Subdominios por fuzzing de la cabecera Host (vhosts)
ffuf -u $URL -H "Host: FUZZ.$DOMAIN" \
     -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -fs 0

# Escaner web clasico
nikto -h $URL

# Descubrir parametros ocultos de una API o endpoint
arjun -u $URL
```

## Fase 3. Busqueda de vulnerabilidades (que es explotable)

```bash
# Escaneo de vulnerabilidades conocidas por plantillas
nuclei -u $URL -severity low,medium,high,critical

# Solo una categoria (ej: exposiciones, CVEs)
nuclei -u $URL -tags cve,exposure

# Inyeccion SQL sobre un parametro
sqlmap -u "$URL/page?id=1" --batch --dbs
sqlmap -u "$URL/page?id=1" --batch -D basedatos -T usuarios --dump

# XSS
dalfox url $URL
```

## Fase 4. Credenciales y hashes

```bash
# Identificar el tipo de hash antes de crackear
hashid '<hash>'

# Fuerza bruta de un servicio
hydra -l admin -P /usr/share/wordlists/rockyou.txt $IP ssh
hydra -L users.txt -P rockyou.txt $IP http-post-form \
      "/login:user=^USER^&pass=^PASS^:Invalid"

# Crackear hashes con John
john --wordlist=/usr/share/wordlists/rockyou.txt hashes.txt
john --show hashes.txt

# Crackear con Hashcat (-m es el tipo: 0=MD5, 1000=NTLM, 1800=sha512crypt)
hashcat -m 0 hashes.txt /usr/share/wordlists/rockyou.txt
```

## Fase 5. Forense, esteganografia y archivos (CTF)

```bash
# Metadatos de una imagen o archivo
exiftool archivo.jpg

# Buscar y extraer archivos embebidos
binwalk -e archivo.bin

# Datos ocultos en una imagen con contrasena
steghide extract -sf imagen.jpg

# Fuerza bruta de steghide
stegseek imagen.jpg /usr/share/wordlists/rockyou.txt

# Recuperar archivos por firmas (carving)
foremost -i disco.img -o salida/

# Ver strings legibles de un binario
strings -n 8 binario
```

## Fase 6. Reversing y binarios

```bash
rizin -A binario          # analisis (aa dentro para analizar)
gdb ./binario             # debugger
ltrace ./binario          # llamadas a librerias
strace ./binario          # llamadas al sistema
file binario              # que tipo de binario es
checksec --file=binario   # protecciones (viene con pwntools)
```

## Fase 7. Post-explotacion y pivoting

```bash
# Buscar vias de escalada de privilegios (subir el script al objetivo)
./linpeas.sh

# Espiar procesos y cron sin ser root
./pspy64

# Tunel o pivoting con chisel (servidor en tu maquina)
./chisel server -p 8000 --reverse
```

## Utilidades de terminal

```bash
# Extraer todas las IPs de un archivo
grep -oP '\d+\.\d+\.\d+\.\d+' archivo | sort -u

# Parsear JSON de una respuesta
curl -s $URL/api | jq '.'

# Info DNS y whois
dig $DOMAIN any
whois $DOMAIN

# Anadir lineas nuevas sin duplicados (recon)
cat nuevos.txt | anew todos.txt

# Sesion persistente para escaneos largos
tmux new -s recon
```