#!/bin/bash

# Nombre del archivo con las IPs
ARCHIVO="lista_ips.txt"

# Verificar si el archivo existe
if [ ! -f "$ARCHIVO" ]; then
    echo "Error: El archivo $ARCHIVO no existe." 
    exit 1
fi

# Definir los servicios y sus puertos estándar
# Apache: 80, SSH: 22, FTP: 21
declare -A SERVICIOS=( ["FTP"]=21 ["SSH"]="22" ["Apache"]="80" )

echo "--------------------------------------------------"
echo " Reporte de Estado de Servicios"
echo "--------------------------------------------------"

# Leer el archivo línea por línea
while IFS= read -r ip || [ -n "$ip" ]; do
    # Limpiar posibles espacios en blanco o saltos de línea
    ip=$(echo $ip | xargs)
    
    # Saltar líneas vacías
    [ -z "$ip" ] && continue

    echo -e "\nVerificando Servidor: $ip" 
    
    for serv in "${!SERVICIOS[@]}"; do
        puerto=${SERVICIOS[$serv]}
        
        # Intentar conexión con un timeout de 2 segundos
        (echo > /dev/tcp/"$ip"/"$puerto") > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "  [✔] $serv (Puerto $puerto): ACTIVO"
        else
            echo -e "  [✘] $serv (Puerto $puerto): INACTIVO o CERRADO"
        fi
    done
done < "$ARCHIVO"

echo -e "\n--------------------------------------------------"
