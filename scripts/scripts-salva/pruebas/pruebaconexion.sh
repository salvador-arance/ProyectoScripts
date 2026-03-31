#!/bin/bash

# Nombre del archivo que contiene las IPs (una por línea)
ARCHIVO_IPS="lista_ips.txt"

# Verificar si el archivo existe
if [[ ! -f "$ARCHIVO_IPS" ]]; then
    echo "Error: El archivo $ARCHIVO_IPS no existe."
    exit 1
fi

echo "--- Iniciando comprobación de red ---"

# Leer el archivo línea por línea
while IFS= read -r ip || [[ -n "$ip" ]]; do
    # Ignorar líneas vacías o comentarios (que empiecen con #)
    [[ -z "$ip" || "$ip" =~ ^# ]] && continue

    # Realizar 1 pings con un tiempo de espera de 1 segundo
    if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
        echo "[ OK ] El equipo $ip responde."
    else
        echo "[FAIL] El equipo $ip NO está disponible."
    fi
done < "$ARCHIVO_IPS"

echo "--- Comprobación finalizada ---"

