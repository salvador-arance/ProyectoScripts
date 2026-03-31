#!/bin/bash

# ==========================================
# CONFIGURACIÓN (RELLENA ESTO)
# ==========================================
TOKEN="8554007149:AAFYY9uYyPTASLY3rL6d2fsKnfTZ0FvNmWY"
CHAT_ID="-5178791639"
USERS_AUTORIZADOS="8373805723 1246852305"
MI_NOMBRE=$(hostname)
LOG_FILE="/var/log/auth.log"
ULTIMO_ID_FILE="/tmp/last_update_id.txt"

# ==========================================
# FUNCIONES AUXILIARES
# ==========================================

send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" -d text="$1" > /dev/null
}

# Monitor de intentos de acceso fallidos
monitor_ssh() {
    echo "[+] Monitor de logs iniciado en $MI_NOMBRE"
    tail -Fn0 "$LOG_FILE" | while read LINEA; do
        if echo "$LINEA" | grep -q "Failed password\|Connection closed by authenticating user"; then
            IP_ATAQUE=$(echo "$LINEA" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
            if [ ! -z "$IP_ATAQUE" ]; then
                send_telegram "⚠️ [$MI_NOMBRE] Intento SSH fallido desde: $IP_ATAQUE"
            fi
        fi
    done
}

# ==========================================
# EJECUCIÓN
# ==========================================

# Lanzar monitor en segundo plano
monitor_ssh &

echo "[+] Bot de comandos activo en $MI_NOMBRE. Escuchando..."

while true; do
    LAST_ID=$(cat "$ULTIMO_ID_FILE" 2>/dev/null || echo 0)
    
    # Consultar actualizaciones (getUpdates)
    UPDATES=$(curl -s "https://api.telegram.org/bot$TOKEN/getUpdates?offset=$((LAST_ID + 1))&timeout=20")

    # Extraer el último mensaje que sea un comando /allow
    # Usamos python3 para procesar el JSON de forma segura si está disponible, 
    # si no, una regex de grep más agresiva.
    
    RESULTADO=$(echo "$UPDATES" | grep -oP '\{"update_id":\d+,"message":\{"message_id":\d+,"from":\{"id":\d+.*?,"text":"/allow [^"]+"\}\}')

    if [ ! -z "$RESULTADO" ]; then
        UPDATE_ID=$(echo "$RESULTADO" | grep -oP '(?<="update_id":)\d+' | tail -1)
        SENDER_ID=$(echo "$RESULTADO" | grep -oP '(?<="from":\{"id":)\d+' | tail -1)
        TEXTO=$(echo "$RESULTADO" | grep -oP '(?<="text":")[^"]+' | tail -1)

        if [ "$UPDATE_ID" -gt "$LAST_ID" ]; then
            echo "$UPDATE_ID" > "$ULTIMO_ID_FILE"

            # Verificar si el usuario está en la lista blanca de personas
            if [[ " $USERS_AUTORIZADOS " =~ " $SENDER_ID " ]]; then
                
                # Extraer IP y Destino del comando /allow 1.2.3.4 nombre_maquina
                IP_REQ=$(echo "$TEXTO" | awk '{print $2}')
                TARGET=$(echo "$TEXTO" | awk '{print $3}')

                if [ "$TARGET" == "$MI_NOMBRE" ] || [ "$TARGET" == "all" ]; then
                    sudo ufw allow from "$IP_REQ" to any port 22 proto tcp > /dev/null
                    send_telegram "✅ [$MI_NOMBRE] Acceso concedido a la IP $IP_REQ"
                fi
            fi
        fi
    fi
    sleep 2
done
