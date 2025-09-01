#!/bin/bash

# install.sh - Instalador universal

detectar() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo -e "\033[1;31m❌ No se detectó la distribución.\033[0m"
        exit 1
    fi
}

instalar() {
    case $DISTRO in
        arch|manjaro)
            sudo pacman -Sy --noconfirm ffmpeg pulseaudio-utils v4l-utils
            ;;
        ubuntu|debian|linuxmint)
            sudo apt update && sudo apt install -y ffmpeg pulseaudio-utils v4l-utils
            ;;
        fedora|rhel|centos*)
            sudo dnf install -y ffmpeg pulseaudio-utils v4l-utils
            ;;
        *)
            echo -e "\033[1;31m❌ $DISTRO no soportado. Usa el script manual.\033[0m"
            exit 1
            ;;
    esac

    echo -e "\033[1;32m📥 Descargando grabador...\033[0m"
    curl -s -o /tmp/grabador.sh https://raw.githubusercontent.com/tuusuario/grabador-terminal-linux/main/scripts/grabador-terminal.sh
    sudo cp /tmp/grabador.sh /usr/local/bin/grabar
    sudo chmod +x /usr/local/bin/grabar

    echo -e "\033[1;32m✅ ¡Instalado! Ejecuta: \033[1;37mgrabar\033[0m"
}

detectar
echo -e "\033[1;36m🐧 Distro detectada: $DISTRO\033[0m"
instalar
