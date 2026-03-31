#!/bin/bash
# install_ssh.sh - Instalación inteligente y endurecimiento de SSH

echo "--- Comprobando estado de OpenSSH Server ---"

# Verificar si sshd (el demonio de SSH) ya está instalado
if command -v sshd >/dev/null 2>&1; then
    echo "[!] OpenSSH ya está instalado. Saltando instalación..."
else
    echo "[+] Instalando OpenSSH Server..."
    sudo apt update && sudo apt install -y openssh-server
fi

echo "--- Aplicando configuraciones de seguridad ---"

# Asegurar que el servicio esté habilitado y corriendo
sudo systemctl enable ssh
sudo systemctl start ssh

echo "--- Configurando Firewall (UFW) ---"
# Verificamos si UFW está instalado, si no, lo instalamos
if ! command -v ufw >/dev/null 2>&1; then
    sudo apt install -y ufw
fi

# Configuración restrictiva: Denegar todo por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# IMPORTANTE: Permitir el puerto 22 para que no te quedes fuera 
# (Luego usarás el script allow_ip.sh para filtrar por IP específica)
sudo ufw allow 22/tcp

# Aplicar los cambios
echo "y" | sudo ufw enable

echo "--- Resumen de estado ---"
sudo ufw status verbose

echo "--------------------------------------------------------"
echo "Configuración completada."
echo "Recuerda usar ./allow_ip.sh para autorizar IPs específicas."
echo "--------------------------------------------------------"
