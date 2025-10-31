#Orquestador de nmap

Script en **Bash** que automatiza el flujo básico de reconocimiento y análisis de vulnerabilidades mediante **Nmap**, extracción de **CVEs**, y sugerencia de **exploits** usando `searchsploit`.

---

## Funcionalidades principales

- Escaneo de puertos completos (`-p-`) con **detección de servicios y versiones** (`-sV`).
- Exportación de resultados en **XML** y parseo automático con `xmlstarlet`.
- Extracción automática de **CVE(s)** detectadas en el XML.
- Integración con **Exploit-DB** (`searchsploit --nmap`) para sugerir posibles exploits.
- Generación de informe final en **Markdown** (`orquestador_summary.md`).

---

## Dependencias

| Herramienta | Función | Instalación |
|--------------|----------|--------------|
| `nmap` | Escaneo de red y detección de servicios | `sudo apt install nmap` |
| `xmlstarlet` | Parseo XML de resultados Nmap | `sudo apt install xmlstarlet` |
| `searchsploit` | Búsqueda de exploits en Exploit-DB | `sudo apt install exploitdb` |


---

## Instalación

```bash
git clone https://github.com/tuusuario/orquestador.git
cd orquestador
chmod +x orquestador.sh
```

## Uso básico
```
./orquestador.sh -t <TARGET> [-o <OUTDIR>]
```

## Archivos generados

| Archivo                  | Descripción                                   |
| ------------------------ | --------------------------------------------- |
| `nmap.xml`               | Resultado del escaneo en formato XML.         |
| `cves.txt`               | CVEs detectadas por los scripts de Nmap.      |
| `searchsploit.txt`       | Resultados de búsqueda de exploits asociados. |
| `orquestador_summary.md` | Informe final en Markdown.                    |

