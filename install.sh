#!/bin/bash

# =========================
#  Couleurs
# =========================
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${GREEN}[+] Installation des dépendances...${NC}"

# =========================
#  Détection OS
# =========================
if [ -f /etc/debian_version ]; then
    DISTRO="debian"
elif [ -f /etc/arch-release ]; then
    DISTRO="arch"
elif [ -f /etc/fedora-release ]; then
    DISTRO="fedora"
else
    echo -e "${RED}[-] Distribution non supportée${NC}"
    exit 1
fi

# =========================
#  Installation dépendances
# =========================
install_debian() {
    sudo apt update
    sudo apt install -y netcat-openbsd coreutils rlwrap
}

install_arch() {
    sudo pacman -Sy --noconfirm netcat rlwrap
}

install_fedora() {
    sudo dnf install -y nc rlwrap
}

case "$DISTRO" in
    debian) install_debian ;;
    arch) install_arch ;;
    fedora) install_fedora ;;
esac

# =========================
#  Vérification
# =========================
echo -e "${GREEN}[+] Vérification des outils...${NC}"

MISSING=()

for cmd in nc base64 iconv rlwrap; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING+=("$cmd")
    fi
done

if [ ${#MISSING[@]} -ne 0 ]; then
    echo -e "${YELLOW}[!] Outils manquants: ${MISSING[*]}${NC}"
else
    echo -e "${GREEN}[+] Tous les outils sont installés ✔${NC}"
fi

# =========================
#  Installation binaire
# =========================
echo -e "${GREEN}[+] Installation du script...${NC}"

SCRIPT_NAME="r3vsh3ll.sh"

if [ ! -f "$SCRIPT_NAME" ]; then
    echo -e "${RED}[-] Script $SCRIPT_NAME introuvable dans $(pwd)${NC}"
    exit 1
fi

chmod +x "$SCRIPT_NAME"

# Création du lien symbolique
if [ ! -f "/usr/local/bin/r3vsh3ll" ]; then
    sudo ln -s "$(pwd)/$SCRIPT_NAME" /usr/local/bin/r3vsh3ll
    echo -e "${GREEN}[+] Lien créé : /usr/local/bin/r3vsh3ll${NC}"
else
    echo -e "${YELLOW}[!] Lien déjà existant${NC}"
fi

# =========================
#  Fin
# =========================
echo -e "${GREEN}[+] Installation terminée 🚀${NC}"
echo -e "Utilisation : ${YELLOW}r3vsh3ll --host <IP> --port <PORT>${NC}"