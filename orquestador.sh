#!/usr/bin/env bash

PROGNAME=$(basename "$0")
TMPDIR=$(mktemp -d)
NMAP_XML="$TMPDIR/nmap.xml"
SEARCHSPLOIT_OUT="$TMPDIR/searchsploit.txt"
SUMMARY_MD="${PWD}/orquestador_summary.md"
NMAP_OPTS=(-p- -sS -sV --min-rate 5000 -n -Pn)

function ctrl_c(){
  echo -e "\n[!] Saliendo...\n"
  exit 1
}
trap ctrl_c INT

function help_panel() {
  echo -e "\n[+] Uso: $PROGNAME -t TARGET [-o OUTDIR]"
  exit 1
}

#Opciones de la línea de comandos
TARGET=""
OUTDIR=""
while getopts ":t:o:h" opt; do
  case $opt in
    t) TARGET="$OPTARG" ;;
    o) OUTDIR="$OPTARG" ;;
    h) help_panel ;;
    *) help_panel ;;
  esac
done

if [[ -z "$TARGET" ]]; then help_panel; fi
OUTDIR="${OUTDIR:-./orquestador_output_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUTDIR"


#Ejecución de nmap
echo -e "\n[+] Lanzando nmap contra ${TARGET}...\n"

nmap "${NMAP_OPTS[@]}" -oX "$NMAP_XML" "$TARGET" > "$OUTDIR/nmap.stdout" 2>&1

#Parseo de resultados
SERVICES_CSV="$TMPDIR/services.csv"
: > "$SERVICES_CSV"

echo -e "\n[+] Parseando XML con xmlstarlet..."
# Para cada host/port abierto saca: port/proto, proto, service, product, version, host
xmlstarlet sel -T -t -m "//host" \
  -v "normalize-space((address[@addrtype='ipv4']/@addr|address/@addr)[1])" -o "|" \
  -m "ports/port[state/@state='open']" -v "concat(@portid,'/',@protocol)" -o "|" \
  -v "normalize-space(@protocol)" -o "|" \
  -v "normalize-space(service/@name)" -o "|" \
  -v "normalize-space(service/@product)" -o "|" \
  -v "normalize-space(service/@version)" -n "$NMAP_XML" \
  | while IFS='|' read -r host port proto service product version; do
      # Normaliza campos vacíos
      product=${product:-}
      version=${version:-}
      service=${service:-}
      echo "${port},${proto},${service},${product},${version},${host}" >> "$SERVICES_CSV"
  done

#Extrae CVes
echo -e "\n[+] Extrayendo CVE(s) detectadas por nmap..."
CVE_LIST="$OUTDIR/cves.txt"
: > "$CVE_LIST"

if [[ -f "$NMAP_XML" ]]; then
  grep -oE 'CVE-[0-9]{4}-[0-9]+' "$NMAP_XML" | sort -u > "$CVE_LIST" || true
fi

#Ejecuta searchexploit
echo -e "\n[+] Ejecutando searchsploit --nmap para sugerir exploits..."

if command -v searchsploit >/dev/null 2>&1; then
  if [[ -s "$NMAP_XML" ]]; then
    if searchsploit --nmap "$NMAP_XML" > "$SEARCHSPLOIT_OUT" 2>/dev/null; then
      cp -f "$SEARCHSPLOIT_OUT" "$OUTDIR/"
      echo "[+] Resultados searchsploit guardados en $OUTDIR/$(basename "$SEARCHSPLOIT_OUT")"
    else
      echo "[!] searchsploit --nmap no devolvió resultados o falló."
    fi
  else
    echo "[!] No hay NMAP XML disponible para pasar a searchsploit."
  fi
else
  echo "[!] searchsploit no instalado. Instálalo con 'apt install exploitdb' o desde repositorio."
fi


#Genera resultado en Markdown
cat > "$SUMMARY_MD" <<EOF
# Orquestador - Resumen
**Target:** $TARGET  
**Fecha:** $(date)

## Servicios detectados
Archivo: \`services.csv\`
\`\`\`
$(if [[ -s "$SERVICES_CSV" ]]; then sed 's/,/ | /g' "$SERVICES_CSV" | sed 's/^/ /'; else echo "  (no services)"; fi)
\`\`\`

## CVEs detectadas por nmap
\`\`\`
$(if [[ -s "$CVE_LIST" ]]; then sed 's/^/ - /' "$CVE_LIST"; else echo "  (no CVEs detected)"; fi)
\`\`\`

## Extracto de searchsploit (si existe)
\`\`\`
$(if [[ -s "$SEARCHSPLOIT_OUT" ]]; then sed -n '1,120p' "$SEARCHSPLOIT_OUT"; else echo "  (no searchsploit output)"; fi)
\`\`\`

## Archivos generados
- $(basename "$NMAP_XML")
- $(basename "$SEARCHSPLOIT_OUT")
- cves.txt

EOF

echo -e "\n[+] Proceso finalizado. Resultados en: $OUTDIR"
