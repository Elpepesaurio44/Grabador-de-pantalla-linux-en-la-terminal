#!/bin/bash

# install-arch.sh - Instalador para Arch Linux

echo -e "\033[1;36m📦 Instalando dependencias en Arch Linux...\033[0m"
sudo pacman -Sy --noconfirm ffmpeg pulseaudio v4l-utils

echo -e "\033[1;32m📥 Descargando el grabador de pantalla...\033[0m"
curl -s -o /tmp/grabador-terminal.sh https://raw.githubusercontent.com/usuario/grabador/main/grabador-terminal.sh

echo -e "\033[1;34m🔧 Instalando como comando global: 'grabar'\033[0m"
sudo cp /tmp/grabador-terminal.sh /usr/local/bin/grabar
sudo chmod +x /usr/local/bin/grabar

echo -e "\033[1;32m🎉 ¡Listo! Usa el comando: \033[1;37mgrabar\033[0m"
